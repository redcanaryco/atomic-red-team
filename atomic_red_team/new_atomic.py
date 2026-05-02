import re
import shlex
import subprocess
from pathlib import Path

from atomic_red_team.common import atomics_path


DEFAULT_ATOMIC_TEMPLATE = """attack_technique: TODO
display_name: TODO
atomic_tests:
- name: TODO
  auto_generated_guid: TODO
  description: |
    TODO
  supported_platforms:
  - windows
  input_arguments:
    TODO:
      description: TODO
      type: string
      default: TODO
  executor:
    command: |
      TODO
    name: command_prompt
"""


def create_or_append_atomic(
    technique_id: str,
    atomics_dir: str | Path = atomics_path,
) -> Path:
    """Creates a new technique YAML file or appends a blank atomic test."""

    technique_id = technique_id.upper()
    technique_path = Path(atomics_dir) / technique_id / f"{technique_id}.yaml"
    technique_path.parent.mkdir(parents=True, exist_ok=True)

    if technique_path.exists():
        with technique_path.open("a") as file:
            file.write(f"\n{template_technique_atomic_test()}")
    else:
        technique_path.write_text(template_technique_tests(technique_id))

    return technique_path


def open_in_editor(path: Path, editor: str) -> int:
    """Opens a path in the requested editor."""

    return subprocess.call([*shlex.split(editor), str(path)])


def template_technique_tests(technique_id: str | None = None) -> str:
    template = DEFAULT_ATOMIC_TEMPLATE
    if technique_id:
        return template.replace(
            "attack_technique: TODO", f"attack_technique: {technique_id.upper()}"
        )
    return template


def template_technique_atomic_test() -> str:
    match = re.search(r"atomic_tests:\n(.*)", template_technique_tests(), re.DOTALL)
    if not match:
        raise ValueError(
            "atomic test template does not contain an atomic_tests section"
        )
    return match.group(1)
