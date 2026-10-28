import copy

import pytest
from pydantic import ValidationError
from typer.testing import CliRunner

from atomic_red_team import runner, validator
from atomic_red_team.models import Technique
from atomic_red_team.validator import format_validation_error


@pytest.fixture
def technique_data():
    return {
        "attack_technique": "T1003",
        "display_name": "OS Credential Dumping",
        "atomic_tests": [{
            "name": "Example test",
            "description": "Example validation fixture",
            "supported_platforms": ["linux"],
            "executor": {"name": "sh", "command": "echo example"},
        }],
    }


def format_errors(data):
    with pytest.raises(ValidationError) as exc_info:
        Technique(**data)
    return format_validation_error(exc_info.value)


@pytest.mark.parametrize("command", [[], {"unexpected": "mapping"}])
def test_multiple_errors_with_unhashable_inputs(technique_data, command):
    atomic = technique_data["atomic_tests"][0]
    atomic["name"] = ""
    atomic["executor"]["command"] = command

    formatted = format_errors(technique_data)

    assert set(map(tuple, formatted.values())) == {
        ("atomic_tests", 0, "name"),
        ("atomic_tests", 0, "executor", "sh", "command"),
    }
    assert any("valid string" in message for message in formatted)


def test_missing_fields_report_their_messages(technique_data):
    atomic = technique_data["atomic_tests"][0]
    del atomic["name"]
    del atomic["description"]

    formatted = format_errors(technique_data)

    assert set(map(tuple, formatted.values())) == {
        ("atomic_tests", 0, "name"),
        ("atomic_tests", 0, "description"),
    }
    assert all("Field required" in message for message in formatted)


def test_identical_invalid_values_keep_separate_field_locations(technique_data):
    atomic = technique_data["atomic_tests"][0]
    atomic["name"] = ""
    atomic["description"] = ""

    formatted = format_errors(technique_data)

    assert set(map(tuple, formatted.values())) == {
        ("atomic_tests", 0, "name"),
        ("atomic_tests", 0, "description"),
    }
    assert all("at least 1 character" in message for message in formatted)


def test_elevation_error_does_not_hide_other_errors(technique_data):
    atomic = technique_data["atomic_tests"][0]
    second = copy.deepcopy(atomic)
    atomic["executor"]["command"] = "sudo echo example"
    second["name"] = ""
    technique_data["atomic_tests"].append(second)

    formatted = format_errors(technique_data)

    assert set(map(tuple, formatted.values())) == {
        ("atomic_tests", 0, "executor", "elevation_required"),
        ("atomic_tests", 1, "name"),
    }


def test_unused_argument_message_is_not_prefixed_with_input(technique_data):
    technique_data["atomic_tests"][0]["input_arguments"] = {
        "unused": {"description": "Unused", "type": "string", "default": "example"}
    }

    formatted = format_errors(technique_data)

    assert list(formatted) == ["'unused' is not used in any of the commands"]


def test_validate_cli_reports_invalid_yaml_without_traceback(monkeypatch, tmp_path):
    atomics = tmp_path / "atomics"
    technique = atomics / "T1003"
    technique.mkdir(parents=True)
    (atomics / "used_guids.txt").write_text("")
    (technique / "T1003.yaml").write_text(
        "attack_technique: T1003\ndisplay_name: OS Credential Dumping\n"
        "atomic_tests:\n- name: ''\n  description: Example test\n"
        "  supported_platforms: [linux]\n"
        "  executor:\n    name: sh\n    command: []\n"
    )
    monkeypatch.setattr(runner, "atomics_path", str(atomics))
    monkeypatch.setattr(validator, "atomics_path", str(atomics))

    result = CliRunner().invoke(runner.app, ["validate"])

    assert result.exit_code == 1
    assert isinstance(result.exception, SystemExit)
    assert "Validation failed" in result.output
    assert "atomic_tests.0.name" in result.output
    assert "atomic_tests.0.executor.sh.command" in result.output
    assert "valid string" in result.output
