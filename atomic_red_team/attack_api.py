"""
Attack API module for loading and querying MITRE ATT&CK technique data.

This module provides the Attack class that loads information about ATT&CK techniques
from MITRE's ATT&CK STIX representation using the mitreattack-python library.
"""

import json
import re
from pathlib import Path
from typing import Dict, List, Optional, Pattern

# Tactics in the order that the ATT&CK matrix uses
ORDERED_TACTICS = [
    "initial-access",
    "execution",
    "persistence",
    "privilege-escalation",
    "defense-evasion",
    "credential-access",
    "discovery",
    "lateral-movement",
    "collection",
    "exfiltration",
    "command-and-control",
    "impact",
]


class Attack:
    """
    API class that loads information about ATT&CK techniques from MITRE's ATT&CK
    STIX representation. Optimized for speed with caching.
    """

    def __init__(self, stix_file: Optional[str] = None):
        """
        Initialize the Attack API.

        Args:
            stix_file: Optional path to a local STIX JSON file.
                      Defaults to enterprise-attack.json in the same directory.
        """
        if stix_file is None:
            stix_file = str(Path(__file__).parent / "enterprise-attack.json")
        self._stix_file = stix_file
        self._techniques: Optional[List[dict]] = None
        self._technique_by_id: Optional[Dict[str, dict]] = None
        self._attack_stix: Optional[dict] = None

    def _load_stix(self) -> dict:
        """Load and cache the STIX JSON data."""
        if self._attack_stix is None:
            with open(self._stix_file, "r", encoding="utf-8") as f:
                self._attack_stix = json.load(f)
        return self._attack_stix

    @property
    def ordered_tactics(self) -> List[str]:
        """Returns tactics in the order that the ATT&CK matrix uses."""
        return ORDERED_TACTICS

    def technique_identifier_for_technique(self, technique: dict) -> str:
        """
        Returns the technique identifier (e.g., T1234) for a Technique object.

        Args:
            technique: A technique dictionary from the STIX data.

        Returns:
            The technique ID (e.g., "T1234" or "T1234.001").
        """
        external_refs = technique.get("external_references", [])
        for ref in external_refs:
            if ref.get("source_name") == "mitre-attack":
                return ref.get("external_id", "").upper()
        return ""

    def _build_technique_index(self) -> Dict[str, dict]:
        """Build an index of technique_id -> technique for fast lookups."""
        if self._technique_by_id is None:
            self._technique_by_id = {}
            for technique in self.techniques:
                tech_id = self.technique_identifier_for_technique(technique)
                if tech_id:
                    self._technique_by_id[tech_id] = technique
        return self._technique_by_id

    def technique_info(self, technique_id: str) -> Optional[dict]:
        """
        Returns a Technique object given a technique identifier (T1234).

        Args:
            technique_id: The technique ID (e.g., "T1234").

        Returns:
            The technique dictionary or None if not found.
        """
        index = self._build_technique_index()
        return index.get(technique_id.upper())

    def ordered_tactic_to_technique_matrix(
        self, only_platform: Pattern = re.compile(r".*")
    ) -> List[List[Optional[dict]]]:
        """
        Returns the ATT&CK Matrix as a 2D array, in order by ordered_tactics.

        Args:
            only_platform: Regex pattern to filter techniques by platform.

        Returns:
            2D list of techniques organized by tactic columns.
        """
        all_techniques = self.techniques_by_tactic(only_platform=only_platform)

        # Make a 2D array of techniques in the order our tactics appear
        all_techniques_in_tactic_order = []
        for tactic in self.ordered_tactics:
            all_techniques_in_tactic_order.append(all_techniques.get(tactic, []))

        # Figure out the max number of techniques any one tactic has
        max_techniques = (
            max(len(techs) for techs in all_techniques_in_tactic_order)
            if all_techniques_in_tactic_order
            else 0
        )

        if max_techniques == 0:
            return []

        # Extend each array of techniques to that length
        for techniques in all_techniques_in_tactic_order:
            techniques.extend([None] * (max_techniques - len(techniques)))

        # Transpose to give us the data in columnar format
        return list(map(list, zip(*all_techniques_in_tactic_order)))

    def techniques_by_tactic(
        self, only_platform: Pattern = re.compile(r".*")
    ) -> Dict[str, List[dict]]:
        """
        Returns a map of all [ATT&CK Tactic name] => [List of ATT&CK techniques].

        Args:
            only_platform: Regex pattern to filter techniques by platform.

        Returns:
            Dictionary mapping tactic names to lists of techniques.
        """
        techniques_by_tactic: Dict[str, List[dict]] = {}

        for technique in self.techniques:
            platforms = technique.get("x_mitre_platforms")
            if platforms is None:
                continue

            # Check if any platform matches
            platform_match = any(
                only_platform.match(p.lower().replace(" ", "-")) for p in platforms
            )
            if not platform_match:
                continue

            # Skip revoked or deprecated techniques
            if technique.get("revoked", False):
                continue
            if technique.get("x_mitre_deprecated", False):
                continue

            # Add to each tactic this technique belongs to
            kill_chain_phases = technique.get("kill_chain_phases", [])
            for phase in kill_chain_phases:
                if phase.get("kill_chain_name") == "mitre-attack":
                    tactic_name = phase.get("phase_name")
                    if tactic_name:
                        if tactic_name not in techniques_by_tactic:
                            techniques_by_tactic[tactic_name] = []
                        techniques_by_tactic[tactic_name].append(technique)

        return techniques_by_tactic

    @property
    def techniques(self) -> List[dict]:
        """
        Returns a list of all ATT&CK techniques.

        Returns:
            List of technique dictionaries.
        """
        if self._techniques is not None:
            return self._techniques

        stix_data = self._load_stix()
        self._techniques = []

        for item in stix_data.get("objects", []):
            if item.get("type") != "attack-pattern":
                continue

            # Check if it has mitre-attack external reference
            external_refs = item.get("external_references", [])
            has_mitre_ref = any(
                ref.get("source_name") == "mitre-attack" for ref in external_refs
            )
            if has_mitre_ref:
                self._techniques.append(item)

        return self._techniques

    def get_tactics(self) -> List[dict]:
        """
        Returns a list of all ATT&CK tactics.

        Returns:
            List of tactic dictionaries.
        """
        stix_data = self._load_stix()
        tactics = []
        for item in stix_data.get("objects", []):
            if item.get("type") == "x-mitre-tactic":
                tactics.append(item)
        return tactics


# Singleton instance for convenience - lazy loaded
_attack_api: Optional[Attack] = None


def get_attack_api() -> Attack:
    """Get or create the singleton Attack API instance."""
    global _attack_api
    if _attack_api is None:
        _attack_api = Attack()
    return _attack_api


# For backwards compatibility
ATTACK_API = Attack()
