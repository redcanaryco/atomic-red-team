require 'open-uri'
require 'json'

#
# Attack is an API class that loads information about ATT&CK techniques from MITRE'S ATT&CK 
# STIX representation. It makes it very simple to do common things with ATT&CK.
#
class Attack
  # 
  # Tactics as presented in the order that the ATT&CK matrics uses
  #
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
      'impact'
    ]
  end

  # 
  # Returns the technique identifier (T1234) for a Technique object
  #
  def technique_identifier_for_technique(technique)
    technique.fetch('external_references', []).find do |refs| 
      refs['source_name'] == 'mitre-attack'
    end['external_id'].upcase
  end

  # 
  # Returns a Technique object given a technique identifier (T1234)
  #
  def technique_info(technique_id)
    techniques.find do |item| 
      item.fetch('external_references', []).find do |references|
        references['external_id'] == technique_id.upcase
      end
    end
  end
  
  # 
  # Returns the ATT&CK Matrix as a 2D array, in order by `ordered_tactics`
  #
  def ordered_tactic_to_technique_matrix(only_platform: /.*/)
    all_techniques = techniques_by_tactic(only_platform: only_platform)

    # make an 2d array of our techniques in the order our tactics appear
    all_techniques_in_tactic_order = []
    ordered_tactics.each do |tactic|
      all_techniques_in_tactic_order << all_techniques[tactic]
    end

    # figure out the max number of techniques any one tactic has
    max_techniques = all_techniques_in_tactic_order.collect(&:count).max

    # extend each array of techniques to that length
    all_techniques_in_tactic_order.each {|techniques| techniques.concat(Array.new(max_techniques - techniques.count, nil))}

    # transpose to give us the data in columnar format
    all_techniques_in_tactic_order.transpose
  end

  # 
  # Returns a map of all [ ATT&CK Tactic name ] => [ List of ATT&CK techniques associated with that tactic]
  #
  def techniques_by_tactic(only_platform: /.*/)
    techniques_by_tactic = Hash.new {|h, k| h[k] = []}
    techniques.each do |technique|
      next unless !technique['x_mitre_platforms'].nil?
      next unless technique['x_mitre_platforms'].any? { |platform| platform.downcase.sub(" ", "-") =~ only_platform }

      technique.fetch('kill_chain_phases', []).select { |phase| phase['kill_chain_name'] == 'mitre-attack' }.each do |tactic|
        techniques_by_tactic[tactic.fetch('phase_name')] << technique
      end
    end
    techniques_by_tactic
  end 

  #
  # Returns a list of all ATT&CK techniques
  #
  def techniques
    return @techniques unless @techniques.nil?

    # pull out the attack pattern objects
    @techniques = attack_stix.fetch("objects").select do |item| 
      item.fetch('type') == 'attack-pattern' && item.fetch('external_references', []).select do |references|
        references['source_name'] == 'mitre-attack'
      end
    end
  end

  private

  #
  # Returns the complete ATT&CK STIX collection parsed into a Hash
  #
  def attack_stix
    @attack_stix ||= begin
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
