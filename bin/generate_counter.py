import os
import argparse
import urllib.parse
import yaml

# Parse command line arguments
parser = argparse.ArgumentParser(description='Generate an SVG counter for a folder with a list of YAML files.')
parser.add_argument('-f', '--folder', metavar='FOLDER', type=str, default='atomics/', help='the folder to search for YAML files (default: atomics/)')
args = parser.parse_args()

# Find YAML files in the specified folder and subfolders
test_count = 0
for root, dirs, files in os.walk(args.folder):
    for filename in files:
        if filename.endswith('.yaml') and root.startswith(os.path.join(args.folder, 'T')):
            with open(os.path.join(root, filename), 'r') as f:
                yaml_data = yaml.safe_load(f)
                if yaml_data is not None and 'atomic_tests' in yaml_data:
                    test_count += len(yaml_data['atomic_tests'])

# Generate the shields.io badge URL
params = {
    'label': 'Atomics',
    'message': str(test_count),
    'style': 'flat'
}
url = 'https://img.shields.io/badge/{}-{}-{}.svg'.format(
    urllib.parse.quote_plus(params['label']),
    urllib.parse.quote_plus(params['message']),
    urllib.parse.quote_plus(params['style'])
)

# Save shields URL in Github Output to be used in the next step.
with open(os.environ['GITHUB_OUTPUT'], 'a') as fh:
    print(f'result={url}', file=fh)

