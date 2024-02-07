import glob
import os
import pathlib

import snakemd
from mdutils.mdutils import MdUtils
from ruamel.yaml import YAML
from snakemd import Document

# lift = attack_client()
# all_techniques = lift.get_techniques()


# def get_technique_description(technique_id: str):
#     return list(filter(lambda x: x["external_references"][0]["external_id"] == technique_id, all_techniques))[0][
#         "description"]


yaml = YAML(typ="safe")


def cleanup(input):
    return str(input).strip().replace("\\", "&#92;")


def get_supported_platform(platform: str):
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
        "containers": "Containers"
    }
    return platforms[platform]


def get_language(executor):
    if executor == "command_prompt":
        return "cmd"
    elif executor == "manual":
        return ""
    return executor


def convert_to_readme(file_name, technique):
    doc = Document()
    identifier = technique['attack_technique'].upper()
    doc.add_heading(f"{identifier} - {technique['display_name']}")
    doc.add_heading(f"[Description from ATT&CK](https://attack.mitre.org/techniques/{identifier.replace('.', '/')})", 2)
    # mdFile.new_line(f"""<blockquote>{technique['description']}</blockquote>""")
    doc.add_heading("Atomic Tests", 2)
    items = [f"Atomic Test #{index + 1} - {test['name']}" for index, test in enumerate(technique["atomic_tests"])]
    items = [f"[{item}](#{item.lower().replace(' ', '-').replace('#', '')})" for item in items]
    doc.add_unordered_list(items)
    doc.add_raw("<br/>")

    for index, test in enumerate(technique["atomic_tests"]):
        doc.add_heading(f"Atomic Test #{index + 1} - {test['name']}".strip(), 2)
        doc.add_raw(test["description"].strip())
        supported_platforms = ",".join([get_supported_platform(i) for i in test['supported_platforms']])
        doc.add_raw(f"**Supported Platforms:** {supported_platforms}")
        doc.add_raw(f"**auto_generated_guid:** {test['auto_generated_guid']}")
        if len(test.get("input_arguments", {})) > 0:
            doc.add_heading("Inputs:", 4)
            header = ["Name", "Description", "Type", "Default Value"]
            input_args = []
            for key, value in test['input_arguments'].items():
                input_args.append([key, value["description"], value["type"], value["default"]])
            doc.add_raw("\n")
            doc.add_table(header, input_args)
            doc.add_raw("\n")
        if test['executor']['name'] == "manual":
            pass
        else:
            attack_exec = f"Attack Commands: Run with `{test['executor']['name']}`!"
            if test['executor'].get("elevation_required", False):
                attack_exec += "  Elevation Required (e.g. root or admin) "
            doc.add_heading(attack_exec, 4)
            doc.add_code(test['executor']['command'].strip(), lang=get_language(test['executor']['name']))
            doc.add_raw("\n")
            if test['executor'].get('cleanup_command'):
                doc.add_heading("Cleanup Commands:", 4)
                doc.add_code(test['executor']['cleanup_command'].strip(), lang=get_language(test['executor']['name']))
        doc.add_raw("<br/>\n<br/>")
    # # mdFile.block_quote(cleanup(technique['description']).replace("%<", "%\\<"))
    #
    # for test_number, test in enumerate(technique['atomic_tests']):
    #     title = f"Atomic Test #{test_number + 1} - {test['name']}"
    #     mdFile.new_line(f"- [{title}](#{title.lower()})")
    #
    #     for test_number, test in enumerate(technique['atomic_tests']):
    #         mdFile.new_line('\n')
    #         mdFile.new_line(f"## Atomic Test #{test_number + 1} - {test['name']}")
    #     mdFile.new_line(cleanup(test['description']))
    #
    #     mdFile.new_line(
    #         f"\n**Supported Platforms:** {', '.join([p.capitalize() if p != 'macos' else 'macOS' for p in test['supported_platforms']])}")
    #     mdFile.new_line(f"\n**auto_generated_guid:** {cleanup(test['auto_generated_guid'])}")
    #
    #     if test['input_arguments'] and len(test['input_arguments']) > 0:
    #         mdFile.new_line(
    #             "\n#### Inputs:\n| Name | Description | Type | Default Value |\n|------|-------------|------|---------------|")
    #     for arg_name, arg_options in test['input_arguments'].items():
    #         mdFile.new_line(
    #             f"| {cleanup(arg_name)} | {cleanup(arg_options['description'])} | {cleanup(arg_options['type'])} | {cleanup(arg_options['default'])} |")
    #
    #     if test['executor']['name'] == 'manual':
    #         mdFile.new_line("\n#### Run it with these steps!")
    #         mdFile.new_line(cleanup(test['executor']['steps']))
    #     if test['executor']['elevation_required']:
    #         mdFile.new_line("Elevation Required (e.g. root or admin)")
    #     else:
    #         mdFile.new_line(f"\n#### Attack Commands: Run with `{test['executor']['name']}`!")
    #     if test['executor']['elevation_required']:
    #         mdFile.new_line("Elevation Required (e.g. root or admin)")
    #
    #     language = get_language(test['executor']['name'])
    #     mdFile.new_line(f"```{language}\n{cleanup(test['executor']['command'])}\n```")
    #
    #     if test['executor']['cleanup_command'] is not None:
    #         mdFile.new_line("\n#### Cleanup Commands:")
    #         mdFile.new_line(f"```{language}\n{cleanup(test['executor']['cleanup_command'])}\n```")
    #
    #     if test['dependencies'] and len(test['dependencies']) > 0:
    #         dependency_executor = test['executor']['name']
    #         mdFile.new_line(
    #             f"\n#### Dependencies:  Run with `{test['dependency_executor_name'] if test['dependency_executor_name'] else test['executor']['name']}`!")
    #         for dep in test['dependencies']:
    #             mdFile.new_line(f"##### Description: {cleanup(dep['description'])}")
    #         mdFile.new_line(f"##### Check Prereq Commands:")
    #         mdFile.new_line(f"```{get_language(dependency_executor)}\n{cleanup(dep['prereq_command'])}\n```")
    #         mdFile.new_line(f"##### Get Prereq Commands:")
    #         mdFile.new_line(f"```{get_language(dependency_executor)}\n{cleanup(dep['get_prereq_command'])}\n```")
    #
    doc.dump(file_name[:-3])


def convert_to_md(file_name, technique):
    identifier = technique['attack_technique'].upper()
    mdFile = MdUtils(file_name=file_name, title="")
    mdFile.new_header(1, f"{identifier} - {technique['display_name']}")
    mdFile.new_header(2,
                      f"[Description from ATT&CK](https://attack.mitre.org/techniques/{identifier.replace('.', '/')})")
    # mdFile.new_line(f"""<blockquote>{technique['description']}</blockquote>""")
    mdFile.new_header(2, "Atomic Tests")
    items = [f"Atomic Test #{index + 1} - {test['name']}" for index, test in enumerate(technique["atomic_tests"])]
    items = [f"[{item}](#{item.lower().replace(' ', '-').replace('#', '')})" for item in items]
    mdFile.new_list(items)
    mdFile.new_line("<br/>")
    mdFile.new_line()

    for index, test in enumerate(technique["atomic_tests"]):
        mdFile.new_header(2, f"Atomic Test #{index + 1} - {test['name']}")
        mdFile.new_line(test["description"])
        supported_platforms = ",".join([get_supported_platform(i) for i in test['supported_platforms']])
        mdFile.new_line(f"**Supported Platforms:** {supported_platforms}")
        mdFile.new_line(f"**auto_generated_guid:** {test['auto_generated_guid']}")
        if len(test.get("input_arguments", {})) > 0:
            mdFile.new_header(3, "Inputs:")
            input_args = ["Name", "Description", "Type", "Default Value"]
            for key, value in test['input_arguments'].items():
                input_args.extend([key, value["description"], value["type"], value["default"]])
            mdFile.new_line()
            mdFile.new_table(columns=4, rows=len(test['input_arguments']) + 1, text=input_args, text_align='center')
            mdFile.new_line()
        if test['executor']['name'] == "manual":
            pass
        else:
            attack_exec = f"Attack Commands: Run with `{test['executor']['name']}`!"
            if test['executor'].get("elevation_required", False):
                attack_exec += "  Elevation Required (e.g. root or admin) "
            mdFile.new_header(3, attack_exec)
            mdFile.insert_code(test['executor']['command'], language=get_language(test['executor']['name']))
            mdFile.new_line()
            if test['executor'].get('cleanup_command'):
                mdFile.new_header(3, "Cleanup Commands:")
                mdFile.insert_code(test['executor']['cleanup_command'], language=get_language(test['executor']['name']))
        mdFile.new_line("<br/>")
        mdFile.new_line("<br/>")
    # # mdFile.block_quote(cleanup(technique['description']).replace("%<", "%\\<"))
    #
    # for test_number, test in enumerate(technique['atomic_tests']):
    #     title = f"Atomic Test #{test_number + 1} - {test['name']}"
    #     mdFile.new_line(f"- [{title}](#{title.lower()})")
    #
    #     for test_number, test in enumerate(technique['atomic_tests']):
    #         mdFile.new_line('\n')
    #         mdFile.new_line(f"## Atomic Test #{test_number + 1} - {test['name']}")
    #     mdFile.new_line(cleanup(test['description']))
    #
    #     mdFile.new_line(
    #         f"\n**Supported Platforms:** {', '.join([p.capitalize() if p != 'macos' else 'macOS' for p in test['supported_platforms']])}")
    #     mdFile.new_line(f"\n**auto_generated_guid:** {cleanup(test['auto_generated_guid'])}")
    #
    #     if test['input_arguments'] and len(test['input_arguments']) > 0:
    #         mdFile.new_line(
    #             "\n#### Inputs:\n| Name | Description | Type | Default Value |\n|------|-------------|------|---------------|")
    #     for arg_name, arg_options in test['input_arguments'].items():
    #         mdFile.new_line(
    #             f"| {cleanup(arg_name)} | {cleanup(arg_options['description'])} | {cleanup(arg_options['type'])} | {cleanup(arg_options['default'])} |")
    #
    #     if test['executor']['name'] == 'manual':
    #         mdFile.new_line("\n#### Run it with these steps!")
    #         mdFile.new_line(cleanup(test['executor']['steps']))
    #     if test['executor']['elevation_required']:
    #         mdFile.new_line("Elevation Required (e.g. root or admin)")
    #     else:
    #         mdFile.new_line(f"\n#### Attack Commands: Run with `{test['executor']['name']}`!")
    #     if test['executor']['elevation_required']:
    #         mdFile.new_line("Elevation Required (e.g. root or admin)")
    #
    #     language = get_language(test['executor']['name'])
    #     mdFile.new_line(f"```{language}\n{cleanup(test['executor']['command'])}\n```")
    #
    #     if test['executor']['cleanup_command'] is not None:
    #         mdFile.new_line("\n#### Cleanup Commands:")
    #         mdFile.new_line(f"```{language}\n{cleanup(test['executor']['cleanup_command'])}\n```")
    #
    #     if test['dependencies'] and len(test['dependencies']) > 0:
    #         dependency_executor = test['executor']['name']
    #         mdFile.new_line(
    #             f"\n#### Dependencies:  Run with `{test['dependency_executor_name'] if test['dependency_executor_name'] else test['executor']['name']}`!")
    #         for dep in test['dependencies']:
    #             mdFile.new_line(f"##### Description: {cleanup(dep['description'])}")
    #         mdFile.new_line(f"##### Check Prereq Commands:")
    #         mdFile.new_line(f"```{get_language(dependency_executor)}\n{cleanup(dep['prereq_command'])}\n```")
    #         mdFile.new_line(f"##### Get Prereq Commands:")
    #         mdFile.new_line(f"```{get_language(dependency_executor)}\n{cleanup(dep['get_prereq_command'])}\n```")
    #
    mdFile.create_md_file()


for file in glob.glob(f'{os.getcwd()}/atomics/**/T*.yaml'):
    path = pathlib.PurePath(file)
    directory = os.path.dirname(file)
    with open(file, "r") as f:
        atomic = yaml.load(f)
        # atomic["description"] = get_technique_description(path.parent.name)
        convert_to_readme(f"{directory}/{path.parent.name}.md", atomic)
    break
