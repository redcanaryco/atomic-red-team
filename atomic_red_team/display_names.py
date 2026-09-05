import json
import re
from os.path import join
from typing import Dict, Tuple

from atomic_red_team.common import base_path

attack_data_file = join(base_path, "atomic_red_team", "enterprise-attack.json")

_display_name_pattern = re.compile(r"^(display_name:[ \t]*)(.+)$", re.MULTILINE)


def load_current_technique_names(path: str = attack_data_file) -> Dict[str, str]:
    """Loads the current (non-deprecated, non-revoked) ATT&CK technique names by ID.

    Args:
        path: Path to the bundled enterprise-attack.json STIX file.

    Returns:
        A mapping of ATT&CK technique ID (e.g. "T1129") to its current official name.
    """
    with open(path, "r", encoding="utf-8") as f:
        bundle = json.load(f)

    names = {}
    for obj in bundle["objects"]:
        if obj.get("type") != "attack-pattern":
            continue
        if obj.get("x_mitre_deprecated") or obj.get("revoked"):
            continue
        for ref in obj.get("external_references", []):
            technique_id = ref.get("external_id", "")
            if ref.get("source_name") == "mitre-attack" and technique_id.startswith(
                "T"
            ):
                names[technique_id] = obj["name"]
    return names


def _parse_display_name(text: str) -> str:
    match = _display_name_pattern.search(text)
    if not match:
        raise ValueError("no display_name field found")
    raw = match.group(2).strip()
    if len(raw) >= 2 and raw[0] == raw[-1] and raw[0] in ("'", '"'):
        raw = raw[1:-1]
    return raw


def expected_display_name(
    technique_id: str, official_names: Dict[str, str]
) -> str:
    """Computes the display_name a technique file should have.

    Sub-techniques follow the repo's "Parent: Sub" house style, built from the
    current official parent and sub-technique names. Base techniques get the plain
    official name.

    Args:
        technique_id: The ATT&CK technique ID, e.g. "T1218.010".
        official_names: Mapping of technique ID to current official ATT&CK name.

    Returns:
        The display_name the file should have.
    """
    official = official_names[technique_id]
    if "." not in technique_id:
        return official
    parent_id = technique_id.split(".")[0]
    parent_official = official_names.get(parent_id, "")
    return f"{parent_official}: {official}"


def check_display_names(
    paths: list, official_names: Dict[str, str]
) -> Dict[str, Tuple[str, str]]:
    """Finds atomic files whose display_name doesn't match current ATT&CK naming.

    Args:
        paths: Atomic YAML file paths to check, e.g. from glob("atomics/T*/T*.yaml").
        official_names: Mapping of technique ID to current official ATT&CK name.

    Returns:
        A mapping of file path to (current_display_name, expected_display_name) for
        each file that needs a fix. Files whose technique ID isn't in
        `official_names` (deprecated/revoked/unknown) are skipped.
    """
    mismatches = {}
    for path in paths:
        with open(path, "r", encoding="utf-8") as f:
            text = f.read()
        technique_id_match = re.search(r"^attack_technique:[ \t]*(\S+)$", text, re.M)
        if not technique_id_match:
            continue
        technique_id = technique_id_match.group(1)
        if technique_id not in official_names:
            continue
        current = _parse_display_name(text)
        expected = expected_display_name(technique_id, official_names)
        if current != expected:
            mismatches[path] = (current, expected)
    return mismatches


def _write_display_name(path: str, value: str) -> None:
    """Rewrites a file's display_name field to `value`, double-quoted, in place.

    Preserves the file's original line endings.

    Args:
        path: Path to the atomic YAML file to rewrite.
        value: The new (unquoted) display_name text to write.
    """
    with open(path, "rb") as f:
        raw = f.read()
    uses_crlf = b"\r\n" in raw
    text = raw.decode("utf-8")

    match = _display_name_pattern.search(text)
    replacement = match.group(1) + f'"{value}"'
    text = text[: match.start()] + replacement + text[match.end() :]

    if uses_crlf:
        text = text.replace("\r\n", "\n").replace("\n", "\r\n")
    with open(path, "w", encoding="utf-8", newline="") as f:
        f.write(text)


def fix_display_names(mismatches: Dict[str, Tuple[str, str]]) -> None:
    """Rewrites each file's display_name field to its expected value in place.

    The new value is always wrapped in double quotes, regardless of the file's
    original quoting style. Preserves the file's original line endings.

    Args:
        mismatches: Mapping of file path to (current_display_name,
            expected_display_name), as returned by `check_display_names`.
    """
    for path, (_current, expected) in mismatches.items():
        _write_display_name(path, expected)


def normalize_display_name_quoting(paths: list) -> list:
    """Rewrites each file's display_name to use double quotes, keeping its text as-is.

    Files whose display_name is already double-quoted are left untouched.

    Args:
        paths: Atomic YAML file paths to normalize, e.g. from
            glob("atomics/T*/T*.yaml").

    Returns:
        The list of paths that were rewritten.
    """
    changed = []
    for path in paths:
        with open(path, "r", encoding="utf-8") as f:
            text = f.read()
        match = _display_name_pattern.search(text)
        if not match:
            continue
        raw = match.group(2).strip()
        if raw.startswith('"') and raw.endswith('"'):
            continue
        value = _parse_display_name(text)
        _write_display_name(path, value)
        changed.append(path)
    return changed
