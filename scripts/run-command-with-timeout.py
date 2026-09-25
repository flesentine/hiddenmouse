#!/usr/bin/env python3
import subprocess
import sys

if len(sys.argv) < 3:
    raise SystemExit("Usage: run-command-with-timeout.py SECONDS COMMAND [ARG ...]")

try:
    timeout_seconds = int(sys.argv[1])
except ValueError:
    raise SystemExit("SECONDS must be an integer")

if timeout_seconds <= 0:
    raise SystemExit("SECONDS must be > 0")

command = sys.argv[2:]

try:
    completed = subprocess.run(command, timeout=timeout_seconds)
except subprocess.TimeoutExpired:
    print(
        f"Command timed out after {timeout_seconds}s: {' '.join(command)}",
        file=sys.stderr,
    )
    raise SystemExit(124)

raise SystemExit(completed.returncode)
