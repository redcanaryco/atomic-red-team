import os
from os.path import dirname, realpath
from pathlib import Path

import pytest
from pydantic import ValidationError

from atomic_red_team.validator import Validator

test_data_path = f"{dirname(dirname(realpath(__file__)))}/test_data"


@pytest.mark.parametrize("test_input", list(os.scandir(test_data_path)))
def test_all_invalid_scenarios(test_input):
    validator = Validator()
    with pytest.raises(ValidationError) as exc_info:
        validator.validate(test_input)
    error_types = [e["type"] for e in exc_info.value.errors()]

    assert Path(test_input).stem in error_types
