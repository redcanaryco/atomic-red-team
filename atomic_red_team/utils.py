"""
Atomic Red Team module for loading and managing atomic tests.

This module provides the AtomicRedTeam class that manages atomic tests,
generates documentation, and provides various utility functions.

Optimized for speed with caching and efficient data structures.
"""

import glob
import re
from concurrent.futures import ProcessPoolExecutor, as_completed
from functools import lru_cache
from pathlib import Path
from typing import Dict, List, Optional, Pattern, Tuple, Union

import yaml  # PyYAML is faster than ruamel.yaml for loading

try:
    from yaml import CSafeLoader as SafeLoader
except ImportError:
    from yaml import SafeLoader

from jinja2 import Environment, FileSystemLoader

from atomic_red_team.attack_api import ATTACK_API
from atomic_red_team.common import atomics_path

ROOT_GITHUB_URL = "https://github.com/redcanaryco/atomic-red-team"


@lru_cache(maxsize=1)
def _get_jinja_env() -> Environment:
    """Get cached Jinja2 environment with custom filters."""
    template_dir = Path(__file__).parent
    env = Environment(
        loader=FileSystemLoader(template_dir),
        trim_blocks=True,
        lstrip_blocks=True,
        auto_reload=False,  # Disable auto-reload for speed
    )
    # Add custom filters
    env.filters["get_language"] = get_language
    env.filters["cleanup"] = cleanup_for_markdown
    env.filters["slugify"] = slugify
    env.filters["platform_display"] = get_supported_platform_display
    return env


@lru_cache(maxsize=1)
def _get_template():
    """Get cached compiled template."""
    return _get_jinja_env().get_template("atomic_doc_template.md.j2")


def get_language(executor: str) -> str:
    """Convert executor name to language identifier for code blocks."""
    if executor == "command_prompt":
        return "cmd"
    elif executor == "manual":
        return ""
    return executor


def get_supported_platform_display(platform: str) -> str:
    """Convert platform identifier to display name (matches Ruby behavior)."""
    # Ruby just capitalizes the first letter, except for 'macos' -> 'macOS'
    if platform == "macos":
        return "macOS"
    return platform.capitalize()


def cleanup_for_markdown(value) -> str:
    """Clean up a value for use in markdown tables."""
    if value is None:
        return ""
    return str(value).strip().replace("\\", "&#92;")


# Pre-compiled regex for slugify
_SLUGIFY_PATTERN = re.compile(r"[`~!@#$%^&*()+=<>?,.\/:;\"'|{}\[\]\\–—]")


def slugify(title: str) -> str:
    """Convert a title to a URL-friendly slug."""
    slug = title.lower().replace(" ", "-")
    return _SLUGIFY_PATTERN.sub("", slug)


def _load_yaml_file(path: str) -> Optional[dict]:
    """Load a YAML file using fast PyYAML loader."""
    try:
        with open(path, "r", encoding="utf-8") as f:
            return yaml.load(f, Loader=SafeLoader)
    except Exception:
        return None


class AtomicRedTeam:
    """
    Main class for managing Atomic Red Team tests.

    Provides methods for loading atomic tests, generating documentation,
    and validating YAML files. Optimized for speed.
    """

    def __init__(self, atomics_directory: Optional[str] = None):
        """
        Initialize the AtomicRedTeam instance.

        Args:
            atomics_directory: Path to the atomics directory.
                             Defaults to the standard atomics path.
        """
        self.atomics_directory = atomics_directory or atomics_path
        self._atomic_tests: Optional[List[dict]] = None
        self._atomic_tests_by_id: Optional[Dict[str, dict]] = None
        self._only_platform: Pattern = re.compile(r".*")

    @property
    def only_platform(self) -> Pattern:
        """Get the current platform filter pattern."""
        return self._only_platform

    @only_platform.setter
    def only_platform(self, pattern: Pattern):
        """Set the platform filter pattern."""
        self._only_platform = pattern

    @property
    def atomic_test_paths(self) -> List[str]:
        """Returns a list of paths that contain Atomic Tests."""
        pattern = f"{self.atomics_directory}/T*/T*.yaml"
        return sorted(glob.glob(pattern))

    @property
    def atomic_tests(self) -> List[dict]:
        """
        Returns a list of Atomic Tests in Atomic Red Team (as dicts from source YAML).
        """
        if self._atomic_tests is not None:
            return self._atomic_tests

        self._atomic_tests = []
        for path in self.atomic_test_paths:
            atomic_yaml = _load_yaml_file(path)
            if atomic_yaml:
                atomic_yaml["atomic_yaml_path"] = path
                self._atomic_tests.append(atomic_yaml)

        return self._atomic_tests

    def _get_atomic_by_id(self, technique_id: str) -> Optional[dict]:
        """Get atomic test by technique ID using cached index."""
        if self._atomic_tests_by_id is None:
            self._atomic_tests_by_id = {}
            for test in self.atomic_tests:
                tid = test.get("attack_technique", "").upper()
                if tid:
                    self._atomic_tests_by_id[tid] = test
        return self._atomic_tests_by_id.get(technique_id.upper())

    def atomic_tests_for_technique(
        self, technique_or_identifier: Union[str, dict]
    ) -> List[dict]:
        """
        Returns the individual Atomic Tests for a given identifier.

        Args:
            technique_or_identifier: Either a technique ID string (e.g., "T1234")
                                    or an ATT&CK technique object.

        Returns:
            List of atomic test dictionaries.
        """
        if isinstance(technique_or_identifier, dict):
            technique_identifier = ATTACK_API.technique_identifier_for_technique(
                technique_or_identifier
            )
        else:
            technique_identifier = technique_or_identifier

        atomic_yaml = self._get_atomic_by_id(technique_identifier)
        return atomic_yaml.get("atomic_tests", []) if atomic_yaml else []

    def atomic_tests_for_technique_by_platform(
        self, technique_or_identifier: Union[str, dict], platform: str
    ) -> List[dict]:
        """
        Returns the individual Atomic Tests for a given identifier filtered by platform.

        Args:
            technique_or_identifier: Either a technique ID string (e.g., "T1234")
                                    or an ATT&CK technique object.
            platform: Platform to filter by (e.g., "windows", "linux", "macos").

        Returns:
            List of atomic test dictionaries matching the platform.
        """
        tests = self.atomic_tests_for_technique(technique_or_identifier)
        return [t for t in tests if platform in t.get("supported_platforms", [])]

    def atomic_yaml_has_test_for_platform(
        self, yaml_file: str, only_platform: Pattern
    ) -> bool:
        """
        Check if a YAML file has tests for a given platform.

        Args:
            yaml_file: Path to the YAML file.
            only_platform: Regex pattern to match platforms.

        Returns:
            True if the file has tests for the platform.
        """
        yaml_path = Path(yaml_file)
        if not yaml_path.exists():
            return False

        data = _load_yaml_file(str(yaml_path))
        if not data or "atomic_tests" not in data:
            return False

        for atomic in data["atomic_tests"]:
            for platform in atomic.get("supported_platforms", []):
                if only_platform.match(platform.lower()):
                    return True

        return False

    def github_link_to_technique(
        self,
        technique: dict,
        include_identifier: bool = False,
        only_platform: Optional[Pattern] = None,
    ) -> str:
        """
        Returns a Markdown formatted GitHub link to a technique.

        This will be to the edit page for techniques that already have one or more
        Atomic Red Team tests, or the create page for techniques that have no
        existing tests for the given OS.

        Args:
            technique: ATT&CK technique dictionary.
            include_identifier: Whether to include the technique ID in the link text.
            only_platform: Platform pattern filter. Defaults to instance's only_platform.

        Returns:
            Markdown formatted link string.
        """
        if only_platform is None:
            only_platform = self._only_platform

        technique_identifier = ATTACK_API.technique_identifier_for_technique(
            technique
        ).upper()

        # Use display_name from atomic YAML if available (has full name for sub-techniques)
        atomic_yaml = self._get_atomic_by_id(technique_identifier)
        if atomic_yaml:
            technique_name = atomic_yaml.get("display_name", technique.get("name", ""))
        else:
            technique_name = technique.get("name", "")

        link_display = technique_name
        if include_identifier:
            link_display = f"{technique_identifier} {technique_name}"

        yaml_file = f"{self.atomics_directory}/{technique_identifier}/{technique_identifier}.yaml"
        markdown_file = f"{self.atomics_directory}/{technique_identifier}/{technique_identifier}.md"

        if (
            self.atomic_yaml_has_test_for_platform(yaml_file, only_platform)
            and Path(markdown_file).exists()
        ):
            return f"[{link_display}](../../{technique_identifier}/{technique_identifier}.md)"
        else:
            return f"{link_display} [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)"

    def generate_technique_docs(
        self, technique_identifier: str, output_path: Optional[str] = None
    ) -> str:
        """
        Generate Markdown documentation for a technique.

        Args:
            technique_identifier: The technique ID (e.g., "T1059").
            output_path: Optional path to write the output. If None, returns the content.

        Returns:
            The generated Markdown content.
        """
        technique_identifier = technique_identifier.upper()

        # Find the atomic YAML using cached index
        atomic_yaml = self._get_atomic_by_id(technique_identifier)

        if not atomic_yaml:
            raise ValueError(
                f"No atomic tests found for technique {technique_identifier}"
            )

        # Get technique info from ATT&CK for description
        technique_info = ATTACK_API.technique_info(technique_identifier)
        technique = {
            "identifier": technique_identifier,
            "name": atomic_yaml.get("display_name", ""),
            "description": technique_info.get("description", "") if technique_info else "",
        }

        # Render using cached template
        template = _get_template()
        content = template.render(
            technique=technique,
            atomic_yaml=atomic_yaml,
        )
        content = content.rstrip() + "\n"

        if output_path:
            Path(output_path).write_text(content, encoding="utf-8")

        return content

    def generate_all_docs(self, parallel: bool = True) -> Dict[str, str]:
        """
        Generate documentation for all techniques.

        Args:
            parallel: Whether to use parallel processing.

        Returns:
            Dictionary mapping technique IDs to their generated documentation.
        """
        docs = {}
        technique_ids = [
            test.get("attack_technique", "").upper()
            for test in self.atomic_tests
            if test.get("attack_technique")
        ]

        if parallel:
            # Use parallel processing
            # Create a standalone function for ProcessPoolExecutor
            def _generate_doc_worker(args: Tuple[str, str]) -> Tuple[str, str]:
                technique_id, atomics_directory = args
                from atomic_red_team.utils import AtomicRedTeam
                art = AtomicRedTeam(atomics_directory=atomics_directory)
                return (technique_id, art.generate_technique_docs(technique_id))
            
            with ProcessPoolExecutor() as executor:
                future_to_id = {
                    executor.submit(_generate_doc_worker, (tid, self.atomics_directory)): tid
                    for tid in technique_ids
                }
                for future in as_completed(future_to_id):
                    tid = future_to_id[future]
                    try:
                        docs[tid] = future.result()
                    except Exception as e:
                        print(f"Error generating docs for {tid}: {e}")
        else:
            # Sequential processing
            for tid in technique_ids:
                try:
                    docs[tid] = self.generate_technique_docs(tid)
                except Exception as e:
                    print(f"Error generating docs for {tid}: {e}")

        return docs


# Singleton instance for convenience
ATOMIC_RED_TEAM = AtomicRedTeam()
