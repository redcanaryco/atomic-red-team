#! /usr/bin/env ruby
require 'yaml'
require 'erb'
require './attack_api'
require './atomic_red_team'

class AtomicRedTeamDocs
  ATTACK_API = Attack.new
  ATOMIC_RED_TEAM = AtomicRedTeam.new

  def generate_all_the_docs!
    oks = []
    fails = []

    ATOMIC_RED_TEAM.atomic_tests.each do |atomic_yaml|
      begin
        print "Generating docs for #{atomic_yaml['atomic_yaml_path']}"
        generate_docs! atomic_yaml, atomic_yaml['atomic_yaml_path'].gsub(/.yaml/, '.md')
        
        oks << atomic_yaml['atomic_yaml_path']
        puts "OK"
      rescue => ex
        fails << atomic_yaml['atomic_yaml_path']
        puts "FAIL\n#{ex}\n#{ex.backtrace.join("\n")}"
      end
    end

    generate_attack_matrix!
    generate_index!
    
    return oks, fails
  end

  def generate_docs!(atomic_yaml, output_doc_path)
    technique = ATTACK_API.technique_info(atomic_yaml.fetch('attack_technique'))
    technique['identifier'] = atomic_yaml.fetch('attack_technique').upcase

    template = ERB.new File.read("#{File.dirname(__FILE__)}/atomics/atomic_doc_template.md.erb"), nil, "-"
    generated_doc = template.result(binding)

    print " => #{output_doc_path} => "
    File.write output_doc_path, generated_doc
  end

  def generate_attack_matrix!
    result = "| #{ATTACK_API.ordered_tactics.join(' | ')} |\n"
    result += "|#{'-----|' * ATTACK_API.ordered_tactics.count}\n"

    ATTACK_API.ordered_tactic_to_technique_matrix.each do |row_of_techniques|
      row_values = row_of_techniques.collect do |technique| 
        if technique
          ATOMIC_RED_TEAM.github_link_to_technique(technique)
        end
      end
      result += "| #{row_values.join(' | ')} |\n"
    end
    File.write "#{File.dirname(__FILE__)}/atomics/matrix.md", result
  end

  def generate_index!
    result = ''

    ATTACK_API.techniques_by_tactic.each do |tactic, techniques|
      result += "# #{tactic}\n"
      techniques.each do |technique|
        result += "- #{ATOMIC_RED_TEAM.github_link_to_technique(technique, true)}\n"
        ATOMIC_RED_TEAM.atomic_tests_for_technique(technique).each_with_index do |atomic_test, i|
          result += "  - Atomic Test ##{i+1}: #{atomic_test['name']}\n"
        end
      end
      result += "\n"
    end

    File.write "#{File.dirname(__FILE__)}/atomics/index.md", result
  end
end

oks, fails = AtomicRedTeamDocs.new.generate_all_the_docs!
puts
puts "Generated docs for #{oks.count} techniques, #{fails.count} failures"

exit fails.count