import re
from functools import reduce
from typing import Dict, List, Literal, Optional, Union
from uuid import UUID

from pydantic import (
    AnyUrl,
    BaseModel,
    ConfigDict,
    Field,
    IPvAnyAddress,
    StrictFloat,
    StringConstraints,
    conlist,
    constr,
    field_serializer,
    field_validator,
    model_validator,
)
from pydantic_core import PydanticCustomError
from pydantic_core.core_schema import ValidationInfo
from typing_extensions import Annotated, TypedDict

InputArgType = Literal["url", "string", "float", "integer", "path"]
Platform = Literal[
    "windows",
    "macos",
    "linux",
    "office-365",
    "azure-ad",
    "google-workspace",
    "saas",
    "iaas",
    "containers",
    "iaas:gcp",
    "iaas:azure",
    "iaas:aws",
]
ExecutorType = Literal["manual", "powershell", "sh", "bash", "command_prompt"]
DomainName = Annotated[
    str,
    StringConstraints(
        pattern=r"^(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z0-9][a-z0-9-]{0,61}[a-z0-9]$"
    ),
]

AttackTechniqueID = Annotated[
    str, StringConstraints(pattern=r"T\d{4}(?:\.\d{3})?", min_length=5)
]


def extract_mustached_keys(commands: List[Optional[str]]) -> List[str]:
    result = []
    for command in commands:
        if command:
            matches = re.finditer(r"#{(.*?)}", command, re.MULTILINE)
            keys = [list(i.groups()) for i in matches]
            keys = list(reduce(lambda x, y: x + y, keys, []))
            result.extend(keys)
    return list(set(result))


def get_supported_platform(platform: Platform):
    platforms = {
        "macos": "macOS",
        "office-365": "Office 365",
        "windows": "Windows",
        "linux": "Linux",
        "azure-ad": "Azure AD",
        "iaas": "IaaS",
        "saas": "SaaS",
        "iaas:aws": "AWS",
        "iaas:azure": "Azure",
        "iaas:gcp": "GCP",
        "google-workspace": "Google Workspace",
        "containers": "Containers",
    }
    return platforms[platform]


def get_language(executor: ExecutorType):
    if executor == "command_prompt":
        return "cmd"
    elif executor == "manual":
        return ""
    return executor


class BaseArgument(TypedDict):
    description: str


class UrlArg(BaseArgument):
    default: Optional[DomainName | AnyUrl | IPvAnyAddress]
    type: Literal["url", "Url"]

    @field_serializer("default")
    def serialize_url(self, value):
        return str(value)


class StringArg(BaseArgument):
    default: Optional[str]
    type: Literal["string", "path", "String", "Path"]


class IntArg(BaseArgument):
    default: Optional[int]
    type: Literal["integer", "Integer"]


class FloatArg(BaseArgument):
    default: Optional[StrictFloat]
    type: Literal["float", "Float"]


Argument = Annotated[
    Union[FloatArg, IntArg, UrlArg, StringArg], Field(discriminator="type")
]


class Executor(BaseModel):
    name: ExecutorType
    elevation_required: bool = False


class ManualExecutor(Executor):
    name: Literal["manual"]
    steps: str = Field(..., min_length=10)


class CommandExecutor(Executor):
    name: Literal["powershell", "sh", "bash", "command_prompt"]
    command: constr(min_length=1)
    cleanup_command: Optional[str] = None


class Dependency(BaseModel):
    description: constr(min_length=1)
    prereq_command: constr(min_length=1)
    get_prereq_command: Optional[str]


class Atomic(BaseModel):
    model_config = ConfigDict(
        validate_default=True, extra="forbid", validate_assignment=True
    )

    test_number: Optional[str] = None
    name: constr(min_length=1)
    description: constr(min_length=1)
    supported_platforms: conlist(Platform, min_length=1)
    executor: Union[ManualExecutor, CommandExecutor] = Field(..., discriminator="name")
    dependencies: Optional[List[Dependency]] = []
    input_arguments: Dict[constr(min_length=2, pattern=r"^[\w_-]+$"), Argument] = {}
    dependency_executor_name: ExecutorType = "manual"
    auto_generated_guid: Optional[UUID] = None

    @classmethod
    def extract_mustached_keys(cls, value: dict) -> List[str]:
        commands = []
        executor = value.get("executor")
        if isinstance(executor, CommandExecutor):
            commands = [executor.command, executor.cleanup_command]
        if isinstance(executor, ManualExecutor):
            commands = [executor.steps]
        for d in value.get("dependencies") or []:
            commands.extend([d.get_prereq_command, d.prereq_command])
        return extract_mustached_keys(commands)

    @field_validator("dependency_executor_name", mode="before")  # noqa
    @classmethod
    def validate_dep_executor(cls, v, info: ValidationInfo):
        if v is None:
            raise PydanticCustomError(
                "empty_dependency_executor_name",
                "'dependency_executor_name' shouldn't be empty. Provide a valid value ['manual','powershell', 'sh', "
                "'bash', 'command_prompt'] or remove the key from YAML",
                {"loc": ["dependency_executor_name"], "input": None},
            )
        return v

    @model_validator(mode="after")
    def validate_elevation_required(self):
        if (
            ("linux" in self.supported_platforms or "macos" in self.supported_platforms)
            and not self.executor.elevation_required
            and isinstance(self.executor, CommandExecutor)
        ):
            commands = [self.executor.command]
            if self.executor.cleanup_command:
                commands.append(self.executor.cleanup_command)

            if any(["sudo" in cmd for cmd in commands]):
                raise PydanticCustomError(
                    "elevation_required_but_not_provided",
                    "'elevation_required' shouldn't be empty/false. Since `sudo` is used, set `elevation_required` to true`",
                    {
                        "loc": ["executor", "elevation_required"],
                        "input": self.executor.elevation_required,
                    },
                )
        return self

    @field_validator("input_arguments", mode="before")  # noqa
    @classmethod
    def validate(cls, v, info: ValidationInfo):
        if v is None:
            raise PydanticCustomError(
                "empty_input_arguments",
                "'input_arguments' shouldn't be empty. Provide a valid value or remove the key from YAML",
                {"loc": ["input_arguments"], "input": None},
            )

        atomic = info.data
        keys = cls.extract_mustached_keys(atomic)
        for key, _value in v.items():
            if key not in keys:
                raise PydanticCustomError(
                    "unused_input_argument",
                    f"'{key}' is not used in any of the commands",
                    {"loc": ["input_arguments", key], "input": key},
                )
            else:
                keys.remove(key)

        if len(keys) > 0:
            for x in keys:
                raise PydanticCustomError(
                    "missing_input_argument",
                    f"{x} is not defined in input_arguments",
                    {"loc": ["input_arguments"]},
                )
        return v


class Technique(BaseModel):
    attack_technique: AttackTechniqueID
    display_name: str = Field(..., min_length=5)
    atomic_tests: List[Atomic] = Field(min_length=1)

    def model_post_init(self, __context) -> None:
        for index in range(len(self.atomic_tests)):
            test_number = f"{self.attack_technique}-{index + 1}"
            self.atomic_tests[index].test_number = test_number
