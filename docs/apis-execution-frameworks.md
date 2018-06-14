---
layout: default
---

# Using the Atomic Red Team APIs
Atomic Red Team includes a Ruby API we use to validate atomic tests, generate docs, and 
[interact with ATT&CK](#bonus-apis-ruby-attck-api). 

> Want to contribute APIs for another language such as Python or Powershell?
  Follow the interface in `atomic_red_team/atomic_red_team.rb` and submit a pull request!

## Ruby API

Atomic Red Team comes with a Ruby API that we use when validating tests again our spec, generating
documentation in Markdown format, etc. You too can use the API to use Atomic Red Team tests
in your test execution framework.

### Installing
Add atomic-red-team to your Gemfile:
```ruby
gem 'atomic-red-team', git: 'git@github.com:redcanaryco/atomic-red-team.git', branch: :master
```

### Example: print all the Atomic Tests by ATT&CK technique
```ruby
require 'atomic_red_team'

AtomicRedTeam.new.atomic_tests.each do |atomic_yaml|
  puts "#{atomic_yaml['attack_technique']}"
  atomic_yaml['atomic_tests'].each do |atomic_test_yaml|
    puts "  #{atomic_test_yaml['name']}"
  end
end
```

### Example: Show what atomic tests we have for a specific ATT&CK technique
```ruby
require 'atomic_red_team'

AtomicRedTeam.new.atomic_tests_for_technique('T1117').each do |atomic_test_yaml|
  puts "#{atomic_test_yaml['name']}"
end
```

For additional examples, see the utilities in `bin/` or the API code in `atomic_red_team`.

## Bonus APIs: Ruby ATT&CK API
Atomic Red Team pulls information about ATT&CK techniques using the STIX definitions of ATT&CK located
on [MITRE's CTI Github](https://raw.githubusercontent.com/mitre/cti/master/enterprise-attack/enterprise-attack.json).

We created a lightweight wrapper around that data structure to make it simple to consume. If you
would like to use it, install the atomic-red-team gem as [described above](#using-the-atomic-red-team-api),
and then:

```ruby
$ bundle exec irb
2.2.0 :001 > require 'attack_api'
```

### Example: Get all the techniques
```ruby
2.2.0 :020 > Attack.new.techniques.count
 => 219
```

### Example: Get information about a technique by it's friendly identifier
```ruby
2.2.0 :006 >   Attack.new.technique_info('T1117')
 => {"name"=>"Regsvr32", "description"=>"Regsvr32.exe is a command-line program used to register and unregister
 object linking and embedding controls, including dynamic link libraries (DLLs), on Windows systems. Regsvr32.exe can
 be used to execute arbitrary binaries. (Citation: Microsoft Regsvr32)\n\nAdversaries may take advantage of this
 functionality to proxy" <SNIP> }

2.2.0 :007 > Attack.new.technique_info('T1117').keys
 => ["name", "description", "kill_chain_phases", "external_references", "object_marking_refs", "created",
 "created_by_ref", "x_mitre_platforms", "x_mitre_data_sources", "x_mitre_defense_bypassed",
 "x_mitre_permissions_required", "x_mitre_remote_support", "x_mitre_contributors", "id", "modified", "type"]
```

### Example: Get a map of ATT&CK Tactic to all the Techniques associated with it
```ruby
2.2.0 :019 > Attack.new.techniques_by_tactic.each {|tactic, techniques| puts "#{tactic} has #{techniques.count} techniques"}
persistence has 56 techniques
defense-evasion has 59 techniques
privilege-escalation has 28 techniques
discovery has 19 techniques
credential-access has 20 techniques
execution has 31 techniques
lateral-movement has 17 techniques
collection has 13 techniques
exfiltration has 9 techniques
command-and-control has 21 techniques
initial-access has 10 techniques
```

### Example (my favorite): Getting a 2D array of the ATT&CK matrix of Tactic columns and Technique rows:
```ruby
2.2.0 :062 > Attack.new.ordered_tactics
 => ["initial-access", "execution", "persistence", "privilege-escalation", "defense-evasion", "credential-access",
 "discovery", "lateral-movement", "collection", "exfiltration", "command-and-control"]

2.2.0 :071 > Attack.new.ordered_tactic_to_technique_matrix.each {|row| puts row.collect {|technique| technique['name'] if technique}.join(', ')};
Drive-by Compromise, AppleScript, .bash_profile and .bashrc, Access Token Manipulation, Access Token Manipulation, Account Manipulation, Account Discovery, AppleScript, Audio Capture, Automated Exfiltration, Commonly Used Port
Exploit Public-Facing Application, CMSTP, Accessibility Features, Accessibility Features, BITS Jobs, Bash History, Application Window Discovery, Application Deployment Software, Automated Collection, Data Compressed, Communication Through Removable Media
Hardware Additions, Command-Line Interface, AppCert DLLs, AppCert DLLs, Binary Padding, Brute Force, Browser Bookmark Discovery, Distributed Component Object Model, Clipboard Data, Data Encrypted, Connection Proxy
<SNIP>
, , Winlogon Helper DLL, , Timestomp, , , , , ,
, , , , Trusted Developer Utilities, , , , , ,
, , , , Valid Accounts, , , , , ,
, , , , Web Service, , , , , ,
```
