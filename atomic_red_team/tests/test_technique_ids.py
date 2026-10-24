import pytest
from pydantic import ValidationError

from atomic_red_team.models import Technique


@pytest.fixture
def technique_data():
    return {
        "display_name": "OS Credential Dumping",
        "atomic_tests": [
            {
                "name": "Example test",
                "description": "Example technique for validating IDs",
                "supported_platforms": ["linux"],
                "executor": {"name": "sh", "command": "echo example"},
            }
        ],
    }


@pytest.mark.parametrize("technique_id", ["T1003", "T1003.001"])
def test_valid_technique_id(technique_data, technique_id):
    technique = Technique(attack_technique=technique_id, **technique_data)

    assert technique.attack_technique == technique_id
    assert technique.atomic_tests[0].test_number == f"{technique_id}-1"


@pytest.mark.parametrize(
    "technique_id",
    [
        "prefixT1003",
        "T1003suffix",
        "T10030",
        "T1003.",
        "T1003.0",
        "T1003.00",
        "T1003.0001",
        "T1003.001suffix",
        " T1003",
        "T1003 ",
        "T1003\n",
    ],
)
def test_invalid_technique_id(technique_data, technique_id):
    with pytest.raises(ValidationError) as exc_info:
        Technique(attack_technique=technique_id, **technique_data)

    error = exc_info.value.errors()[0]
    assert error["loc"] == ("attack_technique",)
    assert error["type"] == "string_pattern_mismatch"
