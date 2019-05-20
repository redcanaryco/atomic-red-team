#! /usr/bin/env ruby
$LOAD_PATH << "#{File.dirname(File.dirname(__FILE__))}/atomic_red_team" unless $LOAD_PATH.include? "#{File.dirname(File.dirname(__FILE__))}/atomic_red_team"
require 'erb'
require 'fileutils'
require 'json'
require 'atomic_red_team'

class AtomicRedTeamDocs
  ATTACK_API = Attack.new
  ATOMIC_RED_TEAM = AtomicRedTeam.new
  ATOMIC_RED_TEAM_DIR = "#{File.dirname(File.dirname(__FILE__))}/atomic_red_team"

  #
  # Generates all the documentation used by Atomic Red Team
  #
  def generate_all_the_docs!
    oks = []
    fails = []

    ATOMIC_RED_TEAM.atomic_tests.each do |atomic_yaml|
      begin
        print "Generating docs for #{atomic_yaml['atomic_yaml_path']}"
        generate_technique_docs! atomic_yaml, atomic_yaml['atomic_yaml_path'].gsub(/.yaml/, '.md')
        # generate_technique_execution_docs! atomic_yaml, "#{File.dirname(File.dirname(__FILE__))}/atomic-red-team-execution/#{atomic_yaml['attack_technique'].downcase}.html"

        oks << atomic_yaml['atomic_yaml_path']
        puts "OK"
      rescue => ex
        fails << atomic_yaml['atomic_yaml_path']
        puts "FAIL\n#{ex}\n#{ex.backtrace.join("\n")}"
      end
    end
    puts
    puts "Generated docs for #{oks.count} techniques, #{fails.count} failures"
    generate_attack_matrix! 'All', "#{File.dirname(File.dirname(__FILE__))}/atomics/matrix.md"
    generate_attack_matrix! 'Windows', "#{File.dirname(File.dirname(__FILE__))}/atomics/windows-matrix.md", only_platform: /windows/
    generate_attack_matrix! 'macOS', "#{File.dirname(File.dirname(__FILE__))}/atomics/macos-matrix.md", only_platform: /macos/
    generate_attack_matrix! 'Linux', "#{File.dirname(File.dirname(__FILE__))}/atomics/linux-matrix.md", only_platform: /^(?!windows|macos).*$/

    generate_index! 'All', "#{File.dirname(File.dirname(__FILE__))}/atomics/index.md"
    generate_index! 'Windows', "#{File.dirname(File.dirname(__FILE__))}/atomics/windows-index.md", only_platform: /windows/
    generate_index! 'macOS', "#{File.dirname(File.dirname(__FILE__))}/atomics/macos-index.md", only_platform: /macos/
    generate_index! 'Linux', "#{File.dirname(File.dirname(__FILE__))}/atomics/linux-index.md", only_platform: /^(?!windows|macos).*$/

    generate_yaml_index! "#{File.dirname(File.dirname(__FILE__))}/atomics/index.yaml"
    generate_navigator_layer! "#{File.dirname(File.dirname(__FILE__))}/atomics/art_navigator_layer.json"

    return oks, fails
  end

  #
  # Generates Markdown documentation for a specific technique from its YAML source
  #
  def generate_technique_docs!(atomic_yaml, output_doc_path)
    technique = ATTACK_API.technique_info(atomic_yaml.fetch('attack_technique'))
    technique['identifier'] = atomic_yaml.fetch('attack_technique').upcase

    template = ERB.new File.read("#{ATOMIC_RED_TEAM_DIR}/atomic_doc_template.md.erb"), nil, "-"
    generated_doc = template.result(binding)

    print " => #{output_doc_path} => "
    File.write output_doc_path, generated_doc
  end

  #
  # Generates Markdown documentation for a specific technique from its YAML source
  #
  def generate_technique_execution_docs!(atomic_yaml, output_doc_path)
    FileUtils.mkdir_p File.dirname(output_doc_path)

    technique = ATTACK_API.technique_info(atomic_yaml.fetch('attack_technique'))
    technique['identifier'] = atomic_yaml.fetch('attack_technique').upcase

    template = ERB.new File.read("#{ATOMIC_RED_TEAM_DIR}/atomic_execution_template.html.erb"), nil, "-"
    generated_doc = template.result(binding)

    print " => #{output_doc_path} => "
    File.write output_doc_path, generated_doc
  end

  #
  # Generates a Markdown ATT&CK documentation matrix for all techniques
  #
  def generate_attack_matrix!(title_prefix, output_doc_path, only_platform: /.*/)
    result = ''
    result += "# #{title_prefix} Atomic Tests by ATT&CK Tactic & Technique\n"

    result += "| #{ATTACK_API.ordered_tactics.join(' | ')} |\n"
    result += "|#{'-----|' * ATTACK_API.ordered_tactics.count}\n"

    ATTACK_API.ordered_tactic_to_technique_matrix(only_platform: only_platform).each do |row_of_techniques|
      row_values = row_of_techniques.collect do |technique|
        if technique
          ATOMIC_RED_TEAM.github_link_to_technique(technique, include_identifier: false, link_new_to_contrib: false)
        end
      end
      result += "| #{row_values.join(' | ')} |\n"
    end
    File.write output_doc_path, result

    puts "Generated ATT&CK matrix at #{output_doc_path}"
  end

  #
  # Generates a master Markdown index of ATT&CK Tactic -> Technique -> Atomic Tests
  #
  def generate_index!(title_prefix, output_doc_path, only_platform: /.*/)
    result = ''
    result += "# #{title_prefix} Atomic Tests by ATT&CK Tactic & Technique\n"

    ATTACK_API.techniques_by_tactic(only_platform: only_platform).each do |tactic, techniques|
      result += "# #{tactic}\n"
      techniques.each do |technique|
        result += "- #{ATOMIC_RED_TEAM.github_link_to_technique(technique, include_identifier: true, link_new_to_contrib: true)}\n"
        ATOMIC_RED_TEAM.atomic_tests_for_technique(technique).each_with_index do |atomic_test, i|
          next unless atomic_test['supported_platforms'].any? {|platform| platform.downcase =~ only_platform}

          result += "  - Atomic Test ##{i+1}: #{atomic_test['name']} [#{atomic_test['supported_platforms'].join(', ')}]\n"
        end
      end
      result += "\n"
    end

    File.write output_doc_path, result

    puts "Generated Atomic Red Team index at #{output_doc_path}"
  end

  #
  # Generates a master YAML index of ATT&CK Tactic -> Technique -> Atomic Tests
  #
  def generate_yaml_index!(output_doc_path)
    result = {}

    ATTACK_API.techniques_by_tactic.each do |tactic, techniques|
      result[tactic] = techniques.collect do |technique|
        [
            technique['identifier'],
            {
                'technique' => technique,
                'atomic_tests' => ATOMIC_RED_TEAM.atomic_tests_for_technique(technique)
            }
        ]
      end.to_h
    end

    File.write output_doc_path, JSON.parse(result.to_json).to_yaml # shenanigans to eliminate YAML aliases

    puts "Generated Atomic Red Team YAML index at #{output_doc_path}"
  end

  #
  # Generates a MITRE ATT&CK Navigator Layer based on contributed techniques
  #
  def generate_navigator_layer!(output_layer_path)

    techniques = []
    
    ATOMIC_RED_TEAM.atomic_tests.each do |atomic_yaml|
      begin
        technique = {
          "techniqueID" => atomic_yaml['attack_technique'],
          "score" => 100,
          "enabled" => true
        }

        techniques.push(technique)
      end

    layer = {
      "version" => "2.1",
      "name" => "Atomic Red Team",
      "description" => "Atomic Red Team MITRE ATT&CK Navigator Layer",
      "domain" => "mitre-enterprise",
      "gradient" => {
                  "colors" => ["#ce232e","#ce232e"],
                  "minValue" => 0,
                  "maxValue" => 100
                },
      "techniques" => techniques
    }

    File.write output_layer_path,layer.to_json
    end

    puts "Generated Atomic Red Team ATT&CK Navigator Layer at #{output_layer_path}"
  end
end

#
# MAIN
#
oks, fails = AtomicRedTeamDocs.new.generate_all_the_docs!

exit fails.count