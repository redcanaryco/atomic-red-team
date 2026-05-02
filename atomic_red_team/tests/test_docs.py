import json

import yaml
from mitreattack import navlayers

from atomic_red_team.docs import AtomicRedTeam, AtomicRedTeamDocs


def test_generate_technique_docs_writes_markdown(tmp_path):
    atomics_dir = tmp_path / "atomics"
    technique_dir = atomics_dir / "T1001"
    technique_dir.mkdir(parents=True)
    atomic_yaml_path = technique_dir / "T1001.yaml"
    atomic_yaml_path.write_text(
        yaml.safe_dump(
            {
                "attack_technique": "T1001",
                "display_name": "Data Obfuscation",
                "atomic_tests": [
                    {
                        "name": "Run command",
                        "description": "Runs a command.",
                        "supported_platforms": ["windows"],
                        "auto_generated_guid": "11111111-1111-4111-8111-111111111111",
                        "input_arguments": {
                            "path": {
                                "description": "File path",
                                "type": "path",
                                "default": "C:\\Temp\\file.txt",
                            }
                        },
                        "executor": {
                            "name": "command_prompt",
                            "command": "type #{path}",
                            "cleanup_command": "del #{path}",
                        },
                    }
                ],
            }
        )
    )
    attack_file = tmp_path / "enterprise-attack.json"
    attack_file.write_text(
        json.dumps(
            {
                "type": "bundle",
                "id": "bundle--11111111-1111-4111-8111-111111111111",
                "spec_version": "2.0",
                "objects": [
                    {
                        "type": "attack-pattern",
                        "id": "attack-pattern--11111111-1111-4111-8111-111111111111",
                        "created": "2024-01-01T00:00:00.000Z",
                        "modified": "2024-01-01T00:00:00.000Z",
                        "name": "Data Obfuscation",
                        "description": "Technique description.",
                        "external_references": [
                            {"source_name": "mitre-attack", "external_id": "T1001"}
                        ],
                        "x_mitre_platforms": ["Windows"],
                        "kill_chain_phases": [
                            {
                                "kill_chain_name": "mitre-attack",
                                "phase_name": "command-and-control",
                            }
                        ],
                    }
                ],
            }
        )
    )
    output_path = technique_dir / "T1001.md"
    atomic_red_team = AtomicRedTeam(atomics_dir=atomics_dir)
    docs = AtomicRedTeamDocs(attack_file=attack_file, atomic_red_team=atomic_red_team)

    docs.generate_technique_docs(
        atomic_red_team.atomic_tests[0],
        output_path,
    )

    output = output_path.read_text()
    assert "# T1001 - Data Obfuscation" in output
    assert "[Atomic Test #1: Run command](#atomic-test-1-run-command)" in output
    assert "| path | File path | path | C:&#92;Temp&#92;file.txt|" in output
    assert "```cmd\ntype #{path}\n```" in output
    assert "```cmd\ndel #{path}\n```" in output


def test_generate_technique_docs_separates_markdown_blocks(tmp_path):
    atomics_dir = tmp_path / "atomics"
    technique_dir = atomics_dir / "T1001"
    technique_dir.mkdir(parents=True)
    atomic_yaml_path = technique_dir / "T1001.yaml"
    atomic_yaml_path.write_text(
        yaml.safe_dump(
            {
                "attack_technique": "T1001",
                "display_name": "Data Obfuscation",
                "atomic_tests": [
                    {
                        "name": "First command",
                        "description": "Runs a command.",
                        "supported_platforms": ["windows"],
                        "auto_generated_guid": "11111111-1111-4111-8111-111111111111",
                        "input_arguments": {
                            "path": {
                                "description": "File path",
                                "type": "path",
                                "default": "C:\\Temp",
                            }
                        },
                        "executor": {
                            "name": "command_prompt",
                            "command": "type #{path}",
                            "cleanup_command": "del #{path}",
                        },
                        "dependencies": [
                            {
                                "description": "Target must exist",
                                "prereq_command": "if exist #{path} (exit /b 0)",
                                "get_prereq_command": "mkdir #{path}",
                            }
                        ],
                    },
                    {
                        "name": "Second command",
                        "description": "Runs another command.",
                        "supported_platforms": ["windows"],
                        "auto_generated_guid": "22222222-2222-4222-8222-222222222222",
                        "executor": {"name": "command_prompt", "command": "dir"},
                    },
                ],
            }
        )
    )
    attack_file = tmp_path / "enterprise-attack.json"
    attack_file.write_text(
        json.dumps(
            {
                "type": "bundle",
                "id": "bundle--11111111-1111-4111-8111-111111111111",
                "spec_version": "2.0",
                "objects": [
                    {
                        "type": "attack-pattern",
                        "id": "attack-pattern--11111111-1111-4111-8111-111111111111",
                        "created": "2024-01-01T00:00:00.000Z",
                        "modified": "2024-01-01T00:00:00.000Z",
                        "name": "Data Obfuscation",
                        "description": "Technique description.",
                        "external_references": [
                            {"source_name": "mitre-attack", "external_id": "T1001"}
                        ],
                        "x_mitre_platforms": ["Windows"],
                        "kill_chain_phases": [
                            {
                                "kill_chain_name": "mitre-attack",
                                "phase_name": "command-and-control",
                            }
                        ],
                    }
                ],
            }
        )
    )
    output_path = technique_dir / "T1001.md"
    atomic_red_team = AtomicRedTeam(atomics_dir=atomics_dir)
    docs = AtomicRedTeamDocs(attack_file=attack_file, atomic_red_team=atomic_red_team)

    docs.generate_technique_docs(atomic_red_team.atomic_tests[0], output_path)

    output = output_path.read_text()
    assert (
        output
        == """# T1001 - Data Obfuscation

## Description from ATT&CK

> Technique description.

[Source](https://attack.mitre.org/techniques/T1001)

## Atomic Tests

- [Atomic Test #1: First command](#atomic-test-1-first-command)
- [Atomic Test #2: Second command](#atomic-test-2-second-command)

### Atomic Test #1: First command

Runs a command.

**Supported Platforms:** Windows

**auto_generated_guid:** `11111111-1111-4111-8111-111111111111`

#### Inputs

| Name | Description | Type | Default Value |
|------|-------------|------|---------------|
| path | File path | path | C:&#92;Temp|

#### Attack Commands: Run with `command_prompt`!

```cmd
type #{path}
```

#### Cleanup Commands

```cmd
del #{path}
```

#### Dependencies: Run with `command_prompt`!

##### Description: Target must exist

###### Check Prereq Commands

```cmd
if exist #{path} (exit /b 0)
```

###### Get Prereq Commands

```cmd
mkdir #{path}
```

### Atomic Test #2: Second command

Runs another command.

**Supported Platforms:** Windows

**auto_generated_guid:** `22222222-2222-4222-8222-222222222222`

#### Attack Commands: Run with `command_prompt`!

```cmd
dir
```
"""
    )


def test_github_link_prompts_for_contribution_when_platform_missing(tmp_path):
    atomics_dir = tmp_path / "atomics"
    technique_dir = atomics_dir / "T1001"
    technique_dir.mkdir(parents=True)
    (technique_dir / "T1001.yaml").write_text(
        yaml.safe_dump(
            {
                "attack_technique": "T1001",
                "display_name": "Data Obfuscation",
                "atomic_tests": [
                    {
                        "name": "Run command",
                        "description": "Runs a command.",
                        "supported_platforms": ["windows"],
                        "executor": {"name": "command_prompt", "command": "dir"},
                    }
                ],
            }
        )
    )
    atomic_red_team = AtomicRedTeam(atomics_dir=atomics_dir)
    technique = {
        "name": "Data Obfuscation",
        "external_references": [
            {"source_name": "mitre-attack", "external_id": "T1001"}
        ],
    }

    link = atomic_red_team.github_link_to_technique(
        technique,
        include_identifier=True,
        only_platform="linux",
    )

    assert link == (
        "T1001 Data Obfuscation "
        "[CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)"
    )


def test_generate_navigator_layers_writes_mitreattack_layer(tmp_path):
    atomics_dir = tmp_path / "atomics"
    technique_dir = atomics_dir / "T1001"
    technique_dir.mkdir(parents=True)
    (technique_dir / "T1001.yaml").write_text(
        yaml.safe_dump(
            {
                "attack_technique": "T1001",
                "display_name": "Data Obfuscation",
                "atomic_tests": [
                    {
                        "name": "Windows command",
                        "description": "Runs a command.",
                        "supported_platforms": ["windows"],
                        "executor": {"name": "command_prompt", "command": "dir"},
                    },
                    {
                        "name": "Linux command",
                        "description": "Runs a command.",
                        "supported_platforms": ["linux"],
                        "executor": {"name": "sh", "command": "ls"},
                    },
                ],
            }
        )
    )
    output_dir = tmp_path / "layers"
    output_dir.mkdir()
    docs = AtomicRedTeamDocs(
        base_dir=tmp_path,
        attack_file=tmp_path / "enterprise-attack.json",
        atomic_red_team=AtomicRedTeam(atomics_dir=atomics_dir),
    )

    docs.generate_navigator_layers(output_dir)

    layer = navlayers.Layer()
    layer.from_file(str(output_dir / "art-navigator-layer-windows.json"))
    technique = layer.layer.techniques[0]
    assert layer.layer.name == "Atomic Red Team (Windows)"
    assert layer.layer.versions.attack == "19"
    assert layer.layer.filters.platforms == ["Windows"]
    assert technique.techniqueID == "T1001"
    assert technique.score == 1
    assert technique.comment == "\n- Windows command\n"


def test_generate_all_the_docs_prints_generated_file_paths(
    tmp_path, capsys, monkeypatch
):
    atomics_dir = tmp_path / "atomics"
    technique_dir = atomics_dir / "T1001"
    technique_dir.mkdir(parents=True)
    atomic_yaml_path = technique_dir / "T1001.yaml"
    atomic_yaml_path.write_text(
        yaml.safe_dump(
            {
                "attack_technique": "T1001",
                "display_name": "Data Obfuscation",
                "atomic_tests": [
                    {
                        "name": "Run command",
                        "description": "Runs a command.",
                        "supported_platforms": ["windows"],
                        "executor": {"name": "command_prompt", "command": "dir"},
                    }
                ],
            }
        )
    )
    attack_file = tmp_path / "enterprise-attack.json"
    attack_file.write_text(
        json.dumps(
            {
                "type": "bundle",
                "id": "bundle--11111111-1111-4111-8111-111111111111",
                "spec_version": "2.0",
                "objects": [
                    {
                        "type": "attack-pattern",
                        "id": "attack-pattern--11111111-1111-4111-8111-111111111111",
                        "created": "2024-01-01T00:00:00.000Z",
                        "modified": "2024-01-01T00:00:00.000Z",
                        "name": "Data Obfuscation",
                        "description": "Technique description.",
                        "external_references": [
                            {"source_name": "mitre-attack", "external_id": "T1001"}
                        ],
                        "x_mitre_platforms": ["Windows"],
                        "kill_chain_phases": [
                            {
                                "kill_chain_name": "mitre-attack",
                                "phase_name": "command-and-control",
                            }
                        ],
                    }
                ],
            }
        )
    )
    indexes_dir = atomics_dir / "Indexes"
    for path in [
        indexes_dir / "Matrices",
        indexes_dir / "Indexes-Markdown",
        indexes_dir / "Indexes-CSV",
        indexes_dir / "Attack-Navigator-Layers",
    ]:
        path.mkdir(parents=True)
    docs = AtomicRedTeamDocs(
        base_dir=tmp_path,
        attack_file=attack_file,
        atomic_red_team=AtomicRedTeam(atomics_dir=atomics_dir),
    )
    monkeypatch.setattr(docs, "generate_indexes", lambda: None)

    docs.generate_all_the_docs()

    output = capsys.readouterr().out
    expected_markdown_path = technique_dir / "T1001.md"
    assert f"Generating docs for {atomic_yaml_path}" in output
    assert f"=> {expected_markdown_path} => OK" in output
    assert f"Generated docs for 1 techniques, 0 failures" in output


def test_generate_yaml_index_serializes_mitreattack_stix_dates(tmp_path):
    atomics_dir = tmp_path / "atomics"
    technique_dir = atomics_dir / "T1001"
    technique_dir.mkdir(parents=True)
    (technique_dir / "T1001.yaml").write_text(
        yaml.safe_dump(
            {
                "attack_technique": "T1001",
                "display_name": "Data Obfuscation",
                "atomic_tests": [
                    {
                        "name": "Run command",
                        "description": "Runs a command.",
                        "supported_platforms": ["windows"],
                        "executor": {"name": "command_prompt", "command": "dir"},
                    }
                ],
            }
        )
    )
    attack_file = tmp_path / "enterprise-attack.json"
    attack_file.write_text(
        json.dumps(
            {
                "type": "bundle",
                "id": "bundle--11111111-1111-4111-8111-111111111111",
                "spec_version": "2.0",
                "objects": [
                    {
                        "type": "attack-pattern",
                        "id": "attack-pattern--11111111-1111-4111-8111-111111111111",
                        "created": "2024-01-01T00:00:00.000Z",
                        "modified": "2024-01-01T00:00:00.000Z",
                        "name": "Data Obfuscation",
                        "description": "Technique description.",
                        "external_references": [
                            {"source_name": "mitre-attack", "external_id": "T1001"}
                        ],
                        "x_mitre_platforms": ["Windows"],
                        "kill_chain_phases": [
                            {
                                "kill_chain_name": "mitre-attack",
                                "phase_name": "command-and-control",
                            }
                        ],
                    }
                ],
            }
        )
    )
    output_path = tmp_path / "index.yaml"
    docs = AtomicRedTeamDocs(
        base_dir=tmp_path,
        attack_file=attack_file,
        atomic_red_team=AtomicRedTeam(atomics_dir=atomics_dir),
    )

    docs.generate_yaml_index(output_path)

    output = yaml.safe_load(output_path.read_text())
    assert output["command-and-control"]["T1001"]["technique"]["created"] == (
        "2024-01-01T00:00:00.000Z"
    )
