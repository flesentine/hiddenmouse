#!/usr/bin/env python3
import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ADMIN_DIR = ROOT / "ContentAdmin"
LANDS_PATH = ADMIN_DIR / "lands.json"
AREAS_PATH = ADMIN_DIR / "areas.json"
DISCOVERIES_DIR = ADMIN_DIR / "discoveries"
OUTPUT_PATH = ROOT / "ParkHunt" / "Resources" / "content-catalog.json"
SCHEMA_VERSION = 1


def load_json(path: Path):
    try:
        with path.open("r", encoding="utf-8") as handle:
            return json.load(handle)
    except FileNotFoundError:
        raise SystemExit(f"Missing content-admin file: {path.relative_to(ROOT)}")
    except json.JSONDecodeError as error:
        raise SystemExit(
            f"Invalid JSON in {path.relative_to(ROOT)}: "
            f"line {error.lineno}, column {error.colno}: {error.msg}"
        )


def load_array(path: Path, label: str):
    value = load_json(path)
    if not isinstance(value, list):
        raise SystemExit(
            f"{path.relative_to(ROOT)} must contain a JSON array of {label}."
        )
    return value


def runtime_discovery(value):
    if not isinstance(value, dict):
        return value

    return {
        key: field_value
        for key, field_value in value.items()
        if not key.startswith("_")
    }


def load_discoveries():
    if not DISCOVERIES_DIR.is_dir():
        raise SystemExit(
            f"Missing discoveries directory: {DISCOVERIES_DIR.relative_to(ROOT)}"
        )

    paths = sorted(DISCOVERIES_DIR.glob("*.json"))
    if not paths:
        raise SystemExit("ContentAdmin/discoveries must contain at least one .json file.")

    discoveries = []
    for path in paths:
        value = load_json(path)
        if not isinstance(value, dict):
            raise SystemExit(
                f"{path.relative_to(ROOT)} must contain one JSON discovery object."
            )
        discoveries.append(runtime_discovery(value))

    return discoveries


def generated_catalog():
    return {
        "schemaVersion": SCHEMA_VERSION,
        "lands": load_array(LANDS_PATH, "lands"),
        "areas": load_array(AREAS_PATH, "areas"),
        "discoveries": load_discoveries(),
    }


def serialized_catalog():
    return json.dumps(
        generated_catalog(),
        indent=2,
        ensure_ascii=False,
    ) + "\n"


def check_catalog(expected: str):
    if not OUTPUT_PATH.is_file():
        raise SystemExit(
            f"Generated catalog is missing: {OUTPUT_PATH.relative_to(ROOT)}\n"
            "Run: python3 scripts/build-content-catalog.py"
        )

    actual = OUTPUT_PATH.read_text(encoding="utf-8")
    if actual != expected:
        print(
            "Generated content catalog is stale or was edited directly.",
            file=sys.stderr,
        )
        print(
            "Run: python3 scripts/build-content-catalog.py",
            file=sys.stderr,
        )
        raise SystemExit(1)

    print("Content-admin catalog is synchronized.")


def write_catalog(expected: str):
    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_PATH.write_text(expected, encoding="utf-8")
    count = len(generated_catalog()["discoveries"])
    print(
        f"Wrote {OUTPUT_PATH.relative_to(ROOT)} with {count} "
        f"discovery{'ies' if count != 1 else ''}."
    )


def main():
    parser = argparse.ArgumentParser(
        description="Build Park Hunt's bundled runtime catalog from ContentAdmin."
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="Fail if the generated runtime catalog is not synchronized.",
    )
    args = parser.parse_args()

    expected = serialized_catalog()

    if args.check:
        check_catalog(expected)
    else:
        write_catalog(expected)


if __name__ == "__main__":
    main()
