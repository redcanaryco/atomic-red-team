"""
Atomic Red Team documentation generator.

This module generates all documentation including:
- Individual technique markdown files
- ATT&CK matrices (markdown)
- Platform-specific indexes (markdown, CSV, YAML)
- ATT&CK Navigator layers (JSON)
"""

import csv
import json
import re
from concurrent.futures import ProcessPoolExecutor, as_completed
from io import StringIO
from pathlib import Path
from typing import Dict, List, Optional, Pattern, Tuple

from atomic_red_team.attack_api import ATTACK_API
from atomic_red_team.utils import ATOMIC_RED_TEAM, AtomicRedTeam
import yaml

# Platform configurations for index generation
PLATFORM_CONFIGS = {
    "all": {"pattern": re.compile(r".*"), "attack_pattern": re.compile(r".*")},
    "windows": {
        "pattern": re.compile(r"windows"),
        "attack_pattern": re.compile(r"windows"),
    },
    "macos": {
        "pattern": re.compile(r"macos"),
        "attack_pattern": re.compile(r"windows"),
    },
    "linux": {
        "pattern": re.compile(r"linux"),
        "attack_pattern": re.compile(r"windows"),
    },
    "iaas": {"pattern": re.compile(r"iaas"), "attack_pattern": re.compile(r"windows")},
    "containers": {
        "pattern": re.compile(r"containers"),
        "attack_pattern": re.compile(r"windows"),
    },
    "office-365": {
        "pattern": re.compile(r"office-365"),
        "attack_pattern": re.compile(r"office"),
    },
    "google-workspace": {
        "pattern": re.compile(r"google-workspace"),
        "attack_pattern": re.compile(r"office"),
    },
    "azure-ad": {
        "pattern": re.compile(r"azure-ad"),
        "attack_pattern": re.compile(r"identity"),
    },
    "esxi": {"pattern": re.compile(r"esxi"), "attack_pattern": re.compile(r"esxi")},
    "iaas:gcp": {
        "pattern": re.compile(r"iaas:gcp"),
        "attack_pattern": re.compile(r".*"),
    },
    "iaas:azure": {
        "pattern": re.compile(r"iaas:azure"),
        "attack_pattern": re.compile(r".*"),
    },
    "iaas:aws": {
        "pattern": re.compile(r"iaas:aws"),
        "attack_pattern": re.compile(r".*"),
    },
}


def _generate_technique_doc_worker(
    args: Tuple[dict, str],
) -> Tuple[str, bool, Optional[str]]:
    """Standalone function for ProcessPoolExecutor to generate a single technique doc."""
    atomic_yaml, atomics_directory = args
    try:

        art = AtomicRedTeam(atomics_directory=atomics_directory)
        yaml_path = atomic_yaml["atomic_yaml_path"]
        md_path = yaml_path.replace(".yaml", ".md")
        technique_id = atomic_yaml.get("attack_technique", "").upper()
        art.generate_technique_docs(technique_id, md_path)
        return (yaml_path, True, None)
    except Exception as ex:
        return (atomic_yaml.get("atomic_yaml_path", "unknown"), False, str(ex))


def _generate_matrix_worker(args: Tuple[str, str, str, Optional[str]]) -> None:
    """Standalone function for ProcessPoolExecutor to generate a matrix."""
    title_prefix, output_path, atomics_directory, platform_pattern = args
    import importlib
    from pathlib import Path
    
    doc_generator = importlib.import_module('atomic_red_team.doc_generator')
    utils = importlib.import_module('atomic_red_team.utils')
    
    art = utils.AtomicRedTeam(atomics_directory=atomics_directory)
    docs = doc_generator.AtomicRedTeamDocs(atomic_red_team=art)
    pattern = re.compile(platform_pattern) if platform_pattern else re.compile(r".*")
    docs.generate_attack_matrix(title_prefix, Path(output_path), only_platform=pattern)


def _generate_index_worker(
    args: Tuple[str, str, str, Optional[str], Optional[str]],
) -> None:
    """Standalone function for ProcessPoolExecutor to generate a markdown index."""
    (
        title_prefix,
        output_path,
        atomics_directory,
        only_platform_pattern,
        attack_platform_pattern,
    ) = args
    import importlib
    from pathlib import Path
    
    doc_generator = importlib.import_module('atomic_red_team.doc_generator')
    utils = importlib.import_module('atomic_red_team.utils')

    art = utils.AtomicRedTeam(atomics_directory=atomics_directory)
    docs = doc_generator.AtomicRedTeamDocs(atomic_red_team=art)
    only_platform = (
        re.compile(only_platform_pattern)
        if only_platform_pattern
        else re.compile(r".*")
    )
    attack_platform = (
        re.compile(attack_platform_pattern)
        if attack_platform_pattern
        else re.compile(r".*")
    )
    docs.generate_index(
        title_prefix,
        Path(output_path),
        only_platform=only_platform,
        attack_platform=attack_platform,
    )


def _generate_index_csv_worker(
    args: Tuple[str, str, Optional[str], Optional[str]],
) -> None:
    """Standalone function for ProcessPoolExecutor to generate a CSV index."""
    output_path, atomics_directory, only_platform_pattern, attack_platform_pattern = (
        args
    )
    import importlib
    from pathlib import Path
    
    doc_generator = importlib.import_module('atomic_red_team.doc_generator')
    utils = importlib.import_module('atomic_red_team.utils')

    art = utils.AtomicRedTeam(atomics_directory=atomics_directory)
    docs = doc_generator.AtomicRedTeamDocs(atomic_red_team=art)
    only_platform = (
        re.compile(only_platform_pattern)
        if only_platform_pattern
        else re.compile(r".*")
    )
    attack_platform = (
        re.compile(attack_platform_pattern)
        if attack_platform_pattern
        else re.compile(r".*")
    )
    docs.generate_index_csv(
        Path(output_path), only_platform=only_platform, attack_platform=attack_platform
    )


def _generate_yaml_index_worker(args: Tuple[str, str]) -> None:
    """Standalone function for ProcessPoolExecutor to generate a YAML index."""
    output_path, atomics_directory = args
    import importlib
    from pathlib import Path
    
    doc_generator = importlib.import_module('atomic_red_team.doc_generator')
    utils = importlib.import_module('atomic_red_team.utils')
    
    art = utils.AtomicRedTeam(atomics_directory=atomics_directory)
    docs = doc_generator.AtomicRedTeamDocs(atomic_red_team=art)
    docs.generate_yaml_index(Path(output_path))


def _generate_yaml_index_by_platform_worker(args: Tuple[str, str, str]) -> None:
    """Standalone function for ProcessPoolExecutor to generate a platform-specific YAML index."""
    output_path, atomics_directory, platform = args
    import importlib
    from pathlib import Path
    
    doc_generator = importlib.import_module('atomic_red_team.doc_generator')
    utils = importlib.import_module('atomic_red_team.utils')
    
    art = utils.AtomicRedTeam(atomics_directory=atomics_directory)
    docs = doc_generator.AtomicRedTeamDocs(atomic_red_team=art)
    docs.generate_yaml_index_by_platform(Path(output_path), platform)


class AtomicRedTeamDocs:
    """
    Documentation generator for Atomic Red Team.

    Generates all documentation including technique docs, indexes, matrices,
    and ATT&CK Navigator layers.
    """

    def __init__(self, atomic_red_team: Optional[AtomicRedTeam] = None):
        """Initialize the documentation generator."""
        self.atomic_red_team = atomic_red_team or ATOMIC_RED_TEAM
        self.atomics_directory = self.atomic_red_team.atomics_directory

    def generate_all_the_docs(self) -> Tuple[List[str], List[str]]:
        """
        Generate all documentation used by Atomic Red Team.

        Returns:
            Tuple of (successful_paths, failed_paths)
        """
        oks = []
        fails = []

        # Generate individual technique docs concurrently
        with ProcessPoolExecutor() as executor:
            future_to_yaml = {
                executor.submit(
                    _generate_technique_doc_worker,
                    (atomic_yaml, self.atomics_directory),
                ): atomic_yaml
                for atomic_yaml in self.atomic_red_team.atomic_tests
            }

            for future in as_completed(future_to_yaml):
                yaml_path, success, error = future.result()
                if success:
                    oks.append(yaml_path)
                else:
                    fails.append(yaml_path)
                    print(f"✗ {yaml_path}: {error}")

        print(f"\nGenerated docs for {len(oks)} techniques, {len(fails)} failures")

        # Prepare directories
        indexes_dir = Path(self.atomics_directory) / "Indexes"
        matrices_dir = indexes_dir / "Matrices"
        md_indexes_dir = indexes_dir / "Indexes-Markdown"
        csv_indexes_dir = indexes_dir / "Indexes-CSV"
        layers_dir = indexes_dir / "Attack-Navigator-Layers"

        for dir_path in [matrices_dir, md_indexes_dir, csv_indexes_dir, layers_dir]:
            dir_path.mkdir(parents=True, exist_ok=True)

        print("\nGenerating indexes and matrices concurrently...")
        
        # Prepare all index generation tasks
        tasks = []
        
        # ATT&CK matrices
        tasks.append(("matrix", _generate_matrix_worker, ("All", str(matrices_dir / "matrix.md"), self.atomics_directory, None)))
        tasks.append(("windows-matrix", _generate_matrix_worker, ("Windows", str(matrices_dir / "windows-matrix.md"), self.atomics_directory, r"windows")))
        tasks.append(("macos-matrix", _generate_matrix_worker, ("macOS", str(matrices_dir / "macos-matrix.md"), self.atomics_directory, r"macos")))
        tasks.append(("linux-matrix", _generate_matrix_worker, ("Linux", str(matrices_dir / "linux-matrix.md"), self.atomics_directory, r"linux")))
        tasks.append(("esxi-matrix", _generate_matrix_worker, ("ESXi", str(matrices_dir / "esxi-matrix.md"), self.atomics_directory, r"esxi")))

        # Markdown indexes
        tasks.append(("md-index-all", _generate_index_worker, ("All", str(md_indexes_dir / "index.md"), self.atomics_directory, None, None)))
        tasks.append(("md-index-windows", _generate_index_worker, ("Windows", str(md_indexes_dir / "windows-index.md"), self.atomics_directory, r"windows", r"windows")))
        tasks.append(("md-index-macos", _generate_index_worker, ("macOS", str(md_indexes_dir / "macos-index.md"), self.atomics_directory, r"macos", r"windows")))
        tasks.append(("md-index-linux", _generate_index_worker, ("Linux", str(md_indexes_dir / "linux-index.md"), self.atomics_directory, r"linux", r"windows")))
        tasks.append(("md-index-iaas", _generate_index_worker, ("IaaS", str(md_indexes_dir / "iaas-index.md"), self.atomics_directory, r"iaas", r"windows")))
        tasks.append(("md-index-containers", _generate_index_worker, ("Containers", str(md_indexes_dir / "containers-index.md"), self.atomics_directory, r"containers", r"windows")))
        tasks.append(("md-index-office365", _generate_index_worker, ("Office 365", str(md_indexes_dir / "office-365-index.md"), self.atomics_directory, r"office-365", r"office")))
        tasks.append(("md-index-google-workspace", _generate_index_worker, ("Google Workspace", str(md_indexes_dir / "google-workspace-index.md"), self.atomics_directory, r"google-workspace", r"office")))
        tasks.append(("md-index-azure-ad", _generate_index_worker, ("Azure AD", str(md_indexes_dir / "azure-ad-index.md"), self.atomics_directory, r"azure-ad", r"identity")))
        tasks.append(("md-index-esxi", _generate_index_worker, ("ESXi", str(md_indexes_dir / "esxi-index.md"), self.atomics_directory, r"esxi", r"esxi")))

        # CSV indexes
        tasks.append(("csv-index-all", _generate_index_csv_worker, (str(csv_indexes_dir / "index.csv"), self.atomics_directory, None, None)))
        tasks.append(("csv-index-windows", _generate_index_csv_worker, (str(csv_indexes_dir / "windows-index.csv"), self.atomics_directory, r"windows", r"windows")))
        tasks.append(("csv-index-macos", _generate_index_csv_worker, (str(csv_indexes_dir / "macos-index.csv"), self.atomics_directory, r"macos", r"macos")))
        tasks.append(("csv-index-linux", _generate_index_csv_worker, (str(csv_indexes_dir / "linux-index.csv"), self.atomics_directory, r"linux", r"linux")))
        tasks.append(("csv-index-iaas", _generate_index_csv_worker, (str(csv_indexes_dir / "iaas-index.csv"), self.atomics_directory, r"iaas", r"iaas")))
        tasks.append(("csv-index-containers", _generate_index_csv_worker, (str(csv_indexes_dir / "containers-index.csv"), self.atomics_directory, r"containers", r"containers")))
        tasks.append(("csv-index-office365", _generate_index_csv_worker, (str(csv_indexes_dir / "office-365-index.csv"), self.atomics_directory, r"office-365", r"office")))
        tasks.append(("csv-index-google-workspace", _generate_index_csv_worker, (str(csv_indexes_dir / "google-workspace-index.csv"), self.atomics_directory, r"google-workspace", r"identity")))
        tasks.append(("csv-index-azure-ad", _generate_index_csv_worker, (str(csv_indexes_dir / "azure-ad-index.csv"), self.atomics_directory, r"azure-ad", r"identity")))
        tasks.append(("csv-index-esxi", _generate_index_csv_worker, (str(csv_indexes_dir / "esxi-index.csv"), self.atomics_directory, r"esxi", r"esxi")))

        # YAML indexes
        tasks.append(("yaml-index-all", _generate_yaml_index_worker, (str(indexes_dir / "index.yaml"), self.atomics_directory)))
        for platform in ["windows", "macos", "linux", "office-365", "azure-ad", "google-workspace", "iaas", "containers", "iaas:gcp", "iaas:azure", "iaas:aws", "esxi"]:
            filename = f"{platform.replace(':', '_')}-index.yaml"
            tasks.append((f"yaml-index-{platform}", _generate_yaml_index_by_platform_worker, (str(indexes_dir / filename), self.atomics_directory, platform)))

        # Generate all indexes concurrently
        with ProcessPoolExecutor() as executor:
            future_to_task = {executor.submit(task[1], task[2]): task[0] for task in tasks}
            
            for future in as_completed(future_to_task):
                task_name = future_to_task[future]
                try:
                    future.result()
                except Exception as ex:
                    print(f"✗ Error generating {task_name}: {ex}")

        # Generate ATT&CK Navigator layers (this is already optimized internally)
        print("\nGenerating ATT&CK Navigator layers...")
        self.generate_navigator_layers(layers_dir)

        return oks, fails

    def generate_attack_matrix(
        self,
        title_prefix: str,
        output_path: Path,
        only_platform: Pattern = re.compile(r".*"),
    ) -> None:
        """Generate a Markdown ATT&CK matrix."""
        result = f"# {title_prefix} Atomic Tests by ATT&CK Tactic & Technique\n"
        result += f"| {' | '.join(ATTACK_API.ordered_tactics)} |\n"
        result += f"|{'-----|' * len(ATTACK_API.ordered_tactics)}\n"

        matrix = ATTACK_API.ordered_tactic_to_technique_matrix(
            only_platform=only_platform
        )
        for row in matrix:
            row_values = []
            for technique in row:
                if technique:
                    row_values.append(
                        self.atomic_red_team.github_link_to_technique(
                            technique,
                            include_identifier=False,
                            only_platform=only_platform,
                        )
                    )
                else:
                    row_values.append("")
            result += f"| {' | '.join(row_values)} |\n"

        output_path.write_text(result, encoding="utf-8")
        print(f"Generated ATT&CK matrix at {output_path}")

    def generate_index(
        self,
        title_prefix: str,
        output_path: Path,
        only_platform: Pattern = re.compile(r".*"),
        attack_platform: Pattern = re.compile(r".*"),
    ) -> None:
        """Generate a Markdown index of ATT&CK Tactic -> Technique -> Atomic Tests."""
        result = f"# {title_prefix} Atomic Tests by ATT&CK Tactic & Technique\n"

        techniques_by_tactic = ATTACK_API.techniques_by_tactic(
            only_platform=attack_platform
        )
        for tactic, techniques in techniques_by_tactic.items():
            result += f"# {tactic}\n"
            for technique in techniques:
                result += f"- {self.atomic_red_team.github_link_to_technique(technique, include_identifier=True, only_platform=only_platform)}\n"

                atomic_tests = self.atomic_red_team.atomic_tests_for_technique(
                    technique
                )
                for i, atomic_test in enumerate(atomic_tests):
                    platforms = atomic_test.get("supported_platforms", [])
                    if any(only_platform.match(p.lower()) for p in platforms):
                        result += f"  - Atomic Test #{i + 1}: {atomic_test['name']} [{', '.join(platforms)}]\n"

            result += "\n"

        output_path.write_text(result, encoding="utf-8")
        print(f"Generated Atomic Red Team index at {output_path}")

    def generate_index_csv(
        self,
        output_path: Path,
        only_platform: Pattern = re.compile(r".*"),
        attack_platform: Pattern = re.compile(r".*"),
    ) -> None:
        """Generate a CSV index."""
        output = StringIO(newline="")
        writer = csv.writer(output, lineterminator="\n")
        writer.writerow(
            [
                "Tactic",
                "Technique #",
                "Technique Name",
                "Test #",
                "Test Name",
                "Test GUID",
                "Executor Name",
            ]
        )

        techniques_by_tactic = ATTACK_API.techniques_by_tactic(
            only_platform=attack_platform
        )
        for tactic, techniques in techniques_by_tactic.items():
            for technique in techniques:
                tech_id = ATTACK_API.technique_identifier_for_technique(technique)

                # Get atomic YAML to use display_name (which has full technique name for sub-techniques)
                atomic_yaml = self.atomic_red_team._get_atomic_by_id(tech_id)
                if not atomic_yaml:
                    continue

                tech_name = atomic_yaml.get("display_name", technique.get("name", ""))

                atomic_tests = self.atomic_red_team.atomic_tests_for_technique(
                    technique
                )
                for i, atomic_test in enumerate(atomic_tests):
                    platforms = atomic_test.get("supported_platforms", [])
                    if any(only_platform.match(p.lower()) for p in platforms):
                        writer.writerow(
                            [
                                tactic,
                                tech_id,
                                tech_name,
                                i + 1,
                                atomic_test.get("name", ""),
                                atomic_test.get("auto_generated_guid", ""),
                                atomic_test.get("executor", {}).get("name", ""),
                            ]
                        )

        output_path.write_text(output.getvalue(), encoding="utf-8")
        print(f"Generated Atomic Red Team CSV index at {output_path}")

    def generate_yaml_index(self, output_path: Path) -> None:
        """Generate a master YAML index."""
        result: Dict[str, dict] = {}

        techniques_by_tactic = ATTACK_API.techniques_by_tactic()
        for tactic, techniques in techniques_by_tactic.items():
            result[tactic] = {}
            for technique in techniques:
                tech_id = ATTACK_API.technique_identifier_for_technique(technique)

                # Create a copy of the technique and update name with display_name from YAML
                technique_copy = json.loads(json.dumps(technique))  # Deep copy
                atomic_yaml = self.atomic_red_team._get_atomic_by_id(tech_id)
                if atomic_yaml and atomic_yaml.get("display_name"):
                    technique_copy["name"] = atomic_yaml["display_name"]

                result[tactic][tech_id] = {
                    "technique": technique_copy,
                    "atomic_tests": self.atomic_red_team.atomic_tests_for_technique(
                        technique
                    ),
                }

        # Convert through JSON to eliminate YAML aliases (matching Ruby behavior)
        # Use explicit_start=True to add '---' at the beginning like Ruby
        yaml_content = yaml.dump(
            json.loads(json.dumps(result)),
            default_flow_style=False,
            allow_unicode=True,
            sort_keys=False,
            explicit_start=True,
        )
        output_path.write_text(yaml_content, encoding="utf-8")
        print(f"Generated Atomic Red Team YAML index at {output_path}")

    def generate_yaml_index_by_platform(self, output_path: Path, platform: str) -> None:
        """Generate a platform-specific YAML index."""
        result: Dict[str, dict] = {}

        techniques_by_tactic = ATTACK_API.techniques_by_tactic()
        for tactic, techniques in techniques_by_tactic.items():
            result[tactic] = {}
            for technique in techniques:
                tech_id = ATTACK_API.technique_identifier_for_technique(technique)

                # Create a copy of the technique and update name with display_name from YAML
                technique_copy = json.loads(json.dumps(technique))  # Deep copy
                atomic_yaml = self.atomic_red_team._get_atomic_by_id(tech_id)
                if atomic_yaml and atomic_yaml.get("display_name"):
                    technique_copy["name"] = atomic_yaml["display_name"]

                result[tactic][tech_id] = {
                    "technique": technique_copy,
                    "atomic_tests": self.atomic_red_team.atomic_tests_for_technique_by_platform(
                        technique, platform
                    ),
                }

        yaml_content = yaml.dump(
            json.loads(json.dumps(result)),
            default_flow_style=False,
            allow_unicode=True,
            sort_keys=False,
            explicit_start=True,
        )
        output_path.write_text(yaml_content, encoding="utf-8")
        print(f"Generated Atomic Red Team YAML index at {output_path}")

    def _get_layer(self, techniques: List[dict], layer_name: str) -> dict:
        """Create an ATT&CK Navigator layer structure."""
        filters = {}
        if "Windows" in layer_name:
            filters = {"platforms": ["Windows"]}
        elif "macOS" in layer_name:
            filters = {"platforms": ["macOS"]}
        elif "Linux" in layer_name:
            filters = {"platforms": ["Linux"]}

        return {
            "name": layer_name,
            "versions": {"attack": "16", "navigator": "5.1.0", "layer": "4.5"},
            "description": f"{layer_name} MITRE ATT&CK Navigator Layer",
            "domain": "enterprise-attack",
            "filters": filters,
            "gradient": {
                "colors": ["#ffffff", "#ce232e"],
                "minValue": 0,
                "maxValue": 10,
            },
            "legendItems": [
                {"label": "10 or more tests", "color": "#ce232e"},
                {"label": "1 or more tests", "color": "#ffffff"},
            ],
            "techniques": techniques,
        }

    def _update_techniques_list(
        self,
        current_technique: dict,
        current_technique_parent: dict,
        techniques_list: List[dict],
        atomic_yaml: dict,
        comments: bool,
    ) -> None:
        """Update the techniques list with a new technique."""
        tech_id = atomic_yaml.get("attack_technique", "")

        if "." not in tech_id:
            # This is a parent technique
            tech_parent = next(
                (
                    t
                    for t in techniques_list
                    if t["techniqueID"] == tech_id.split(".")[0]
                ),
                None,
            )
            if tech_parent:
                tech_parent["score"] += current_technique["score"]
                if comments:
                    tech_parent["comment"] = current_technique.get("comment", "")
            else:
                if not comments:
                    current_technique.pop("comment", None)
                techniques_list.append(current_technique)
        else:
            # This is a sub-technique
            parent_id = tech_id.split(".")[0]
            tech_parent = next(
                (t for t in techniques_list if t["techniqueID"] == parent_id), None
            )
            if tech_parent:
                tech_parent["score"] += current_technique["score"]
            else:
                current_technique_parent["score"] += current_technique["score"]
                techniques_list.append(current_technique_parent)

            if not comments:
                current_technique.pop("comment", None)
            techniques_list.append(current_technique)

    def generate_navigator_layers(self, output_dir: Path) -> None:
        """Generate all ATT&CK Navigator layers."""
        # Initialize technique lists for each platform
        platforms_data = {
            "all": [],
            "windows": [],
            "macos": [],
            "linux": [],
            "iaas": [],
            "iaas_aws": [],
            "iaas_azure": [],
            "iaas_gcp": [],
            "containers": [],
            "google_workspace": [],
            "azure_ad": [],
            "office_365": [],
            "esxi": [],
        }

        platform_patterns = {
            "windows": re.compile(r"windows", re.I),
            "macos": re.compile(r"macos", re.I),
            "linux": re.compile(r"linux", re.I),
            "iaas": re.compile(r"^iaas", re.I),
            "iaas_aws": re.compile(r"^iaas:aws", re.I),
            "iaas_azure": re.compile(r"^iaas:azure", re.I),
            "iaas_gcp": re.compile(r"^iaas:gcp", re.I),
            "containers": re.compile(r"^containers", re.I),
            "google_workspace": re.compile(r"^google-workspace", re.I),
            "azure_ad": re.compile(r"^azure-ad", re.I),
            "office_365": re.compile(r"^office-365", re.I),
            "esxi": re.compile(r"^esxi", re.I),
        }

        for atomic_yaml in self.atomic_red_team.atomic_tests:
            tech_id = atomic_yaml.get("attack_technique", "")
            base_technique = {
                "techniqueID": tech_id,
                "score": 0,
                "enabled": True,
                "comment": "\n",
                "links": [
                    {
                        "label": "View Atomic",
                        "url": f"https://github.com/redcanaryco/atomic-red-team/blob/master/atomics/{tech_id}/{tech_id}.md",
                    }
                ],
            }

            base_parent = {
                "techniqueID": tech_id.split(".")[0],
                "score": 0,
                "enabled": True,
                "links": [
                    {
                        "label": "View Atomic",
                        "url": f"https://github.com/redcanaryco/atomic-red-team/blob/master/atomics/{tech_id.split('.')[0]}/{tech_id.split('.')[0]}.md",
                    }
                ],
            }

            # Create platform-specific technique copies
            techniques = {
                key: {**base_technique, "comment": "\n"} for key in platforms_data
            }
            technique_parents = {key: {**base_parent} for key in platforms_data}
            has_tests = {key: False for key in platforms_data}

            for atomic in atomic_yaml.get("atomic_tests", []):
                techniques["all"]["score"] += 1
                supported_platforms = atomic.get("supported_platforms", [])

                for platform_key, pattern in platform_patterns.items():
                    if any(pattern.match(p) for p in supported_platforms):
                        has_tests[platform_key] = True
                        techniques[platform_key]["score"] += 1
                        techniques[platform_key]["comment"] += f"- {atomic['name']}\n"

            # Update the all techniques list
            self._update_techniques_list(
                techniques["all"],
                technique_parents["all"],
                platforms_data["all"],
                atomic_yaml,
                False,
            )

            # Update platform-specific lists
            for platform_key in platform_patterns:
                if has_tests[platform_key]:
                    self._update_techniques_list(
                        techniques[platform_key],
                        technique_parents[platform_key],
                        platforms_data[platform_key],
                        atomic_yaml,
                        True,
                    )

        # Write layers
        layer_configs = [
            ("all", "art-navigator-layer.json", "Atomic Red Team"),
            (
                "windows",
                "art-navigator-layer-windows.json",
                "Atomic Red Team (Windows)",
            ),
            ("macos", "art-navigator-layer-macos.json", "Atomic Red Team (macOS)"),
            ("linux", "art-navigator-layer-linux.json", "Atomic Red Team (Linux)"),
            ("iaas", "art-navigator-layer-iaas.json", "Atomic Red Team (Iaas)"),
            (
                "iaas_aws",
                "art-navigator-layer-iaas-aws.json",
                "Atomic Red Team (Iaas:AWS)",
            ),
            (
                "iaas_azure",
                "art-navigator-layer-iaas-azure.json",
                "Atomic Red Team (Iaas:Azure)",
            ),
            (
                "iaas_gcp",
                "art-navigator-layer-iaas-gcp.json",
                "Atomic Red Team (Iaas:GCP)",
            ),
            (
                "containers",
                "art-navigator-layer-containers.json",
                "Atomic Red Team (Containers)",
            ),
            (
                "google_workspace",
                "art-navigator-layer-google-workspace.json",
                "Atomic Red Team (Google-Workspace)",
            ),
            (
                "azure_ad",
                "art-navigator-layer-azure-ad.json",
                "Atomic Red Team (Azure-AD)",
            ),
            (
                "office_365",
                "art-navigator-layer-office-365.json",
                "Atomic Red Team (Office-365)",
            ),
            ("esxi", "art-navigator-layer-esxi.json", "Atomic Red Team (ESXi)"),
        ]

        for platform_key, filename, layer_name in layer_configs:
            layer = self._get_layer(platforms_data[platform_key], layer_name)
            output_path = output_dir / filename
            # Use separators without spaces to match Ruby's compact JSON output
            output_path.write_text(
                json.dumps(layer, separators=(",", ":")), encoding="utf-8"
            )
            print(f"Generated Atomic Red Team ATT&CK Navigator Layer at {output_path}")


def generate_all_docs() -> Tuple[List[str], List[str]]:
    """Generate all Atomic Red Team documentation."""
    return AtomicRedTeamDocs().generate_all_the_docs()
