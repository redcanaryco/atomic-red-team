---
layout: default
---

# Quick Start: Using Atomic Red Team to test your security

Our Atomic Red Team tests are small, highly portable detection tests mapped to the MITRE ATT&CK Framework. Each test
is designed to map back to a particular tactic. This gives defenders a highly actionable way to immediately start
testing their defenses against a broad spectrum of attacks.

## Best Practices

* Be sure to get permission and necessary approval before conducting tests. Unauthorized testing is a bad decision
and can potentially be a resume-generating event.

* Set up a test machine that would be similar to the build in your environment. Be sure you have your collection/EDR
solution in place, and that the endpoint is checking in and active.

* Spend some time developing a test plan or scenario. This can take many forms. An example test plan could be to
execute all the Discovery phase items at once in a batch file, or run each phase one by one, validating coverage as you go.
