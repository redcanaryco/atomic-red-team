import re
from functools import reduce
from typing import Dict, List, Literal, Optional, Union
from uuid import UUID

from pydantic import (
    AnyUrl,
    IPvAnyAddress,
    BaseModel,
    Field,
    StrictFloat,
    StrictInt,
    conlist,
    constr,
    field_validator,
    field_serializer,
    StringConstraints,
)
from pydantic_core import PydanticCustomError
from pydantic_core.core_schema import FieldValidationInfo
from snakemd import Heading, Code, Raw, Table
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
    default: Optional[StrictInt]
    type: Literal["integer", "Integer"]


class FloatArg(BaseArgument):
    default: Optional[StrictFloat]
    type: Literal["float", "Float"]


Argument = Annotated[
    Union[FloatArg, IntArg, UrlArg, StringArg], Field(discriminator="type")
]

from pydantic import ConfigDict


class Executor(BaseModel):
    name: ExecutorType
    elevation_required: bool = False


class ManualExecutor(Executor):
    name: Literal["manual"]
    steps: str

    @property
    def markdown(self):
        return [Heading("Run it with these steps! ", level=4), self.steps]


class CommandExecutor(Executor):
    name: Literal["powershell", "sh", "bash", "command_prompt"]
    command: constr(min_length=1)
    cleanup_command: Optional[str] = None

    @field_serializer("cleanup_command")
    def serialize_gpc(self, command):
        if command == "":
            return None
        return command

    @property
    def markdown(self):
        attack_exec = f"Attack Commands: Run with `{self.name}`!"
        if self.elevation_required:
            attack_exec += "  Elevation Required (e.g. root or admin) "
        elements = [
            Heading(text=attack_exec, level=4),
            Code(self.command.strip(), lang=get_language(self.name)),
        ]
        if self.cleanup_command:
            elements.extend(
                [
                    Heading(text="Cleanup Commands:", level=4),
                    Code(self.cleanup_command.strip(), lang=get_language(self.name)),
                ]
            )
        return elements


class Dependency(BaseModel):
    description: constr(min_length=1)
    prereq_command: constr(min_length=1)
    get_prereq_command: Optional[str]

    @field_serializer("get_prereq_command")
    def serialize_gpc(self, command):
        if command == "":
            return None
        return command


class Atomic(BaseModel):
    model_config = ConfigDict(validate_default=True)

    test_number: Optional[str] = None
    name: constr(min_length=1)
    description: constr(min_length=1)
    supported_platforms: conlist(Platform, min_length=1)
    executor: Union[ManualExecutor, CommandExecutor] = Field(..., discriminator="name")
    dependencies: Optional[List[Dependency]] = []
    input_arguments: Optional[Dict[str, Argument]] = {}
    dependency_executor_name: Optional[ExecutorType] = None
    auto_generated_guid: Optional[UUID] = None

    @classmethod
    def extract_mustached_keys(cls, value: dict) -> List[str]:
        commands = []
        executor = value.get("executor")
        if isinstance(executor, CommandExecutor):
            commands = [executor.command, executor.cleanup_command]
        if isinstance(executor, ManualExecutor):
            commands = [executor.steps]
        for d in value.get("dependencies", []):
            commands.extend([d.get_prereq_command, d.prereq_command])
        return extract_mustached_keys(commands)

    @field_validator("input_arguments", mode="before")  # noqa
    @classmethod
    def validate(cls, v, info: FieldValidationInfo):
        atomic = info.data
        keys = cls.extract_mustached_keys(atomic)
        for key, _value in v.items():
            if key not in keys:
                raise PydanticCustomError(
                    "unused_input_argument",
                    f"'{key}' is not used in any of the commands",
                    {"loc": ["input_arguments", key]},
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

    @property
    def markdown(self) -> List[Raw | Heading]:
        supported_platforms = ",".join(
            [get_supported_platform(i) for i in self.supported_platforms]
        )
        elements = [
            Raw(self.description.strip()),
            Raw(f"**Supported Platforms:** {supported_platforms}"),
            Raw(f"**auto_generated_guid:** {self.auto_generated_guid}"),
        ]
        if len(self.input_arguments) > 0:
            elements.append(Heading("Inputs:", 4))
            input_args = []
            for key, value in self.input_arguments.items():
                input_args.append(
                    [key, value["description"], value["type"], value["default"]]
                )
            elements.append(Raw("\n"))
            elements.append(
                Table(
                    header=["Name", "Description", "Type", "Default Value"],
                    body=input_args,
                )
            )
        elements.extend(self.executor.markdown)
        if len(self.dependencies) > 0:
            if self.dependency_executor_name:
                dependency_executor = self.dependency_executor_name
            else:
                dependency_executor = self.executor.name
            elements.append(
                Heading(f"Dependencies:  Run with `{dependency_executor}`!", level=4)
            )
            for dependency in self.dependencies:
                elements.append(
                    Heading(text=f"Description: {dependency.description}", level=5)
                )
                if dependency.prereq_command:
                    elements.extend(
                        [
                            Heading("Check Prereq Commands:", level=5),
                            Code(
                                dependency.prereq_command.strip(),
                                lang=get_language(dependency_executor),
                            ),
                        ]
                    )
                if dependency.get_prereq_command:
                    elements.extend(
                        [
                            Heading("Get Prereq Commands:", level=5),
                            Code(
                                dependency.get_prereq_command.strip(),
                                lang=get_language(dependency_executor),
                            ),
                        ]
                    )
        elements.append(Raw("<br/>\n<br/>"))
        return elements
