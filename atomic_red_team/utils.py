import itertools
from typing import Any, List

from ruamel.yaml import YAML

from .models.technique import Technique

yaml = YAML(typ="safe")


def flatten(list_of_lists: List[List[Any]]):
    return list(itertools.chain(*list_of_lists))


def get_technique_from_file(file: str) -> Technique:
    with open(file, "r") as f:
        atomic = yaml.load(f)
        technique = Technique(**atomic)
        return technique
