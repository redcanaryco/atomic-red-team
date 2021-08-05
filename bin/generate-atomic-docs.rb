#! /usr/bin/env ruby
$LOAD_PATH << "#{File.dirname(File.dirname(__FILE__))}/atomic_red_team" unless $LOAD_PATH.include? "#{File.dirname(File.dirname(__FILE__))}/atomic_red_team"
require 'erb'
require 'fileutils'
require 'json'
require 'atomic_red_team'
require 'csv'

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
    generate_attack_matrix! 'All', "#{File.dirname(File.dirname(__FILE__))}/atomics/Indexes/Matrices/matrix.md"
    generate_attack_matrix! 'Windows', "#{File.dirname(File.dirname(__FILE__))}/atomics/Indexes/Matrices/windows-matrix.md", only_platform: /windows/
    generate_attack_matrix! 'macOS', "#{File.dirname(File.dirname(__FILE__))}/atomics/Indexes/Matrices/macos-matrix.md", only_platform: /macos/
    generate_attack_matrix! 'Linux', "#{File.dirname(File.dirname(__FILE__))}/atomics/Indexes/Matrices/linux-matrix.md", only_platform: /^(?!windows|macos).*$/

    generate_index! 'All', "#{File.dirname(File.dirname(__FILE__))}/atomics/Indexes/Indexes-Markdown/index.md"
    generate_index! 'Windows', "#{File.dirname(File.dirname(__FILE__))}/atomics/Indexes/Indexes-Markdown/windows-index.md", only_platform: /windows/
    generate_index! 'macOS', "#{File.dirname(File.dirname(__FILE__))}/atomics/Indexes/Indexes-Markdown/macos-index.md", only_platform: /macos/
    generate_index! 'Linux', "#{File.dirname(File.dirname(__FILE__))}/atomics/Indexes/Indexes-Markdown/linux-index.md", only_platform: /^(?!windows|macos).*$/

    generate_index_csv!  "#{File.dirname(File.dirname(__FILE__))}/atomics/Indexes/Indexes-CSV/index.csv"
    generate_index_csv!  "#{File.dirname(File.dirname(__FILE__))}/atomics/Indexes/Indexes-CSV/windows-index.csv", only_platform: /windows/
    generate_index_csv!  "#{File.dirname(File.dirname(__FILE__))}/atomics/Indexes/Indexes-CSV/macos-index.csv", only_platform: /macos/
    generate_index_csv!  "#{File.dirname(File.dirname(__FILE__))}/atomics/Indexes/Indexes-CSV/linux-index.csv", only_platform: /^(?!windows|macos).*$/

    generate_yaml_index! "#{File.dirname(File.dirname(__FILE__))}/atomics/Indexes/index.yaml"
    generate_navigator_layer! "#{File.dirname(File.dirname(__FILE__))}/atomics/Indexes/Attack-Navigator-Layers/art-navigator-layer.json", \
      "#{File.dirname(File.dirname(__FILE__))}/atomics/Indexes/Attack-Navigator-Layers/art-navigator-layer-windows.json", \
      "#{File.dirname(File.dirname(__FILE__))}/atomics/Indexes/Attack-Navigator-Layers/art-navigator-layer-macos.json", \
      "#{File.dirname(File.dirname(__FILE__))}/atomics/Indexes/Attack-Navigator-Layers/art-navigator-layer-linux.json"

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
          ATOMIC_RED_TEAM.github_link_to_technique(technique, include_identifier: false, only_platform: only_platform)
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
        result += "- #{ATOMIC_RED_TEAM.github_link_to_technique(technique, include_identifier: true, only_platform: only_platform)}\n"
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
  # Generates a master Markdown index of ATT&CK Tactic -> Technique -> Atomic Tests
  #
  def generate_index_csv!(output_doc_path_by_tactic, only_platform: /.*/)
    rows = Array.new
    rows << ["Tactic", "Technique #", "Technique Name", "Test #", "Test Name", "Test GUID", "Executor Name"]

    ATTACK_API.techniques_by_tactic(only_platform: only_platform).each do |tactic, techniques|
      techniques.each do |technique|
        ATOMIC_RED_TEAM.atomic_tests_for_technique(technique).each_with_index do |atomic_test, i|
          next unless atomic_test['supported_platforms'].any? {|platform| platform.downcase =~ only_platform}
          rows << [tactic, technique['identifier'], technique['name'], i+1, atomic_test['name'], atomic_test['auto_generated_guid'], atomic_test['executor']['name']]
        end
      end
    end

    File.write(output_doc_path_by_tactic, rows.map(&:to_csv).join)

    puts "Generated Atomic Red Team CSV indexes at #{output_doc_path_by_tactic}"
  end

  #
  # Generates a master YAML index of ATT&CK Tactic -> Technique -> Atomic Tests
  #
  def generate_yaml_index!(output_doc_path)
    result = {}

    ATTACK_API.techniques_by_tactic.each do |tactic, techniques|
      result[tactic] = techniques.collect do |technique|
        [
            technique['external_references'][0]['external_id'],
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

  def get_layer(techniques, layer_name)
    layer = {
      "version" => "4.1",
      "name" => layer_name,
      "description" => layer_name + " MITRE ATT&CK Navigator Layer",
      "domain" => "mitre-enterprise",
      "gradient" => {
                  "colors" => ["#ce232e","#ce232e"],
                  "minValue" => 0,
                  "maxValue" => 100
                },
      "legendItems" => [
        "label" => "Has at least one test",
        "color" => "#ce232e"
      ],
      "techniques" => techniques
    }
  end
  #
  # Generates a MITRE ATT&CK Navigator Layer based on contributed techniques
  #
  def generate_navigator_layer!(output_layer_path, output_layer_path_win, output_layer_path_mac, output_layer_path_lin)

    techniques = []
    techniques_win = []
    techniques_mac = []
    techniques_lin = []

    ATOMIC_RED_TEAM.atomic_tests.each do |atomic_yaml|
      begin
        technique = {
          "techniqueID" => atomic_yaml['attack_technique'],
          "score" => 100,
          "enabled" => true,
          "comment" => "https://github.com/redcanaryco/atomic-red-team/blob/master/atomics/" + atomic_yaml['attack_technique'] + "/" + atomic_yaml['attack_technique'] + ".md"
        }
        techniqueParent =  {
          "techniqueID" => atomic_yaml['attack_technique'].split('.')[0],
          "score" => 100,
          "enabled" => true,
          "comment" => "https://github.com/redcanaryco/atomic-red-team/blob/master/atomics/" + atomic_yaml['attack_technique'] + "/" + atomic_yaml['attack_technique'] + ".md"
        }

        techniques.push(technique)
        techniques.push(techniqueParent) unless techniques.include?(techniqueParent)
        has_windows_tests = false
        has_macos_tests = false
        has_linux_tests = false
        atomic_yaml['atomic_tests'].each do |atomic|
          if atomic['supported_platforms'].any? {|platform| platform.downcase =~ /windows/} then has_windows_tests = true end
          if atomic['supported_platforms'].any? {|platform| platform.downcase =~ /macos/} then has_macos_tests = true end
          if atomic['supported_platforms'].any? {|platform| platform.downcase =~ /^(?!windows|macos).*$/} then has_linux_tests = true end
        end
        if has_windows_tests then
          techniques_win.push(technique)
          techniques_win.push(techniqueParent) unless techniques_win.include?(techniqueParent)
        end
        if has_macos_tests then
          techniques_mac.push(technique)
          techniques_mac.push(techniqueParent) unless techniques_mac.include?(techniqueParent)
        end
        if has_linux_tests then
          techniques_lin.push(technique)
          techniques_lin.push(techniqueParent) unless techniques_lin.include?(techniqueParent)
        end
      end
    end

    layer = get_layer techniques, "Atomic Red Team"
    layer_win = get_layer techniques_win, "Atomic Red Team (Windows)"
    layer_mac = get_layer techniques_mac, "Atomic Red Team (macOS)"
    layer_lin = get_layer techniques_lin, "Atomic Red Team (Linux)"

    File.write output_layer_path,layer.to_json
    File.write output_layer_path_win,layer_win.to_json
    File.write output_layer_path_mac,layer_mac.to_json
    File.write output_layer_path_lin,layer_lin.to_json

    puts "Generated Atomic Red Team ATT&CK Navigator Layers at #{output_layer_path}"
    puts "Generated Atomic Red Team ATT&CK Navigator Layers at #{output_layer_path_win}"
    puts "Generated Atomic Red Team ATT&CK Navigator Layers at #{output_layer_path_mac}"
    puts "Generated Atomic Red Team ATT&CK Navigator Layers at #{output_layer_path_lin}"
  end
end

#
# MAIN
#
oks, fails = AtomicRedTeamDocs.new.generate_all_the_docs!

exit fails.count
