import glob
import json
import os
import sys
import urllib.parse
from collections import defaultdict
from functools import partial
from pathlib import Path
from typing import Annotated, Optional

import typer
from pydantic import ValidationError

from atomic_red_team.common import atomics_path, used_guids_file
from atomic_red_team.guid import (
    generate_guids_for_yaml,
    get_unique_guid,
)
from atomic_red_team.labels import GithubAPI
from atomic_red_team.models import Technique
from atomic_red_team.utils import ATOMIC_RED_TEAM
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


@app.command()
def generate_docs(
    technique_id: Annotated[
        Optional[str],
        typer.Option(
            "--technique", "-t", help="Specific technique ID to generate docs for"
        ),
    ] = None,
    output_dir: Annotated[
        Optional[str],
        typer.Option("--output", "-o", help="Output directory for documentation"),
    ] = None,
    full: Annotated[
        bool,
        typer.Option("--full", "-f", help="Generate all docs including indexes, matrices, and navigator layers"),
    ] = False,
):
    """Generate Markdown documentation for atomic tests.

    Use --full to generate all documentation including:
    - Individual technique markdown files
    - ATT&CK matrices (markdown)
    - Platform-specific indexes (markdown, CSV, YAML)
    - ATT&CK Navigator layers (JSON)
    """
    if full:
        # Generate all documentation including indexes
        from atomic_red_team.doc_generator import generate_all_docs

        oks, fails = generate_all_docs()
        if fails:
            sys.exit(len(fails))
        return

    if output_dir is None:
        output_dir = atomics_path

    if technique_id:
        # Generate docs for a specific technique
        technique_id = technique_id.upper()
        output_path = Path(output_dir) / technique_id / f"{technique_id}.md"
        try:
            ATOMIC_RED_TEAM.generate_technique_docs(technique_id, str(output_path))
            print(f"Generated documentation for {technique_id} at {output_path}")
        except ValueError as e:
            print(f"Error: {e}")
            sys.exit(1)
    else:
        # Generate docs for all techniques
        count = 0
        for atomic_yaml in ATOMIC_RED_TEAM.atomic_tests:
            tech_id = atomic_yaml.get("attack_technique", "").upper()
            if tech_id:
                output_path = Path(output_dir) / tech_id / f"{tech_id}.md"
                try:
                    ATOMIC_RED_TEAM.generate_technique_docs(tech_id, str(output_path))
                    count += 1
                except Exception as e:
                    print(f"Error generating docs for {tech_id}: {e}")
        print(f"Generated documentation for {count} techniques")


if __name__ == "__main__":
    app()
