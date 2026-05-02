import json
import re
from collections import defaultdict
from pathlib import Path
from typing import Pattern

from atomic_red_team.common import base_path


PlatformFilter = str | Pattern[str]


class Attack:
    """Loads MITRE ATT&CK technique metadata used by documentation generation."""

    def __init__(self, attack_file: str | Path | None = None):
        self.attack_file = (
            Path(attack_file)
            if attack_file
            else Path(base_path) / "atomic_red_team" / "enterprise-attack.json"
        )
        self._techniques: list[dict] | None = None
        self._techniques_by_id: dict[str, dict] | None = None

    def ordered_tactics(self) -> list[str]:
        return [
            "reconnaissance",
            "resource-development",
            "initial-access",
            "execution",
            "persistence",
            "privilege-escalation",
            "stealth",
            "defense-impairment",
            "credential-access",
            "discovery",
            "lateral-movement",
            "collection",
            "command-and-control",
            "exfiltration",
            "impact",
        ]

    def technique_identifier_for_technique(self, technique: dict) -> str:
        reference = next(
            ref
            for ref in technique.get("external_references", [])
            if ref.get("source_name") == "mitre-attack"
        )
        return reference["external_id"].upper()

    def technique_info(self, technique_id: str) -> dict | None:
        return self.techniques_by_id.get(technique_id.upper())

    def ordered_tactic_to_technique_matrix(
        self,
        only_platform: PlatformFilter = ".*",
    ) -> list[list[dict | None]]:
        techniques_by_tactic = self.techniques_by_tactic(only_platform=only_platform)
        tactic_order = [
            techniques_by_tactic[tactic] for tactic in self.ordered_tactics()
        ]
        max_techniques = max(
            (len(techniques) for techniques in tactic_order), default=0
        )
        if max_techniques == 0:
            return []
        for techniques in tactic_order:
            techniques.extend([None] * (max_techniques - len(techniques)))
        return [list(row) for row in zip(*tactic_order)]

    def techniques_by_tactic(
        self,
        only_platform: PlatformFilter = ".*",
    ) -> dict[str, list[dict]]:
        result: dict[str, list[dict]] = defaultdict(list)
        for technique in self.techniques:
            platforms = technique.get("x_mitre_platforms")
            if not platforms:
                continue
            if not any(
                _matches_platform(platform, only_platform) for platform in platforms
            ):
                continue
            if technique.get("revoked", False) or technique.get(
                "x_mitre_deprecated", False
            ):
                continue
            for tactic in technique.get("kill_chain_phases", []):
                if tactic.get("kill_chain_name") == "mitre-attack":
                    result[tactic["phase_name"]].append(technique)
        return result

    @property
    def techniques(self) -> list[dict]:
        if self._techniques is None:
            raw = [
                obj
                for obj in json.loads(self.attack_file.read_text())["objects"]
                if obj.get("type") == "attack-pattern"
            ]
            id_to_name = {
                _attack_id(obj): obj["name"]
                for obj in raw
                if _attack_id(obj) is not None
            }
            techniques = []
            for obj in raw:
                tid = _attack_id(obj)
                if tid is None:
                    continue
                t = dict(obj)
                if "." in tid:
                    parent_name = id_to_name.get(tid.split(".")[0])
                    if parent_name:
                        t["name"] = f"{parent_name}: {t['name']}"
                techniques.append(t)
            self._techniques = techniques
        return self._techniques

    @property
    def techniques_by_id(self) -> dict[str, dict]:
        if self._techniques_by_id is None:
            self._techniques_by_id = {
                tid: t
                for t in self.techniques
                if (tid := _attack_id(t)) is not None
            }
        return self._techniques_by_id


def _attack_id(technique: dict) -> str | None:
    """Return the ATT&CK ID (e.g. 'T1059.001') for a technique dict, or None."""
    for ref in technique.get("external_references", []):
        if ref.get("source_name") == "mitre-attack":
            return ref["external_id"].upper()
    return None


def _matches_platform(platform: str, only_platform: PlatformFilter) -> bool:
    # Normalize STIX platform names ("Azure AD" -> "azure-ad", "IaaS" -> "iaas") so
    # they match the hyphenated YAML platform strings used as filters.
    normalized = platform.lower().replace(" ", "-")
    if isinstance(only_platform, str):
        # Also match in the other direction so "iaas" matches filter "iaas:gcp".
        return (
            re.search(only_platform, normalized) is not None
            or re.search(re.escape(normalized), only_platform) is not None
        )
    return only_platform.search(normalized) is not None
