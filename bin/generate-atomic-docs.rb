#! /usr/bin/env ruby
$LOAD_PATH << "#{File.dirname(File.dirname(__FILE__))}/atomic_red_team" unless $LOAD_PATH.include? "#{File.dirname(File.dirname(__FILE__))}/atomic_red_team"
require 'erb'
require 'fileutils'
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
end

#
# MAIN
#
oks, fails = AtomicRedTeamDocs.new.generate_all_the_docs!

exit fails.count