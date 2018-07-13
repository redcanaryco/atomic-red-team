---
layout: default
---

# Use Cases

## Test your production security controls
You have one or more security controls in production today. But do you know
how they perform when presented with specific adversary techniques? Atomic Red
Team can be used to introduce known adversary techniques in a controlled manner. 

*Questions to ask* 
- Are we receiving signals for all observable events?
- Are we receiving alerts for events that should occur with low frequency, or
  that have a high impact?

## Testing the coverage of a product during a proof of concept
The original use case for Atomic Red Team, these tests are an invaluable means
of validating vendor claims, or objectively measuring the presence or quality
of signals across multiple products.

*Questions to ask* 
- Are we receiving signals for all observable events?
- Are we receiving alerts for events that should occur with low frequency, or
  that have a high impact?
- Is alerting for a given event deterministic, or does it depend on runtime
  context (i.e,. user, parent/child process attributes, etc.)?

## Testing your analysis team and processes
While it is ideal that technical controls be tested and understood, it is
critical that information security leaders understand how their
operational capability--the combination of technical controls, expertise, and
response processes--perform in the face of a determined adversary. 

*Questions to ask*
- Do one or more of our technical controls identify the test or Chain Reaction? 
- Does detection depend on automated correlation? On human analysis? 
- In any event, how quickly do we detect the activity?
- How long does it take us to contain, remediate, recover?
- What is the signal-to-noise ratio for the detection critiera used to
  identify the activity? Is it sustainable, in conjunction with the criteria
  required to cover a greater percentage of the ATT&CK matrix?
