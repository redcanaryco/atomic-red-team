import glob
import sys
from os.path import abspath, dirname

from ruamel.yaml import YAML
from snakemd import Document

from atomic_red_team.models.technique import Technique

yaml = YAML(typ="safe")


def cleanup(input):
    return str(input).strip().replace("\\", "&#92;")


def get_language(executor):
    if executor == "command_prompt":
        return "cmd"
    elif executor == "manual":
        return ""
    return executor


def generate_markdown():
    root_dir = dirname(dirname(abspath(__file__)))
    for file in glob.glob(f"{root_dir}/atomics/**/T*.yaml"):
        with open(file, "r") as f:
            atomic = yaml.load(f)
            try:
                technique = Technique(**atomic)
                doc = Document(elements=technique.markdown)
                doc.dump(
                    f"{technique.attack_technique}",
                    directory=f"atomics/{technique.attack_technique}",
                )
            except Exception as e:
                print(f"Error with {file}: {str(e)}")
                sys.exit(1)


if __name__ == "__main__":
    generate_markdown()
