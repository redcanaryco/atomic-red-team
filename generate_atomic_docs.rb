#! /usr/bin/env ruby
require 'yaml'
require 'ostruct'
require 'erb'
require 'open-uri'
require 'json'

def attack_technique_library
  @attack_json ||= begin
    # load the full attack library
    local_attack_json_to_try = "#{File.dirname(__FILE__)}/enterprise-attack.json"
    parsed = if File.exists? local_attack_json_to_try
      JSON.parse File.read(local_attack_json_to_try)
    else
      JSON.parse open('https://raw.githubusercontent.com/mitre/cti/master/enterprise-attack/enterprise-attack.json').read
    end

    # pull out the attack pattern objects
    parsed.fetch("objects").select do |item| 
      item.fetch('type') == 'attack-pattern' && item.fetch('external_references', []).select do |references|
        references['source_name'] == 'mitre-attack'
      end
    end

  end
end

def attack_technique_info(technique_id)
  attack_technique_library.find do |item| 
    item.fetch('external_references', []).find do |references|
      references['external_id'] == technique_id.upcase
    end
  end
end

def all_techniques_by_tactic
  @all_techniques_by_tactic ||= begin
    all_techniques_by_tactic = Hash.new {|h, k| h[k] = []}
    attack_technique_library.each do |technique|
      tactic = technique.fetch('kill_chain_phases', []).find {|phase| phase['kill_chain_name'] == 'mitre-attack'}.fetch('phase_name')
      all_techniques_by_tactic[tactic] << technique
    end
    all_techniques_by_tactic
  end
end

def generate_docs!(atomic_yaml, output_doc_path)
  technique = attack_technique_info(atomic_yaml.fetch('attack_technique'))
  technique['identifier'] = atomic_yaml.fetch('attack_technique').upcase

  template = ERB.new File.read("#{File.dirname(__FILE__)}/atomics/atomic_doc_template.md.erb"), nil, "-"
  generated_doc = template.result(binding)

  print " => #{output_doc_path} => "
  File.write output_doc_path, generated_doc
end

def update_index_mapping(atomic_yaml, techniques_by_tactic)
  technique = attack_technique_info(atomic_yaml.fetch('attack_technique'))
  technique.fetch('kill_chain_phases', []).select {|phase| phase['kill_chain_name'] == 'mitre-attack'}.each do |tactic|
    techniques_by_tactic[tactic.fetch('phase_name')] << technique
  end
end

def generate_indices!(techniques_by_tactic)
  ordered_tactics = [
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

  result = ''
  result += "| #{ordered_tactics.join(' | ')} |\n"
  result += "|#{'-----|' * ordered_tactics.count}\n"

  all_techniques_in_tactic_order = []
  ordered_tactics.each do |tactic|
    all_techniques_in_tactic_order << all_techniques_by_tactic[tactic]
  end
  max_tactics = all_techniques_in_tactic_order.collect(&:count).max
  all_techniques_in_tactic_order.each {|techniques| techniques.concat(Array.new(max_tactics - techniques.count, nil))}

  p all_techniques_in_tactic_order.count
  all_techniques_in_tactic_order.transpose.each do |row|
    p row, row.class
    result += "| #{row.collect {|t| t['name'] if t}.join(' | ')} |\n"
  end

  # all_techniques_by_tactic.to_a.transpose[1..-1].first.each do |techniques|
  #   p techniques, techniques.count, '-----'
  #   result += "| #{techniques.collect {|t| t['name']}.join(' | ')} |\n"
  # end
  File.write "#{File.dirname(__FILE__)}/atomics/index.md", result
end

oks = []
fails = []
techniques_by_tactic = Hash.new {|h, k| h[k] = []}

Dir["#{File.dirname(__FILE__)}/atomics/t*/t*.yaml"].sort.each do |path|
  begin
    print "Generating docs for #{path}"
    atomic_yaml = YAML.load(File.read path)

    generate_docs! atomic_yaml, path.gsub(/.yaml/, '.md')
    update_index_mapping atomic_yaml, techniques_by_tactic
    
    puts "OK"
  rescue => ex
    fails << path
    puts "FAIL (#{ex} #{ex.backtrace.join("\n")})"
  end
end

generate_indices! techniques_by_tactic

puts
puts "Generated docs for #{oks.count} techniques, #{fails.count} failures"

exit fails.count