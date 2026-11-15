import collections
import fnmatch
from os import DirEntry

from pydantic import ValidationError
from pydantic_core import InitErrorDetails, PydanticCustomError
from ruamel.yaml import YAML

from atomic_red_team.common import atomics_path
from atomic_red_team.models import Technique

yaml = YAML(typ="safe")


def format_validation_error(error: ValidationError):
    entries = []
    for err in error.errors():
        location = tuple(err.get("loc", ()))
        message = ""
        if err["type"] == "elevation_required_but_not_provided":
            location += tuple(err.get("ctx", {}).get("loc", ()))
        elif err.get("input") is not None and err["type"] != "unused_input_argument":
            message += f"{err['input']} - "
        entries.append((message + err["msg"], location))

    # Identical invalid values can occur at different fields. Keep each location
    # instead of grouping by input, which can also be an unhashable list or dict.
    counts = collections.Counter(message for message, _ in entries)
    formatted = {}
    for message, location in entries:
        if counts[message] > 1:
            message += f" ({'.'.join(map(str, location))})"
        formatted[message] = location
    return formatted


class Validator:
    def __init__(self):
        used_guids_path = f"{atomics_path}/used_guids.txt"
        with open(used_guids_path, "r") as f:
            self.used_guids = [x.strip() for x in f.readlines()]
        self.guids = []

    def validate(self, obj: DirEntry):
        if obj.is_file():
            if fnmatch.fnmatch(obj.name, "*.y*ml"):
                self.validate_file(obj)
        if obj.is_dir():
            self.validate_directory(obj)

    def validate_file(self, file: DirEntry):
        """Performs file validation"""
        self.validate_yaml_extension(file)
        self.validate_atomic(file)

    def validate_atomic(self, file: DirEntry):
        """Validates whether the defined input args are used."""
        with open(file.path, "r") as f:
            atomic = yaml.load(f)
            technique = Technique(**atomic)
            for index, t in enumerate(technique.atomic_tests):
                if t.auto_generated_guid:
                    if t.auto_generated_guid not in self.guids:
                        self.guids.append(t.auto_generated_guid)
                    else:
                        raise ValidationError.from_exception_data(
                            "ValueError",
                            [
                                InitErrorDetails(
                                    type=PydanticCustomError(
                                        "reused_guid",
                                        f"GUID {t.auto_generated_guid} reused for test {t.name}. GUIDs are auto generated. You can remove atomic_tests[{index}].auto_generated_guid",
                                    ),
                                    loc=("atomic_tests", index, "auto_generated_guid"),
                                    input=t.auto_generated_guid,
                                )
                            ],
                        )

    def validate_yaml_extension(self, file: DirEntry):
        """Validates the yaml extension"""
        if fnmatch.fnmatch(file.path, "*.yml"):
            raise ValidationError.from_exception_data(
                "ValueError",
                [
                    InitErrorDetails(
                        type=PydanticCustomError(
                            "invalid_filename",
                            "Rename file from .yml to .yaml",
                        ),
                        loc=["filename"],
                    )
                ],
            )

    def validate_directory(self, directory: DirEntry):
        """Performs directory validation"""
        self.validate_directory_path(directory)

    def validate_directory_path(self, directory: DirEntry):
        """Validated whether the directory is allowed directory name (`src` or `bin`)"""
        if directory.name not in ["src", "bin"]:
            raise ValidationError.from_exception_data(
                "ValueError",
                [
                    InitErrorDetails(
                        type=PydanticCustomError(
                            "invalid_directory",
                            "Invalid path. `src` and `bin` are the only two directories supported.",
                        ),
                        loc=["directory"],
                    )
                ],
            )
