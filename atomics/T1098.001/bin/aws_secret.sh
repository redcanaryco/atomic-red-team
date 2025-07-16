#! /bin/sh

echo "Creating Profile in ./aws/credentials"

access_key=`cat aws_secret.creds| jq -r '.AccessKey.AccessKeyId'`
secret_key=`cat aws_secret.creds| jq -r '.AccessKey.SecretAccessKey'`

line=`grep -n atomicredteam ~/.aws/credentials | cut -d : -f1 |bc` 

access="$(($line+1))"
secret="$(($line+2))"

# Detect OS type for sed compatibility
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS version (requires empty string after -i)
    sed -i '' "${access}s|aws_access_key_id = .*$|aws_access_key_id = $access_key|g" ~/.aws/credentials
    sed -i '' "${secret}s|aws_secret_access_key = .*$|aws_secret_access_key = $secret_key|g" ~/.aws/credentials
else
    # Linux version
    sed -i "${access}s|aws_access_key_id = .*$|aws_access_key_id = $access_key|g" ~/.aws/credentials
    sed -i "${secret}s|aws_secret_access_key = .*$|aws_secret_access_key = $secret_key|g" ~/.aws/credentials
fi
