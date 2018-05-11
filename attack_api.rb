#! /usr/bin/env ruby
require 'open-uri'
require 'json'

class Attack
  def ordered_tactics 
    [
      'initial-access',
      'execution',
      'persistence',
      'privilege-escalation',
      'defense-evasion',
      'credential-access',
      'discovery',
      'lateral-movement',
      'collection',
      'exfiltration',
      'command-and-control',
    ]
  end

  def technique_info(technique_id)
    techniques.find do |item| 
      item.fetch('external_references', []).find do |references|
        references['external_id'] == technique_id.upcase
      end
    end
  end
  
  def techniques_by_tactic
    techniques_by_tactic = Hash.new {|h, k| h[k] = []}
    techniques.each do |technique|
      technique.fetch('kill_chain_phases', []).select {|phase| phase['kill_chain_name'] == 'mitre-attack'}.each do |tactic|
        techniques_by_tactic[tactic.fetch('phase_name')] << technique
      end
    end
    techniques_by_tactic
  end 

  def ordered_tactic_to_technique_matrix
    # make an 2d array of our techniques in the order our tactics appear
    all_techniques_in_tactic_order = []
    ordered_tactics.each do |tactic|
      all_techniques_in_tactic_order << techniques_by_tactic[tactic]
    end

    # figure out the max number of techniques any one tactic has
    max_techniques = all_techniques_in_tactic_order.collect(&:count).max

    # extend each array of techniques to that length
    all_techniques_in_tactic_order.each {|techniques| techniques.concat(Array.new(max_techniques - techniques.count, nil))}

    # transpose to give us the data in columnar format
    all_techniques_in_tactic_order.transpose
  end

  def techniques
    # pull out the attack pattern objects
    attack_json.fetch("objects").select do |item| 
      item.fetch('type') == 'attack-pattern' && item.fetch('external_references', []).select do |references|
        references['source_name'] == 'mitre-attack'
      end
    end
  end

  def attack_json
    @attack_json ||= begin
      # load the full attack library
      local_attack_json_to_try = "#{File.dirname(__FILE__)}/enterprise-attack.json"
      if File.exists? local_attack_json_to_try
        JSON.parse File.read(local_attack_json_to_try)
      else
        JSON.parse open('https://raw.githubusercontent.com/mitre/cti/master/enterprise-attack/enterprise-attack.json').read
      end
    end
  end
end