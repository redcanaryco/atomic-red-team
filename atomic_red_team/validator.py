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
    if len(error.errors()) == 1:
        err = error.errors()[0]
        message = ""
        if err["input"] and err["type"] != "unused_input_argument":
            message += f"{err['input']} - "
        return {message + err["msg"]: err.get("loc")}
    inputs = collections.defaultdict(set)
    for e in error.errors():
        # If it's a union type, then it generates multiple errors for the same input arguments.
        # Here we collect only the common paths. For example,
        # [( input_arguments, url_parsing),(input_arguments, string_mismatch)] => (input_arguments)
        if len(inputs[e["input"]]) == 0:
            inputs[e["input"]] = e.get("loc", tuple())
        else:
            inputs[e["input"]] = tuple(
                [x for x in inputs[e["input"]] if x in e.get("loc", tuple())]
            )
    return dict(inputs)


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
