#!/usr/bin/env python3
"""Report Swift files under phpmon/ and tests/ that are missing from Xcode.

This compares the filesystem with PHP Monitor.xcodeproj/project.pbxproj and
reports two cases:
  - files present on disk but not referenced by the project at all
  - Swift file references that exist but are not part of a Sources build phase

It intentionally has no third-party dependencies.
"""

from __future__ import annotations

import argparse
import os
import re
import sys
from pathlib import Path


ROOT_DIRS = ("phpmon", "tests")
PROJECT_FILE = Path("PHP Monitor.xcodeproj/project.pbxproj")


def parse_attrs(body: str) -> dict[str, str]:
    attrs: dict[str, str] = {}
    for key in ("isa", "path", "name", "sourceTree", "fileRef"):
        match = re.search(rf"\b{key} = ([^;]+);", body)
        if match:
            value = match.group(1).strip().strip('"')
            if key == "fileRef":
                value = value.split()[0]
            attrs[key] = value
    return attrs


def parse_children(body: str) -> list[str]:
    match = re.search(r"children = \((.*?)\);", body, re.S)
    if not match:
        return []
    return re.findall(r"\b([A-F0-9]{24})\b", match.group(1))


def parse_sources_files(body: str) -> list[str]:
    if "isa = PBXSourcesBuildPhase;" not in body:
        return []
    match = re.search(r"files = \((.*?)\);", body, re.S)
    if not match:
        return []
    return re.findall(r"\b([A-F0-9]{24})\b", match.group(1))


def parse_project(path: Path):
    objects = {}
    current_id = None
    current_lines: list[str] = []

    def add_current():
        if current_id is None:
            return
        body = "\n".join(current_lines)
        attrs = parse_attrs(body)
        attrs["children"] = parse_children(body)
        attrs["sourceFiles"] = parse_sources_files(body)
        objects[current_id] = attrs

    for line in path.read_text(encoding="utf-8").splitlines():
        start = re.match(r"\s*([A-F0-9]{24}) /\* .*? \*/ = \{(.*)$", line)
        if start:
            current_id = start.group(1)
            current_lines = [start.group(2)]
            if line.rstrip().endswith("};"):
                add_current()
                current_id = None
                current_lines = []
            continue

        if current_id is not None:
            current_lines.append(line)
            if line.strip() == "};":
                add_current()
                current_id = None
                current_lines = []

    return objects


def build_parent_map(objects) -> dict[str, str]:
    parents = {}
    for object_id, attrs in objects.items():
        if attrs.get("isa") != "PBXGroup":
            continue
        for child in attrs.get("children", []):
            parents[child] = object_id
    return parents


def object_label(attrs: dict[str, str]) -> str | None:
    return attrs.get("path") or attrs.get("name")


def resolved_file_path(object_id: str, objects, parents) -> str | None:
    attrs = objects[object_id]
    label = object_label(attrs)
    if not label:
        return None

    parts = [label]
    parent_id = parents.get(object_id)
    while parent_id:
        parent = objects.get(parent_id, {})
        parent_label = object_label(parent)
        if parent_label:
            parts.append(parent_label)
        parent_id = parents.get(parent_id)

    parts.reverse()

    for index, part in enumerate(parts):
        if part in ROOT_DIRS:
            return str(Path(*parts[index:]))

    return None


def filesystem_swift_files() -> set[str]:
    files: set[str] = set()
    for root in ROOT_DIRS:
        root_path = Path(root)
        if not root_path.exists():
            continue
        for path in root_path.rglob("*.swift"):
            files.add(path.as_posix())
    return files


def xcode_swift_files(objects, parents) -> dict[str, str]:
    files: dict[str, str] = {}
    for object_id, attrs in objects.items():
        if attrs.get("isa") != "PBXFileReference":
            continue
        if not (object_label(attrs) or "").endswith(".swift"):
            continue
        path = resolved_file_path(object_id, objects, parents)
        if path and path.startswith(ROOT_DIRS):
            files[path] = object_id
    return files


def source_phase_file_refs(objects) -> set[str]:
    build_file_refs: dict[str, str] = {}
    source_build_files: set[str] = set()

    for object_id, attrs in objects.items():
        if attrs.get("isa") == "PBXBuildFile" and attrs.get("fileRef"):
            build_file_refs[object_id] = attrs["fileRef"]
        for build_file_id in attrs.get("sourceFiles", []):
            source_build_files.add(build_file_id)

    return {
        build_file_refs[build_file_id]
        for build_file_id in source_build_files
        if build_file_id in build_file_refs
    }


def print_section(title: str, paths: list[str]) -> None:
    print(title)
    if not paths:
        print("  none")
        return
    for path in paths:
        print(f"  {path}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", default=PROJECT_FILE, type=Path)
    args = parser.parse_args()

    if not args.project.exists():
        print(f"Project file not found: {args.project}", file=sys.stderr)
        return 2

    objects = parse_project(args.project)
    parents = build_parent_map(objects)

    disk_files = filesystem_swift_files()
    project_files = xcode_swift_files(objects, parents)
    source_refs = source_phase_file_refs(objects)

    missing_from_project = sorted(disk_files - set(project_files.keys()))
    missing_from_sources = sorted(
        path for path, object_id in project_files.items()
        if object_id not in source_refs
    )

    print_section("Swift files on disk but not referenced by Xcode:", missing_from_project)
    print()
    print_section("Swift file references not included in a Sources build phase:", missing_from_sources)

    if missing_from_project or missing_from_sources:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
