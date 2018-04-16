# Custom Command and Control Protocol

MITRE ATT&CK Technique: [T1146](https://attack.mitre.org/wiki/Technique/T1094)

## Communication over Bitbucket Snippets
The use of a legitimate service as transport is a common technique to evade detection by masquerading as the legitimate service.

Below are instructions to run a script to simulate traffic from a malware implant that communicates via a custom protocol implemented in [Bitbucket Snippets](https://confluence.atlassian.com/bitbucket/snippets-719095082.html).

The malware itself isn't included, just the traffic simulation.

### Installation

#### Step 1: Create a new Bitbucket account

We recommend using a fresh account for this so as not to pollute the snippets of your existing account.

https://bitbucket.org/account/signup/

#### Step 2: Include its credentials in `auth.json`
In the directory [Payloads/Custom_Command_and_Control_Protocol_Bitbucket_Snippets](Payloads/Custom_Command_and_Control_Protocol_Bitbucket_Snippets):

```
cp auth.json.template auth.json
```

Edit `auth.json` to include the username, email, and password of the Bitbucket account. `auth.json` should not be added to version control.

### Step 3: Install dependencies
```
pip install -r requirements.txt
```

### Usage
To simulate the network traffic, run:
```
python replay.py
```

You will need to be using Python 3.

This will make requests to `bitbucket.org` urls, recorded from an interactive session with the malware.
The session recording of the malware is available to view and modify at [traffic_history.json](bitbucket_protocol/traffic_history.json)
