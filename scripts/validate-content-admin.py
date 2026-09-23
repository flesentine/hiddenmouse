#!/usr/bin/env python3
import argparse
import copy
import json
import re
import sys
import tempfile
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ADMIN_DIR = ROOT / "ContentAdmin"
LANDS_PATH = ADMIN_DIR / "lands.json"
AREAS_PATH = ADMIN_DIR / "areas.json"
DISCOVERIES_DIR = ADMIN_DIR / "discoveries"
REGISTRY_PATH = ADMIN_DIR / "discovery-id-registry.json"
IMAGE_DIR = ROOT / "ParkHunt" / "Resources" / "Images"

ID_PATTERN = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
DISCOVERY_FILENAME_PATTERN = re.compile(
    r"^(?P<order>\d{3})-[a-z0-9]+(?:-[a-z0-9]+)*\.json$"
)
ALLOWED_AREA_KINDS = {"attraction", "area"}
ALLOWED_CATEGORIES = {
    "hiddenMickey",
    "hiddenCharacter",
    "imagineeringDetail",
    "movieReference",
    "historicalDetail",
    "easterEgg",
    "secretFeature",
}
ALLOWED_DIFFICULTIES = {"easy", "medium", "hard", "expert"}
ALLOWED_VERIFICATION_STATUSES = {
    "verified",
    "needsRecheck",
    "unverified",
    "temporarilyUnavailable",
    "removed",
}
ALLOWED_HINT_KINDS = {"clue", "detailed"}
ALLOWED_IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".heic", ".png"}
ALLOWED_REGISTRY_STATES = {"development", "active", "retired"}
PLACEHOLDER_PATTERNS = [
    re.compile(pattern, re.IGNORECASE)
    for pattern in [
        r"\bTODO\b",
        r"\bFIXME\b",
        r"\bTBD\b",
        r"\bplaceholder\b",
        r"\bprototype\b",
        r"\bdevelopment[- ]only\b",
        r"\breplace[- ]with\b",
        r"\breplace this\b",
        r"\blorem ipsum\b",
    ]
]

LAND_REQUIRED = {"id", "parkID", "name", "sortOrder"}
LAND_ALLOWED = LAND_REQUIRED
AREA_REQUIRED = {"id", "landID", "name", "kind", "sortOrder"}
AREA_ALLOWED = AREA_REQUIRED
DISCOVERY_REQUIRED = {
    "id",
    "title",
    "parkID",
    "landID",
    "category",
    "difficulty",
    "hints",
    "revealDescription",
    "verificationStatus",
    "isIndoor",
    "tags",
}
DISCOVERY_OPTIONAL = {
    "areaID",
    "location",
    "thumbnailImageName",
    "revealImageName",
    "lastVerifiedAt",
    "_editorial",
}
DISCOVERY_ALLOWED = DISCOVERY_REQUIRED | DISCOVERY_OPTIONAL
HINT_REQUIRED = {"id", "order", "text"}
HINT_OPTIONAL = {"kind"}
HINT_ALLOWED = HINT_REQUIRED | HINT_OPTIONAL
LOCATION_REQUIRED = {"latitude", "longitude", "radiusMeters"}
EDITORIAL_ALLOWED = {"developmentOnly", "notes"}


class ValidationResult:
    def __init__(self):
        self.errors = []
        self.warnings = []

    def error(self, message):
        self.errors.append(message)

    def warn(self, message):
        self.warnings.append(message)

    def extend(self, other):
        self.errors.extend(other.errors)
        self.warnings.extend(other.warnings)


def load_json(path):
    try:
        with path.open("r", encoding="utf-8") as handle:
            return json.load(handle)
    except FileNotFoundError:
        raise SystemExit(f"Missing content file: {path.relative_to(ROOT)}")
    except json.JSONDecodeError as error:
        raise SystemExit(
            f"Invalid JSON in {path.relative_to(ROOT)}: "
            f"line {error.lineno}, column {error.colno}: {error.msg}"
        )


def load_admin_source():
    lands = load_json(LANDS_PATH)
    areas = load_json(AREAS_PATH)
    registry = load_json(REGISTRY_PATH)

    if not DISCOVERIES_DIR.is_dir():
        raise SystemExit(
            f"Missing discoveries directory: {DISCOVERIES_DIR.relative_to(ROOT)}"
        )

    discoveries = []
    for path in sorted(DISCOVERIES_DIR.glob("*.json")):
        discoveries.append((path.name, load_json(path)))

    return lands, areas, discoveries, registry


def is_number(value):
    return isinstance(value, (int, float)) and not isinstance(value, bool)


def nonempty_string(value):
    return isinstance(value, str) and bool(value.strip())


def validate_id(value, label, result):
    if not nonempty_string(value):
        result.error(f"{label}: ID must be a non-empty string.")
        return

    if not ID_PATTERN.fullmatch(value):
        result.error(
            f"{label}: ID '{value}' must use lowercase kebab-case."
        )


def validate_keys(value, required, allowed, label, result):
    if not isinstance(value, dict):
        result.error(f"{label}: must be a JSON object.")
        return False

    missing = sorted(required - set(value))
    unknown = sorted(set(value) - allowed)

    for field in missing:
        result.error(f"{label}: missing required field '{field}'.")

    for field in unknown:
        result.error(f"{label}: unknown field '{field}'.")

    return not missing


def validate_positive_sort_order(value, label, result):
    if not isinstance(value, int) or isinstance(value, bool) or value <= 0:
        result.error(f"{label}: sortOrder must be a positive integer.")


def validate_lands(lands, result):
    if not isinstance(lands, list) or not lands:
        result.error("ContentAdmin/lands.json must contain a non-empty array.")
        return {}

    by_id = {}
    sort_orders = {}

    for index, land in enumerate(lands):
        label = f"lands[{index}]"
        validate_keys(land, LAND_REQUIRED, LAND_ALLOWED, label, result)
        if not isinstance(land, dict):
            continue

        land_id = land.get("id")
        validate_id(land_id, label, result)

        if nonempty_string(land_id):
            if land_id in by_id:
                result.error(f"{label}: duplicate land ID '{land_id}'.")
            else:
                by_id[land_id] = land

        if not nonempty_string(land.get("parkID")):
            result.error(f"{label}: parkID must be a non-empty string.")
        else:
            validate_id(land.get("parkID"), f"{label}.parkID", result)

        if not nonempty_string(land.get("name")):
            result.error(f"{label}: name must be a non-empty string.")

        sort_order = land.get("sortOrder")
        validate_positive_sort_order(sort_order, label, result)
        if isinstance(sort_order, int) and not isinstance(sort_order, bool):
            if sort_order in sort_orders:
                result.error(
                    f"{label}: duplicate land sortOrder {sort_order} "
                    f"(also used by {sort_orders[sort_order]})."
                )
            else:
                sort_orders[sort_order] = land_id or label

    return by_id


def validate_areas(areas, land_by_id, result):
    if not isinstance(areas, list):
        result.error("ContentAdmin/areas.json must contain a JSON array.")
        return {}

    by_id = {}
    order_by_land = {}

    for index, area in enumerate(areas):
        label = f"areas[{index}]"
        validate_keys(area, AREA_REQUIRED, AREA_ALLOWED, label, result)
        if not isinstance(area, dict):
            continue

        area_id = area.get("id")
        validate_id(area_id, label, result)
        if nonempty_string(area_id):
            if area_id in by_id:
                result.error(f"{label}: duplicate area ID '{area_id}'.")
            else:
                by_id[area_id] = area

        land_id = area.get("landID")
        if not nonempty_string(land_id):
            result.error(f"{label}: landID must be a non-empty string.")
        elif land_id not in land_by_id:
            result.error(
                f"{label}: unknown landID '{land_id}'."
            )

        if not nonempty_string(area.get("name")):
            result.error(f"{label}: name must be a non-empty string.")

        if area.get("kind") not in ALLOWED_AREA_KINDS:
            result.error(
                f"{label}: kind must be one of "
                f"{sorted(ALLOWED_AREA_KINDS)}."
            )

        sort_order = area.get("sortOrder")
        validate_positive_sort_order(sort_order, label, result)
        if (
            nonempty_string(land_id)
            and isinstance(sort_order, int)
            and not isinstance(sort_order, bool)
        ):
            key = (land_id, sort_order)
            if key in order_by_land:
                result.error(
                    f"{label}: duplicate sortOrder {sort_order} "
                    f"inside land '{land_id}'."
                )
            else:
                order_by_land[key] = area_id or label

    return by_id


def validate_registry(registry, result):
    if not isinstance(registry, dict):
        result.error(
            "ContentAdmin/discovery-id-registry.json must contain a JSON object."
        )
        return {}

    for discovery_id, metadata in registry.items():
        validate_id(
            discovery_id,
            f"registry['{discovery_id}']",
            result,
        )

        if not isinstance(metadata, dict):
            result.error(
                f"registry['{discovery_id}']: value must be an object."
            )
            continue

        unknown = sorted(set(metadata) - {"state", "notes"})
        for field in unknown:
            result.error(
                f"registry['{discovery_id}']: unknown field '{field}'."
            )

        if metadata.get("state") not in ALLOWED_REGISTRY_STATES:
            result.error(
                f"registry['{discovery_id}']: state must be one of "
                f"{sorted(ALLOWED_REGISTRY_STATES)}."
            )

        if "notes" in metadata and not nonempty_string(metadata["notes"]):
            result.error(
                f"registry['{discovery_id}']: notes must be a non-empty string."
            )

    return registry


def validate_location(location, label, result):
    if not isinstance(location, dict):
        result.error(f"{label}: location must be an object.")
        return

    validate_keys(
        location,
        LOCATION_REQUIRED,
        LOCATION_REQUIRED,
        f"{label}.location",
        result,
    )

    latitude = location.get("latitude")
    longitude = location.get("longitude")
    radius = location.get("radiusMeters")

    if not is_number(latitude) or not -90 <= latitude <= 90:
        result.error(
            f"{label}: latitude must be a number from -90 through 90."
        )

    if not is_number(longitude) or not -180 <= longitude <= 180:
        result.error(
            f"{label}: longitude must be a number from -180 through 180."
        )

    if not is_number(radius) or not 0 < radius <= 5000:
        result.error(
            f"{label}: radiusMeters must be greater than 0 and at most 5000."
        )


def validate_iso8601(value, label, result):
    if not nonempty_string(value):
        result.error(f"{label}: must be a non-empty ISO 8601 string.")
        return

    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        result.error(f"{label}: '{value}' is not valid ISO 8601.")
        return

    if parsed.tzinfo is None:
        result.error(f"{label}: ISO 8601 timestamp must include a timezone.")


def validate_image_reference(name, label, image_dir, result):
    if not nonempty_string(name):
        result.error(f"{label}: image filename must be a non-empty string.")
        return

    if Path(name).name != name:
        result.error(f"{label}: image reference must be a filename only.")
        return

    if Path(name).suffix.lower() not in ALLOWED_IMAGE_EXTENSIONS:
        result.error(
            f"{label}: unsupported image type '{Path(name).suffix}'."
        )
        return

    if not (image_dir / name).is_file():
        result.error(
            f"{label}: packaged image does not exist: "
            f"ParkHunt/Resources/Images/{name}"
        )


def validate_editorial_metadata(editorial, label, result):
    if editorial is None:
        return False

    if not isinstance(editorial, dict):
        result.error(f"{label}._editorial must be an object.")
        return False

    unknown = sorted(set(editorial) - EDITORIAL_ALLOWED)
    for field in unknown:
        result.error(
            f"{label}._editorial: unknown field '{field}'."
        )

    development_only = editorial.get("developmentOnly", False)
    if not isinstance(development_only, bool):
        result.error(
            f"{label}._editorial.developmentOnly must be true or false."
        )
        development_only = False

    if "notes" in editorial and not nonempty_string(editorial["notes"]):
        result.error(
            f"{label}._editorial.notes must be a non-empty string."
        )

    if development_only and not nonempty_string(editorial.get("notes")):
        result.error(
            f"{label}: development-only content must explain why in "
            "_editorial.notes."
        )

    return development_only


def placeholder_hits(discovery):
    values = []

    for field in ("id", "title", "revealDescription"):
        if isinstance(discovery.get(field), str):
            values.append((field, discovery[field]))

    tags = discovery.get("tags")
    if isinstance(tags, list):
        for index, tag in enumerate(tags):
            if isinstance(tag, str):
                values.append((f"tags[{index}]", tag))

    hints = discovery.get("hints")
    if isinstance(hints, list):
        for index, hint in enumerate(hints):
            if isinstance(hint, dict) and isinstance(hint.get("text"), str):
                values.append((f"hints[{index}].text", hint["text"]))

    hits = []
    for field, text in values:
        for pattern in PLACEHOLDER_PATTERNS:
            if pattern.search(text):
                hits.append((field, pattern.pattern))
                break

    return hits


def validate_hints(discovery, label, global_hint_ids, result):
    hints = discovery.get("hints")
    if not isinstance(hints, list):
        result.error(f"{label}: hints must be a JSON array.")
        return

    if not hints:
        result.error(f"{label}: at least one hint is required.")
        return

    local_ids = set()
    orders = []
    clue_count = 0
    detailed_count = 0

    for index, hint in enumerate(hints):
        hint_label = f"{label}.hints[{index}]"
        validate_keys(
            hint,
            HINT_REQUIRED,
            HINT_ALLOWED,
            hint_label,
            result,
        )
        if not isinstance(hint, dict):
            continue

        hint_id = hint.get("id")
        validate_id(hint_id, hint_label, result)
        if nonempty_string(hint_id):
            if hint_id in local_ids:
                result.error(
                    f"{hint_label}: duplicate hint ID '{hint_id}' "
                    "inside this discovery."
                )
            local_ids.add(hint_id)

            if hint_id in global_hint_ids:
                result.error(
                    f"{hint_label}: hint ID '{hint_id}' is already used "
                    "by another discovery."
                )
            global_hint_ids.add(hint_id)

            discovery_id = discovery.get("id")
            if nonempty_string(discovery_id) and not hint_id.startswith(
                f"{discovery_id}-"
            ):
                result.error(
                    f"{hint_label}: hint ID must begin with "
                    f"'{discovery_id}-'."
                )

        order = hint.get("order")
        if not isinstance(order, int) or isinstance(order, bool) or order <= 0:
            result.error(
                f"{hint_label}: order must be a positive integer."
            )
        else:
            orders.append(order)

        if not nonempty_string(hint.get("text")):
            result.error(
                f"{hint_label}: text must be a non-empty string."
            )

        kind = hint.get("kind", "clue")
        if kind not in ALLOWED_HINT_KINDS:
            result.error(
                f"{hint_label}: kind must be one of "
                f"{sorted(ALLOWED_HINT_KINDS)}."
            )
        elif kind == "clue":
            clue_count += 1
        elif kind == "detailed":
            detailed_count += 1

    if len(orders) != len(set(orders)):
        result.error(f"{label}: hint orders must be unique.")

    if orders and sorted(orders) != list(range(1, len(orders) + 1)):
        result.error(
            f"{label}: hint orders must be contiguous starting at 1."
        )

    if clue_count < 2:
        result.error(
            f"{label}: prototype hunt flow requires at least two normal clues."
        )

    if detailed_count != 1:
        result.error(
            f"{label}: exactly one detailed hint is required."
        )

    if hints and isinstance(hints[-1], dict):
        if hints[-1].get("kind", "clue") != "detailed":
            result.error(
                f"{label}: the final hint must be the detailed hint."
            )


def validate_discoveries(
    discoveries,
    land_by_id,
    area_by_id,
    registry,
    image_dir,
    shipping,
    result,
):
    if not discoveries:
        result.error(
            "ContentAdmin/discoveries must contain at least one JSON file."
        )
        return

    discovery_ids = {}
    editorial_orders = {}
    global_hint_ids = set()

    for filename, discovery in discoveries:
        label = f"discoveries/{filename}"

        match = DISCOVERY_FILENAME_PATTERN.fullmatch(filename)
        if not match:
            result.error(
                f"{label}: filename must look like "
                "'010-descriptive-slug.json'."
            )
        else:
            editorial_order = match.group("order")
            if editorial_order in editorial_orders:
                result.error(
                    f"{label}: editorial prefix {editorial_order} is also "
                    f"used by {editorial_orders[editorial_order]}."
                )
            editorial_orders[editorial_order] = filename

        validate_keys(
            discovery,
            DISCOVERY_REQUIRED,
            DISCOVERY_ALLOWED,
            label,
            result,
        )
        if not isinstance(discovery, dict):
            continue

        discovery_id = discovery.get("id")
        validate_id(discovery_id, label, result)
        if nonempty_string(discovery_id):
            if discovery_id in discovery_ids:
                result.error(
                    f"{label}: duplicate discovery ID '{discovery_id}' "
                    f"(also in {discovery_ids[discovery_id]})."
                )
            else:
                discovery_ids[discovery_id] = filename

        development_only = validate_editorial_metadata(
            discovery.get("_editorial"),
            label,
            result,
        )

        registry_entry = (
            registry.get(discovery_id)
            if isinstance(registry, dict) and nonempty_string(discovery_id)
            else None
        )
        if registry_entry is None and nonempty_string(discovery_id):
            result.error(
                f"{label}: discovery ID '{discovery_id}' is missing from "
                "discovery-id-registry.json."
            )
        elif isinstance(registry_entry, dict):
            registry_state = registry_entry.get("state")
            if development_only and registry_state != "development":
                result.error(
                    f"{label}: development-only discovery must have "
                    "registry state 'development'."
                )
            if not development_only and registry_state == "development":
                result.error(
                    f"{label}: non-development discovery cannot keep "
                    "registry state 'development'."
                )

            if discovery.get("verificationStatus") == "removed":
                if registry_state != "retired":
                    result.error(
                        f"{label}: removed discovery must have registry "
                        "state 'retired'."
                    )
            elif registry_state == "retired":
                result.error(
                    f"{label}: retired discovery ID cannot be reused by "
                    "an active discovery record."
                )

        if shipping and development_only:
            result.error(
                f"{label}: development-only content is forbidden in "
                "--shipping mode."
            )

        if not nonempty_string(discovery.get("title")):
            result.error(f"{label}: title must be a non-empty string.")

        park_id = discovery.get("parkID")
        land_id = discovery.get("landID")
        area_id = discovery.get("areaID")

        if not nonempty_string(park_id):
            result.error(f"{label}: parkID must be a non-empty string.")
        else:
            validate_id(park_id, f"{label}.parkID", result)

        if not nonempty_string(land_id):
            result.error(f"{label}: landID must be a non-empty string.")
        elif land_id not in land_by_id:
            result.error(f"{label}: unknown landID '{land_id}'.")
        else:
            expected_park = land_by_id[land_id].get("parkID")
            if park_id != expected_park:
                result.error(
                    f"{label}: parkID '{park_id}' does not match land "
                    f"'{land_id}' parkID '{expected_park}'."
                )

        if area_id is not None:
            if not nonempty_string(area_id):
                result.error(
                    f"{label}: areaID must be null/omitted or a non-empty string."
                )
            elif area_id not in area_by_id:
                result.error(f"{label}: unknown areaID '{area_id}'.")
            elif area_by_id[area_id].get("landID") != land_id:
                result.error(
                    f"{label}: area '{area_id}' belongs to land "
                    f"'{area_by_id[area_id].get('landID')}', not '{land_id}'."
                )

        if discovery.get("category") not in ALLOWED_CATEGORIES:
            result.error(
                f"{label}: category must be one of "
                f"{sorted(ALLOWED_CATEGORIES)}."
            )

        if discovery.get("difficulty") not in ALLOWED_DIFFICULTIES:
            result.error(
                f"{label}: difficulty must be one of "
                f"{sorted(ALLOWED_DIFFICULTIES)}."
            )

        if discovery.get("verificationStatus") not in ALLOWED_VERIFICATION_STATUSES:
            result.error(
                f"{label}: verificationStatus must be one of "
                f"{sorted(ALLOWED_VERIFICATION_STATUSES)}."
            )

        if shipping and discovery.get("verificationStatus") in {
            "unverified",
            "needsRecheck",
        }:
            result.error(
                f"{label}: shipping content cannot have verificationStatus "
                f"'{discovery.get('verificationStatus')}'."
            )

        if discovery.get("verificationStatus") == "verified":
            if "lastVerifiedAt" not in discovery:
                result.error(
                    f"{label}: verified discovery requires lastVerifiedAt."
                )

        if "lastVerifiedAt" in discovery:
            validate_iso8601(
                discovery.get("lastVerifiedAt"),
                f"{label}.lastVerifiedAt",
                result,
            )

        if not isinstance(discovery.get("isIndoor"), bool):
            result.error(f"{label}: isIndoor must be true or false.")

        tags = discovery.get("tags")
        if not isinstance(tags, list):
            result.error(f"{label}: tags must be a JSON array.")
        else:
            seen_tags = set()
            for index, tag in enumerate(tags):
                if not nonempty_string(tag):
                    result.error(
                        f"{label}.tags[{index}]: tag must be a non-empty string."
                    )
                    continue
                if not ID_PATTERN.fullmatch(tag):
                    result.error(
                        f"{label}.tags[{index}]: tag '{tag}' must use "
                        "lowercase kebab-case."
                    )
                if tag in seen_tags:
                    result.error(
                        f"{label}: duplicate tag '{tag}'."
                    )
                seen_tags.add(tag)

        if not nonempty_string(discovery.get("revealDescription")):
            result.error(
                f"{label}: revealDescription must be a non-empty string."
            )

        if "location" in discovery:
            validate_location(
                discovery.get("location"),
                label,
                result,
            )

        validate_hints(
            discovery,
            label,
            global_hint_ids,
            result,
        )

        for field in ("thumbnailImageName", "revealImageName"):
            if field in discovery:
                validate_image_reference(
                    discovery.get(field),
                    f"{label}.{field}",
                    image_dir,
                    result,
                )

        hits = placeholder_hits(discovery)
        for field, _ in hits:
            message = (
                f"{label}.{field}: placeholder/development text detected."
            )
            if shipping or not development_only:
                result.error(message)
            else:
                result.warn(
                    message
                    + " Allowed only because _editorial.developmentOnly is true."
                )

    current_ids = set(discovery_ids)

    for registry_id, metadata in registry.items():
        if not isinstance(metadata, dict):
            continue

        state = metadata.get("state")
        if state in {"active", "development"} and registry_id not in current_ids:
            result.error(
                f"registry['{registry_id}']: state '{state}' requires a "
                "current discovery file. Mark intentionally retired IDs "
                "as 'retired' instead."
            )

        if shipping and state == "development" and registry_id in current_ids:
            result.error(
                f"registry['{registry_id}']: development ID is forbidden "
                "in --shipping mode."
            )


def validate_content(
    lands,
    areas,
    discoveries,
    registry,
    image_dir,
    shipping=False,
):
    result = ValidationResult()
    land_by_id = validate_lands(lands, result)
    area_by_id = validate_areas(areas, land_by_id, result)
    registry = validate_registry(registry, result)
    validate_discoveries(
        discoveries,
        land_by_id,
        area_by_id,
        registry,
        image_dir,
        shipping,
        result,
    )
    return result


def run_self_test():
    with tempfile.TemporaryDirectory() as directory:
        image_dir = Path(directory)
        (image_dir / "secret-thumb.jpg").write_bytes(b"fake")
        (image_dir / "secret-reveal.jpg").write_bytes(b"fake")

        lands = [
            {
                "id": "land",
                "parkID": "park",
                "name": "Land",
                "sortOrder": 1,
            }
        ]
        areas = [
            {
                "id": "area",
                "landID": "land",
                "name": "Area",
                "kind": "attraction",
                "sortOrder": 1,
            }
        ]
        discovery = {
            "id": "secret",
            "title": "Real Secret",
            "parkID": "park",
            "landID": "land",
            "areaID": "area",
            "category": "secretFeature",
            "difficulty": "medium",
            "location": {
                "latitude": 33.8,
                "longitude": -117.9,
                "radiusMeters": 75,
            },
            "hints": [
                {
                    "id": "secret-h1",
                    "order": 1,
                    "text": "Look near the arch.",
                    "kind": "clue",
                },
                {
                    "id": "secret-h2",
                    "order": 2,
                    "text": "Look above eye level.",
                    "kind": "clue",
                },
                {
                    "id": "secret-h3",
                    "order": 3,
                    "text": "Check the upper-left detail.",
                    "kind": "detailed",
                },
            ],
            "revealDescription": "The detail is above the left side.",
            "thumbnailImageName": "secret-thumb.jpg",
            "revealImageName": "secret-reveal.jpg",
            "verificationStatus": "verified",
            "lastVerifiedAt": "2026-09-23T00:00:00Z",
            "isIndoor": False,
            "tags": ["detail"],
        }
        registry = {"secret": {"state": "active"}}
        baseline = [("010-secret.json", discovery)]

        valid = validate_content(
            lands,
            areas,
            baseline,
            registry,
            image_dir,
        )
        assert not valid.errors, valid.errors

        cases = []

        bad_location = copy.deepcopy(discovery)
        bad_location["location"]["latitude"] = 200
        cases.append(
            (
                "bad coordinate",
                [("010-secret.json", bad_location)],
                registry,
                "latitude must be",
                False,
            )
        )

        bad_hints = copy.deepcopy(discovery)
        bad_hints["hints"] = bad_hints["hints"][:1]
        cases.append(
            (
                "missing hunt stages",
                [("010-secret.json", bad_hints)],
                registry,
                "at least two normal clues",
                False,
            )
        )

        bad_area = copy.deepcopy(discovery)
        bad_area["areaID"] = "missing-area"
        cases.append(
            (
                "bad area assignment",
                [("010-secret.json", bad_area)],
                registry,
                "unknown areaID",
                False,
            )
        )

        broken_image = copy.deepcopy(discovery)
        broken_image["revealImageName"] = "missing.jpg"
        cases.append(
            (
                "broken image",
                [("010-secret.json", broken_image)],
                registry,
                "packaged image does not exist",
                False,
            )
        )

        placeholder = copy.deepcopy(discovery)
        placeholder["title"] = "TODO placeholder"
        cases.append(
            (
                "placeholder",
                [("010-secret.json", placeholder)],
                registry,
                "placeholder/development text detected",
                False,
            )
        )

        retired_registry = {"secret": {"state": "retired"}}
        cases.append(
            (
                "retired ID reuse",
                baseline,
                retired_registry,
                "retired discovery ID cannot be reused",
                False,
            )
        )

        duplicate = copy.deepcopy(discovery)
        cases.append(
            (
                "duplicate discovery ID",
                [
                    ("010-secret.json", discovery),
                    ("020-secret-copy.json", duplicate),
                ],
                registry,
                "duplicate discovery ID",
                False,
            )
        )

        development = copy.deepcopy(discovery)
        development["id"] = "dev-secret"
        development["title"] = "Prototype Discovery"
        development["_editorial"] = {
            "developmentOnly": True,
            "notes": "Intentional development fixture.",
        }
        for index, hint in enumerate(development["hints"], start=1):
            hint["id"] = f"dev-secret-h{index}"
        development_registry = {
            "dev-secret": {"state": "development"}
        }
        dev_result = validate_content(
            lands,
            areas,
            [("010-dev-secret.json", development)],
            development_registry,
            image_dir,
        )
        assert not dev_result.errors, dev_result.errors
        assert dev_result.warnings, "development placeholder should warn"

        shipping_result = validate_content(
            lands,
            areas,
            [("010-dev-secret.json", development)],
            development_registry,
            image_dir,
            shipping=True,
        )
        assert any(
            "development-only content is forbidden" in error
            for error in shipping_result.errors
        ), shipping_result.errors

        for name, discoveries, case_registry, expected, shipping in cases:
            case_result = validate_content(
                lands,
                areas,
                discoveries,
                case_registry,
                image_dir,
                shipping=shipping,
            )
            assert any(
                expected in error
                for error in case_result.errors
            ), f"{name}: expected '{expected}' in {case_result.errors}"

    print("Content validator self-tests passed.")


def print_result(result):
    for warning in result.warnings:
        print(f"WARNING: {warning}")

    for error in result.errors:
        print(f"ERROR: {error}", file=sys.stderr)


def main():
    parser = argparse.ArgumentParser(
        description="Validate Park Hunt ContentAdmin editorial source."
    )
    parser.add_argument(
        "--shipping",
        action="store_true",
        help=(
            "Apply release/field-test rules: reject development-only, "
            "placeholder, unverified, and needs-recheck content."
        ),
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run validator mutation tests instead of repository validation.",
    )
    args = parser.parse_args()

    if args.self_test:
        run_self_test()
        return

    lands, areas, discoveries, registry = load_admin_source()
    result = validate_content(
        lands,
        areas,
        discoveries,
        registry,
        IMAGE_DIR,
        shipping=args.shipping,
    )
    print_result(result)

    if result.errors:
        raise SystemExit(
            f"Content validation failed with {len(result.errors)} error(s)."
        )

    print(
        f"Content validation passed with {len(result.warnings)} warning(s)."
    )


if __name__ == "__main__":
    main()
