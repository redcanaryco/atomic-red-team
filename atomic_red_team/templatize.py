import glob
import os
import pathlib
import sys

from ruamel.yaml import YAML
from snakemd import Document

from models import Technique

yaml = YAML(typ="safe")


def cleanup(input):
    return str(input).strip().replace("\\", "&#92;")


def get_language(executor):
    if executor == "command_prompt":
        return "cmd"
    elif executor == "manual":
        return ""
    return executor


for file in glob.glob(f'{os.getcwd()}/atomics/**/T*.yaml'):
    path = pathlib.PurePath(file)
    directory = os.path.dirname(file)
    with open(file, "r") as f:
        atomic = yaml.load(f)
        try:
            technique = Technique(**atomic)
            doc = Document(elements=technique.markdown)
            doc.dump(f"{technique.attack_technique}", directory=f"atomics/{technique.attack_technique}")
        except Exception as e:
            print(f"Error with {file}: {str(e)}")
            sys.exit(1)
