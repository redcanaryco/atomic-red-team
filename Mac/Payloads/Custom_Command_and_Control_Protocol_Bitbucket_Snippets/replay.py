"""Replay captured traffic from malware using Bitbucket snippets as a C2."""

import json
import bitbucket_transport

transport = bitbucket_transport.BitbucketTransport()

with open("traffic_history.json") as f:
    history = json.load(f)
    for event in history:
        print(event)
        if event.get("history_type") == "push":
            data = event["data"]
            transport.push(data)
        elif event.get("history_type") == "pop":
            result = transport.pop()
        if event.get("history_type") == "peek":
            result = transport.peek()
