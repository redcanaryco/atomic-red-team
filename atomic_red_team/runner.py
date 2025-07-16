import glob
import json
import os
import sys
import urllib.parse
from collections import defaultdict
from functools import partial
from typing import Annotated

import typer
from pydantic import ValidationError

from atomic_red_team.common import used_guids_file, atomics_path
from atomic_red_team.guid import (
    generate_guids_for_yaml,
    get_unique_guid,
)
from atomic_red_team.labels import GithubAPI
from atomic_red_team.models import Technique
from atomic_red_team.validator import Validator, format_validation_error, yaml

app = typer.Typer(help="Atomic Red Team Maintenance tool CLI helper")


@app.command()
def generate_guids():
    """Generates missing GUIDs for the atomic files"""
    with open(used_guids_file, "r") as file:
        used_guids = file.readlines()

    for file in glob.glob(f"{atomics_path}/T*/T*.yaml"):
        generate_guids_for_yaml(file, partial(get_unique_guid, guids=used_guids))


@app.command()
def generate_schemas():
    """Generates JSON and YAML schemas for techniques"""
    schema = Technique.model_json_schema()  # (1)!
    with open("schema.yaml", "w") as f:
        yaml.default_flow_style = False
        yaml.dump(schema, f)
    with open("schema.json", "w") as f:
        f.write(json.dumps(schema, indent=2))


@app.command()
def generate_counter():
    """Generate atomic tests count svg"""
    test_count = 0
    for file in glob.glob(f"{atomics_path}/T*/T*.yaml"):
        with open(file, "r") as f:
            yaml_data = yaml.load(f)
            if yaml_data is not None and "atomic_tests" in yaml_data:
                test_count += len(yaml_data["atomic_tests"])
    # Generate the shields.io badge URL
    params = {"label": "Atomics", "message": str(test_count), "style": "flat"}
    url = "https://img.shields.io/badge/{}-{}-{}.svg".format(
        urllib.parse.quote_plus(params["label"]),
        urllib.parse.quote_plus(params["message"]),
        urllib.parse.quote_plus(params["style"]),
    )

    # Save shields URL in GitHub Output to be used in the next step.
    with open(os.environ["GITHUB_OUTPUT"], "a") as fh:
        print(f"result={url}", file=fh)


@app.command()
def generate_labels(
    pull_request: Annotated[str, typer.Option("--pr")],
    token: Annotated[str, typer.Option("--token")],
):
    """Generate labels for a pull request."""
    api = GithubAPI(token)
    api.save_labels_and_maintainers(pull_request)


@app.command()
def validate():
    """
    Validate all the atomic techniques in a directory.
    """

    validator = Validator()
    errors = defaultdict(list)

    for folder in glob.glob(f"{atomics_path}/T*"):
        for item in os.scandir(folder):
            try:
                validator.validate(item)
            except ValidationError as error:
                errors[item.path].append(error)

    if len(errors) == 0:
        print("Validation successful")
    else:
        print("Validation failed")
        for i, errors in errors.items():
            print(f"Error occurred with {i.replace(f'{atomics_path}/', '')}.")
            print("Each of the following are why it failed:")
            for error in errors:
                if isinstance(error, ValidationError):
                    for k, v in format_validation_error(error).items():
                        print(f"\n\tInvalid {'.'.join(map(str, v))}: {k}\n")
                else:
                    print(f"\n\t{error}\n")
        sys.exit(1)


if __name__ == "__main__":
    app()
