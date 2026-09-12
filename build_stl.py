#!/usr/bin/env python3
"""Render every .scad file in this directory to stl/<name>.stl via OpenSCAD."""

import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
STL_DIR = ROOT / "stl"


def main():
    STL_DIR.mkdir(exist_ok=True)

    scad_files = sorted(ROOT.glob("*.scad"))
    if not scad_files:
        print("No .scad files found.")
        return 1

    failures = []
    for scad_file in scad_files:
        stl_file = STL_DIR / (scad_file.stem + ".stl")
        print(f"{scad_file.name} -> {stl_file.relative_to(ROOT)}")
        result = subprocess.run(
            ["openscad", "-o", str(stl_file), str(scad_file)],
            capture_output=True,
            text=True,
        )
        if result.returncode != 0:
            failures.append(scad_file.name)
            print(result.stderr, file=sys.stderr)

    if failures:
        print(f"\nFailed to render: {', '.join(failures)}", file=sys.stderr)
        return 1

    print(f"\nRendered {len(scad_files)} file(s) into {STL_DIR}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
