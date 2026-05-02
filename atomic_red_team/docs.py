import csv
import json
import re
from concurrent.futures import ThreadPoolExecutor, as_completed
from functools import lru_cache
from io import StringIO
from pathlib import Path
from typing import Pattern, get_args

import yaml
from jinja2 import Environment, FileSystemLoader
from atomic_red_team.attack_api import Attack, PlatformFilter, _matches_platform
from atomic_red_team.common import atomics_path, base_path
from atomic_red_team.models import Platform, get_language, get_supported_platform


PLATFORMS: list[str] = list(get_args(Platform))


class AtomicRedTeam:
    """Loads Atomic Red Team YAML files and formats technique links."""

    def __init__(
        self, atomics_dir: str | Path = atomics_path, attack_api: Attack | None = None
    ):
        self.atomics_dir = Path(atomics_dir)
        self.attack_api = attack_api or Attack()
        self._atomic_tests: list[dict] | None = None
        self._tests_by_id: dict[str, list[dict]] | None = None

    @property
    def atomic_test_paths(self) -> list[Path]:
        return sorted(self.atomics_dir.glob("T*/T*.yaml"))

    @property
    def atomic_tests(self) -> list[dict]:
        if self._atomic_tests is None:
            self._atomic_tests = []
            for path in self.atomic_test_paths:
                atomic_yaml = yaml.load(path.read_text(), Loader=yaml.CSafeLoader)
                atomic_yaml["atomic_yaml_path"] = str(path)
                self._atomic_tests.append(atomic_yaml)
        return self._atomic_tests

    def atomic_tests_for_technique(
        self, technique_or_identifier: dict | str
    ) -> list[dict]:
        if self._tests_by_id is None:
            self._tests_by_id = {
                atomic["attack_technique"].upper(): atomic.get("atomic_tests", [])
                for atomic in self.atomic_tests
            }
        technique_identifier = self._technique_identifier(technique_or_identifier)
        return self._tests_by_id.get(technique_identifier.upper(), [])

    def atomic_tests_for_technique_by_platform(
        self,
        technique_or_identifier: dict | str,
        platform: str,
    ) -> list[dict]:
        tests = self.atomic_tests_for_technique(technique_or_identifier)
        return [
            test for test in tests if platform in test.get("supported_platforms", [])
        ]

    def github_link_to_technique(
        self,
        technique: dict,
        include_identifier: bool = False,
        only_platform: PlatformFilter = ".*",
    ) -> str:
        technique_identifier = self.attack_api.technique_identifier_for_technique(
            technique
        ).upper()
        link_display = (
            f"{technique_identifier} {technique['name']}"
            if include_identifier
            else technique["name"]
        )
        yaml_file = (
            self.atomics_dir / technique_identifier / f"{technique_identifier}.yaml"
        )
        markdown_file = (
            self.atomics_dir / technique_identifier / f"{technique_identifier}.md"
        )
        if (
            self.atomic_yaml_has_test_for_platform(yaml_file, only_platform)
            and markdown_file.exists()
        ):
            return f"[{link_display}](../../{technique_identifier}/{technique_identifier}.md)"
        return f"{link_display} [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)"

    def atomic_yaml_has_test_for_platform(
        self,
        yaml_file: Path,
        only_platform: PlatformFilter,
    ) -> bool:
        if not yaml_file.exists():
            return False
        atomic_yaml = yaml.load(yaml_file.read_text(), Loader=yaml.CSafeLoader)
        return any(
            _matches_platform(platform, only_platform)
            for atomic in atomic_yaml.get("atomic_tests", [])
            for platform in atomic.get("supported_platforms", [])
        )

    def _technique_identifier(self, technique_or_identifier: dict | str) -> str:
        if isinstance(technique_or_identifier, dict):
            return self.attack_api.technique_identifier_for_technique(
                technique_or_identifier
            )
        return technique_or_identifier


class AtomicRedTeamDocs:
    """Generates Atomic Red Team markdown, CSV, YAML, and Navigator indexes."""

    def __init__(
        self,
        base_dir: str | Path = base_path,
        attack_file: str | Path | None = None,
        atomic_red_team: AtomicRedTeam | None = None,
    ):
        self.base_dir = Path(base_dir)
        self.attack_api = Attack(attack_file)
        self.atomic_red_team = atomic_red_team or AtomicRedTeam(
            self.base_dir / "atomics",
            self.attack_api,
        )

    def generate_all_the_docs(self) -> tuple[list[str], list[str]]:
        # Pre-warm all caches on the main thread before handing off to workers.
        # atomic_tests loads all YAML; _tests_by_id builds the lookup dict;
        # techniques_by_id is used by generate_technique_docs per technique.
        _ = self.atomic_red_team.atomic_tests
        _ = self.attack_api.techniques_by_id

        def _render_one(atomic_yaml: dict) -> tuple[str, str, str]:
            output_path = Path(atomic_yaml["atomic_yaml_path"]).with_suffix(".md")
            try:
                self.generate_technique_docs(atomic_yaml, output_path)
                return ("ok", atomic_yaml["atomic_yaml_path"], str(output_path))
            except Exception as ex:
                return ("fail", atomic_yaml["atomic_yaml_path"], str(ex))

        oks: list[str] = []
        fails: list[str] = []
        with ThreadPoolExecutor() as executor:
            futures = [
                executor.submit(_render_one, ay)
                for ay in self.atomic_red_team.atomic_tests
            ]
            for future in as_completed(futures):
                status, src_path, detail = future.result()
                if status == "ok":
                    print(f"Generating docs for {src_path} => {detail} => OK")
                    oks.append(src_path)
                else:
                    print(f"Generating docs for {src_path} FAIL\n{detail}")
                    fails.append(src_path)
        print()
        print(f"Generated docs for {len(oks)} techniques, {len(fails)} failures")
        self.generate_indexes()
        return oks, fails

    def generate_technique_docs(
        self, atomic_yaml: dict, output_doc_path: str | Path
    ) -> None:
        technique = self.attack_api.technique_info(atomic_yaml["attack_technique"])
        if technique is None:
            raise ValueError(
                f"Unknown ATT&CK technique {atomic_yaml['attack_technique']}"
            )
        technique = {**technique, "identifier": atomic_yaml["attack_technique"].upper()}
        output_doc_path = Path(output_doc_path)
        output_doc_path.write_text(_render_technique_markdown(technique, atomic_yaml))

    def generate_indexes(self) -> None:
        index_dir = self.base_dir / "atomics" / "Indexes"
        for subdir in (
            "Matrices",
            "Indexes-Markdown",
            "Indexes-CSV",
            "Attack-Navigator-Layers",
        ):
            (index_dir / subdir).mkdir(parents=True, exist_ok=True)
        self.generate_attack_matrix("All", index_dir / "Matrices" / "matrix.md")
        for title, platform, filename in _platform_outputs("matrix.md"):
            self.generate_attack_matrix(
                title, index_dir / "Matrices" / filename, platform
            )
        self.generate_index("All", index_dir / "Indexes-Markdown" / "index.md")
        for title, platform, filename in _platform_outputs("index.md"):
            # Use ".*" for attack_platform so STIX v19 platform renames don't break
            # cloud-platform indexes; rely on YAML supported_platforms for filtering.
            self.generate_index(
                title, index_dir / "Indexes-Markdown" / filename, platform
            )
        self.generate_index_csv(index_dir / "Indexes-CSV" / "index.csv")
        for title, platform, filename in _platform_outputs("index.csv"):
            self.generate_index_csv(index_dir / "Indexes-CSV" / filename, platform)
        self.generate_yaml_index(index_dir / "index.yaml")
        for platform in PLATFORMS:
            self.generate_yaml_index_by_platform(
                index_dir / f"{platform.replace(':', '_')}-index.yaml",
                platform,
            )
        self.generate_navigator_layers(index_dir / "Attack-Navigator-Layers")

    def generate_attack_matrix(
        self,
        title_prefix: str,
        output_doc_path: str | Path,
        only_platform: PlatformFilter = ".*",
    ) -> None:
        rows = [f"# {title_prefix} Atomic Tests by ATT&CK Tactic & Technique\n"]
        tactics = self.attack_api.ordered_tactics()
        rows.append(f"| {' | '.join(tactics)} |\n")
        rows.append(f"|{'-----|' * len(tactics)}\n")
        for row_of_techniques in self.attack_api.ordered_tactic_to_technique_matrix(
            only_platform
        ):
            row = [
                self.atomic_red_team.github_link_to_technique(
                    technique, only_platform=only_platform
                )
                if technique
                else ""
                for technique in row_of_techniques
            ]
            rows.append(f"| {' | '.join(row)} |\n")
        Path(output_doc_path).write_text("".join(rows))

    def generate_index(
        self,
        title_prefix: str,
        output_doc_path: str | Path,
        only_platform: PlatformFilter = ".*",
        attack_platform: PlatformFilter = ".*",
    ) -> None:
        rows = [f"# {title_prefix} Atomic Tests by ATT&CK Tactic & Technique\n"]
        by_tactic = self.attack_api.techniques_by_tactic(attack_platform)
        for tactic in self.attack_api.ordered_tactics():
            techniques = sorted(
                by_tactic.get(tactic, []),
                key=lambda t: _technique_sort_key(
                    self.attack_api.technique_identifier_for_technique(t)
                ),
            )
            if not techniques:
                continue
            # For platform-specific indexes exclude techniques with no tests on that platform.
            if only_platform != ".*":
                techniques = [
                    t for t in techniques
                    if any(
                        _matches_platform(platform, only_platform)
                        for test in self.atomic_red_team.atomic_tests_for_technique(t)
                        for platform in test.get("supported_platforms", [])
                    )
                ]
                if not techniques:
                    continue
            rows.append(f"# {tactic}\n")
            for technique in techniques:
                rows.append(
                    f"- {self.atomic_red_team.github_link_to_technique(technique, True, only_platform)}\n"
                )
                tests = self.atomic_red_team.atomic_tests_for_technique(technique)
                for index, atomic_test in enumerate(tests, start=1):
                    platforms = atomic_test.get("supported_platforms", [])
                    if any(
                        _matches_platform(platform, only_platform)
                        for platform in platforms
                    ):
                        rows.append(
                            f"  - Atomic Test #{index}: {atomic_test['name']} [{', '.join(platforms)}]\n"
                        )
            rows.append("\n")
        Path(output_doc_path).write_text("".join(rows))

    def generate_index_csv(
        self,
        output_doc_path: str | Path,
        only_platform: PlatformFilter = ".*",
        attack_platform: PlatformFilter = ".*",
    ) -> None:
        output = StringIO()
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
        by_tactic = self.attack_api.techniques_by_tactic(attack_platform)
        for tactic in self.attack_api.ordered_tactics():
            techniques = sorted(
                by_tactic.get(tactic, []),
                key=lambda t: _technique_sort_key(
                    self.attack_api.technique_identifier_for_technique(t)
                ),
            )
            for technique in techniques:
                tests = self.atomic_red_team.atomic_tests_for_technique(technique)
                for index, atomic_test in enumerate(tests, start=1):
                    if any(
                        _matches_platform(platform, only_platform)
                        for platform in atomic_test.get("supported_platforms", [])
                    ):
                        writer.writerow(
                            [
                                tactic,
                                technique["external_references"][0]["external_id"],
                                technique["name"],
                                index,
                                atomic_test["name"],
                                atomic_test.get("auto_generated_guid", ""),
                                atomic_test["executor"]["name"],
                            ]
                        )
        Path(output_doc_path).write_text(output.getvalue())

    def generate_yaml_index(self, output_doc_path: str | Path) -> None:
        result = self._yaml_index()
        Path(output_doc_path).write_text(
            yaml.dump(
                json.loads(json.dumps(result)),
                Dumper=yaml.CSafeDumper,
                sort_keys=False,
                allow_unicode=True,
            )
        )

    def generate_yaml_index_by_platform(
        self, output_doc_path: str | Path, platform: str
    ) -> None:
        result = self._yaml_index(platform)
        Path(output_doc_path).write_text(
            yaml.dump(
                json.loads(json.dumps(result)),
                Dumper=yaml.CSafeDumper,
                sort_keys=False,
                allow_unicode=True,
            )
        )

    def generate_navigator_layers(self, output_dir: str | Path) -> None:
        output_dir = Path(output_dir)
        layer_specs = [("art-navigator-layer.json", None)]
        layer_specs.extend(
            (f"art-navigator-layer-{platform.replace(':', '-')}.json", platform)
            for platform in PLATFORMS
        )
        for filename, platform in layer_specs:
            layer = _navigator_layer(
                techniques=self._navigator_techniques(platform),
                layer_name=_layer_name(filename),
                platform=platform,
            )
            (output_dir / filename).write_text(
                json.dumps(layer, separators=(",", ":")), encoding="utf-8"
            )

    def _yaml_index(self, platform: str | None = None) -> dict:
        result = {}
        for tactic, techniques in self.attack_api.techniques_by_tactic().items():
            result[tactic] = {}
            for technique in techniques:
                identifier = technique["external_references"][0]["external_id"]
                tests = self.atomic_red_team.atomic_tests_for_technique(technique)
                if platform:
                    tests = [
                        test
                        for test in tests
                        if platform in test.get("supported_platforms", [])
                    ]
                result[tactic][identifier] = {
                    "technique": technique,
                    "atomic_tests": tests,
                }
        return result

    def _navigator_techniques(self, platform: str | None = None) -> list[dict]:
        entries: dict[str, dict] = {}
        parent_scores: dict[str, int] = {}

        for atomic_yaml in self.atomic_red_team.atomic_tests:
            tests = atomic_yaml.get("atomic_tests", [])
            if platform:
                tests = [
                    test
                    for test in tests
                    if platform in test.get("supported_platforms", [])
                ]
            if not tests:
                continue
            technique_id = atomic_yaml["attack_technique"]
            entry: dict = {
                "techniqueID": technique_id,
                "score": len(tests),
                "enabled": True,
            }
            if platform is not None:
                entry["comment"] = "\n" + "".join(
                    f"- {t['name']}\n" for t in tests
                )
            entry["links"] = [{"label": "View Atomic", "url": _atomic_url(technique_id)}]
            entries[technique_id] = entry
            if "." in technique_id:
                parent_id = technique_id.split(".")[0]
                parent_scores[parent_id] = parent_scores.get(parent_id, 0) + len(tests)

        for parent_id, score in parent_scores.items():
            if parent_id in entries:
                entries[parent_id]["score"] += score
            else:
                entries[parent_id] = {
                    "techniqueID": parent_id,
                    "score": score,
                    "enabled": True,
                    "links": [{"label": "View Atomic", "url": _atomic_url(parent_id)}],
                }

        return list(entries.values())


@lru_cache(maxsize=None)
def _get_template():
    environment = Environment(
        autoescape=False,
        keep_trailing_newline=True,
        loader=FileSystemLoader(Path(__file__).parent),
    )
    environment.filters.update(
        {
            "anchor": _anchor,
            "attack_url_identifier": lambda value: str(value).replace(".", "/"),
            "cleanup": _cleanup,
            "language": get_language,
            "platform_list": _platform_list,
        }
    )
    return environment.get_template("atomic_doc_template.md.j2")


def _render_technique_markdown(technique: dict, atomic_yaml: dict) -> str:
    template = _get_template()
    technique = {
        **technique,
        "name": atomic_yaml.get("display_name", technique["name"]),
    }
    return template.render(
        atomic_yaml=atomic_yaml,
        attack_description_lines=_attack_description_lines(technique),
        technique=technique,
    )


def _attack_description_lines(technique: dict) -> list[str]:
    description = technique.get("description", "").replace("%\\<", "%<")
    description = re.sub(
        r"<code>.*?</code>",
        lambda match: match.group(0).replace("~", r"\~"),
        description,
    )
    return description.splitlines()


def _platform_list(platforms: list[str]) -> str:
    return ", ".join(get_supported_platform(platform) for platform in platforms)


def _cleanup(value: object) -> str:
    return str(value or "").strip().replace("\\", "&#92;")


def _anchor(title: str) -> str:
    return re.sub(
        r"[`~!@#$%^&*()+=<>?,./:;\"'|{}\[\]\\–—]", "", title.lower().replace(" ", "-")
    )


_PLATFORM_TITLES: dict[str, str] = {
    "windows": "Windows",
    "macos": "macOS",
    "linux": "Linux",
    "office-365": "Office 365",
    "azure-ad": "Azure AD",
    "google-workspace": "Google Workspace",
    "saas": "SaaS",
    "iaas": "IaaS",
    "containers": "Containers",
    "iaas:gcp": "IaaS:GCP",
    "iaas:azure": "IaaS:Azure",
    "iaas:aws": "IaaS:AWS",
    "esxi": "ESXi",
}

# Platforms whose filename prefix differs from their identifier (e.g. colon is invalid).
_PLATFORM_FILENAME_PREFIX: dict[str, str] = {
    "iaas:gcp": "gcp",
    "iaas:azure": "azure",
    "iaas:aws": "aws",
}


def _platform_outputs(suffix: str) -> list[tuple[str, str, str]]:
    return [
        (
            _PLATFORM_TITLES.get(p, p),
            p,
            f"{_PLATFORM_FILENAME_PREFIX.get(p, p)}-{suffix}",
        )
        for p in PLATFORMS
    ]


def _atomic_url(technique_id: str) -> str:
    return f"https://github.com/redcanaryco/atomic-red-team/blob/master/atomics/{technique_id}/{technique_id}.md"


def _navigator_layer(
    techniques: list[dict], layer_name: str, platform: str | None = None
) -> dict:
    filters: dict = {}
    if platform in ("windows", "macos", "linux"):
        filters = {
            "platforms": [
                platform.replace("macos", "macOS")
                .replace("windows", "Windows")
                .replace("linux", "Linux")
            ]
        }
    return {
        "name": layer_name,
        "versions": {"attack": "19", "navigator": "5.3.0", "layer": "4.5"},
        "description": f"{layer_name} MITRE ATT&CK Navigator Layer",
        "domain": "enterprise-attack",
        "filters": filters,
        "gradient": {"colors": ["#ffffff", "#ce232e"], "minValue": 0, "maxValue": 10},
        "legendItems": [
            {"label": "10 or more tests", "color": "#ce232e"},
            {"label": "1 or more tests", "color": "#ffffff"},
        ],
        "techniques": techniques,
    }


def _technique_sort_key(technique_id: str) -> tuple[int, ...]:
    """Return a sort key that orders T1001 < T1001.001 < T1001.002 < T1002."""
    parts = technique_id.lstrip("Tt").split(".")
    return tuple(int(p) for p in parts)


def _layer_name(filename: str) -> str:
    if filename == "art-navigator-layer.json":
        return "Atomic Red Team"
    platform = filename.removeprefix("art-navigator-layer-").removesuffix(".json")
    names = {
        "windows": "Windows",
        "macos": "macOS",
        "linux": "Linux",
        "iaas": "Iaas",
        "iaas-aws": "Iaas:AWS",
        "iaas-azure": "Iaas:Azure",
        "iaas-gcp": "Iaas:GCP",
        "containers": "Containers",
        "saas": "SaaS",
        "google-workspace": "Google-Workspace",
        "azure-ad": "Azure-AD",
        "office-365": "Office-365",
        "esxi": "ESXi",
    }
    return f"Atomic Red Team ({names.get(platform, platform)})"
