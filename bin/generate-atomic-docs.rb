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
    generate_attack_matrix! 'Linux', "#{File.dirname(File.dirname(__FILE__))}/atomics/Indexes/Matrices/linux-matrix.md", only_platform: /linux/

    generate_index! 'All', "#{File.dirname(File.dirname(__FILE__))}/atomics/Indexes/Indexes-Markdown/index.md"
    generate_index! 'Windows', "#{File.dirname(File.dirname(__FILE__))}/atomics/Indexes/Indexes-Markdown/windows-index.md", only_platform: /windows/
    generate_index! 'macOS', "#{File.dirname(File.dirname(__FILE__))}/atomics/Indexes/Indexes-Markdown/macos-index.md", only_platform: /macos/
    generate_index! 'Linux', "#{File.dirname(File.dirname(__FILE__))}/atomics/Indexes/Indexes-Markdown/linux-index.md", only_platform: /linux/
    generate_index! 'IaaS', "#{File.dirname(File.dirname(__FILE__))}/atomics/Indexes/Indexes-Markdown/iaas-index.md", only_platform: /iaas/
    generate_index! 'Containers', "#{File.dirname(File.dirname(__FILE__))}/atomics/Indexes/Indexes-Markdown/containers-index.md", only_platform: /containers/
    generate_index! 'Office 365', "#{File.dirname(File.dirname(__FILE__))}/atomics/Indexes/Indexes-Markdown/office-365-index.md", only_platform: /office-365/
    generate_index! 'Google Workspace', "#{File.dirname(File.dirname(__FILE__))}/atomics/Indexes/Indexes-Markdown/google-workspace-index.md", only_platform: /google-workspace/
    generate_index! 'Azure AD', "#{File.dirname(File.dirname(__FILE__))}/atomics/Indexes/Indexes-Markdown/azure-ad-index.md", only_platform: /azure-ad/

    generate_index_csv!  "#{File.dirname(File.dirname(__FILE__))}/atomics/Indexes/Indexes-CSV/index.csv"
    generate_index_csv!  "#{File.dirname(File.dirname(__FILE__))}/atomics/Indexes/Indexes-CSV/windows-index.csv", only_platform: /windows/
    generate_index_csv!  "#{File.dirname(File.dirname(__FILE__))}/atomics/Indexes/Indexes-CSV/macos-index.csv", only_platform: /macos/
    generate_index_csv!  "#{File.dirname(File.dirname(__FILE__))}/atomics/Indexes/Indexes-CSV/linux-index.csv", only_platform: /linux/
    generate_index_csv!  "#{File.dirname(File.dirname(__FILE__))}/atomics/Indexes/Indexes-CSV/iaas-index.csv", only_platform: /iaas/
    generate_index_csv!  "#{File.dirname(File.dirname(__FILE__))}/atomics/Indexes/Indexes-CSV/containers-index.csv", only_platform: /containers/
    generate_index_csv!  "#{File.dirname(File.dirname(__FILE__))}/atomics/Indexes/Indexes-CSV/office-365-index.csv", only_platform: /office-365/
    generate_index_csv!  "#{File.dirname(File.dirname(__FILE__))}/atomics/Indexes/Indexes-CSV/google-workspace-index.csv", only_platform: /google-workspace/
    generate_index_csv!  "#{File.dirname(File.dirname(__FILE__))}/atomics/Indexes/Indexes-CSV/azure-ad-index.csv", only_platform: /azure-ad/

    generate_yaml_index! "#{File.dirname(File.dirname(__FILE__))}/atomics/Indexes/index.yaml"
    generate_navigator_layer! "#{File.dirname(File.dirname(__FILE__))}/atomics/Indexes/Attack-Navigator-Layers/art-navigator-layer.json", \
      "#{File.dirname(File.dirname(__FILE__))}/atomics/Indexes/Attack-Navigator-Layers/art-navigator-layer-windows.json", \
      "#{File.dirname(File.dirname(__FILE__))}/atomics/Indexes/Attack-Navigator-Layers/art-navigator-layer-macos.json", \
      "#{File.dirname(File.dirname(__FILE__))}/atomics/Indexes/Attack-Navigator-Layers/art-navigator-layer-linux.json", \
      "#{File.dirname(File.dirname(__FILE__))}/atomics/Indexes/Attack-Navigator-Layers/art-navigator-layer-iaas.json", \
      "#{File.dirname(File.dirname(__FILE__))}/atomics/Indexes/Attack-Navigator-Layers/art-navigator-layer-iaas-aws.json", \
      "#{File.dirname(File.dirname(__FILE__))}/atomics/Indexes/Attack-Navigator-Layers/art-navigator-layer-iaas-azure.json", \
      "#{File.dirname(File.dirname(__FILE__))}/atomics/Indexes/Attack-Navigator-Layers/art-navigator-layer-iaas-gcp.json", \
      "#{File.dirname(File.dirname(__FILE__))}/atomics/Indexes/Attack-Navigator-Layers/art-navigator-layer-containers.json", \
      "#{File.dirname(File.dirname(__FILE__))}/atomics/Indexes/Attack-Navigator-Layers/art-navigator-layer-saas.json", \
      "#{File.dirname(File.dirname(__FILE__))}/atomics/Indexes/Attack-Navigator-Layers/art-navigator-layer-google-workspace.json", \
      "#{File.dirname(File.dirname(__FILE__))}/atomics/Indexes/Attack-Navigator-Layers/art-navigator-layer-azure-ad.json", \
      "#{File.dirname(File.dirname(__FILE__))}/atomics/Indexes/Attack-Navigator-Layers/art-navigator-layer-office-365.json"

    return oks, fails
  end

  #
  # Generates Markdown documentation for a specific technique from its YAML source
  #
  def generate_technique_docs!(atomic_yaml, output_doc_path)
    technique = ATTACK_API.technique_info(atomic_yaml.fetch('attack_technique'))
    technique['identifier'] = atomic_yaml.fetch('attack_technique').upcase
    technique['name'] = atomic_yaml.fetch('display_name')
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
    filters = { }
    if layer_name.include? "Windows"
      filters = { "platforms": [ "Windows"]}
    elsif layer_name.include? "macOS"
      filters = { "platforms": [ "macOS"]}
    elsif layer_name.include? "Linux"
      filters = { "platforms": [ "Linux"]}
    end

    layer = {
      "name" => layer_name,
      "versions" => {	"attack": "12",	"navigator": "4.7.1",	"layer": "4.3"	},
      "description" => layer_name + " MITRE ATT&CK Navigator Layer",
      "domain" => "enterprise-attack",
      "filters"=> filters,    
      "gradient" => {
                  "colors" => ["#ffffff",
                               "#ce232e"
                  ],
                  "minValue" => 0,
                  "maxValue" => 10
                },
      "legendItems" => [
        {
          "label" => "10 or more tests",
          "color" => "#ce232e"
        },
        {
          "label" => "1 or more tests",
          "color" => "#ffffff"
        }
      ],
      "techniques" => techniques
    }
  end
  

  #
  # Process the current technique and update the list
  # 
  def update_techniquesList(current_technique, current_techniqueParent, techniques_list, atomic_yaml, comments)
    if not atomic_yaml['attack_technique'].include?(".") then
      tech_parent = techniques_list.find { |h| h["techniqueID"] == atomic_yaml['attack_technique'].split('.')[0] }
      if tech_parent then
        tech_parent['score'] += current_technique['score']
        if comments then
          tech_parent.merge!("comment": current_technique['comment'])
        end
      else
        if not comments then
          current_technique.delete("comment")
        end
        techniques_list.push(current_technique)
      end
    else
      if tech_parent = techniques_list.find { |h| h["techniqueID"] == atomic_yaml['attack_technique'].split('.')[0] }
        puts tech_parent
        tech_parent['score'] += current_technique['score']
      else
        current_techniqueParent['score'] += current_technique['score']
        techniques_list.push(current_techniqueParent)
      end
      if not comments then
        current_technique.delete("comment")
      end
      techniques_list.push(current_technique)
    end
  end
  
  #
  # Generates a MITRE ATT&CK Navigator Layer based on contributed techniques
  #
  def generate_navigator_layer!(output_layer_path, output_layer_path_win, output_layer_path_mac, output_layer_path_lin, output_layer_path_iaas, \
    output_layer_path_iaas_aws, output_layer_path_iaas_azure, output_layer_path_iaas_gcp, output_layer_path_containers, output_layer_path_saas, \
    output_layer_path_google_workspace, output_layer_path_azure_ad, output_layer_path_office_365)

    techniques = []
    techniques_win = []
    techniques_mac = []
    techniques_lin = []
    techniques_iaas = []
    techniques_iaas_aws = []
    techniques_iaas_azure = []
    techniques_iaas_gcp = []
    techniques_containers = []
    techniques_saas = []
    techniques_google_workspace = []
    techniques_azure_ad = []
    techniques_office_365 = []

    ATOMIC_RED_TEAM.atomic_tests.each do |atomic_yaml|
      begin
        technique = {
          "techniqueID" => atomic_yaml['attack_technique'],
          "score" => 0,
          "enabled" => true,
          "comment" => "\n",
          "links" => ["label" => "View Atomic", "url" => "https://github.com/redcanaryco/atomic-red-team/blob/master/atomics/" + atomic_yaml['attack_technique'] + "/" + atomic_yaml['attack_technique'] + ".md"]
        }

        techniqueParent =  {
          "techniqueID" => atomic_yaml['attack_technique'].split('.')[0],
          "score" => 0,
          "enabled" => true,
          "links" => ["label" => "View Atomic", "url" => "https://github.com/redcanaryco/atomic-red-team/blob/master/atomics/" + atomic_yaml['attack_technique'].split('.')[0] + "/" + atomic_yaml['attack_technique'].split('.')[0] + ".md"]
        }

        has_windows_tests = false
        win_technique = technique.clone
        win_techniqueParent = techniqueParent.clone
        has_macos_tests = false
        macos_technique = technique.clone
        macos_techniqueParent = techniqueParent.clone
        has_linux_tests = false
        linux_technique = technique.clone
        linux_techniqueParent = techniqueParent.clone
        has_iaas_tests = false
        iaas_technique = technique.clone
        iaas_techniqueParent = techniqueParent.clone
        has_iaas_aws_tests = false
        iaas_aws_technique = technique.clone
        iaas_aws_techniqueParent = techniqueParent.clone
        has_iaas_azure_tests = false
        iaas_azure_technique = technique.clone
        iaas_azure_techniqueParent = techniqueParent.clone
        has_iaas_gcp_tests = false
        iaas_gcp_technique = technique.clone
        iaas_gcp_techniqueParent = techniqueParent.clone
        has_containers_tests = false
        containers_technique = technique.clone
        containers_techniqueParent = techniqueParent.clone
        has_saas_tests = false
        saas_technique = technique.clone
        saas_techniqueParent = techniqueParent.clone
        has_google_workspace_tests = false
        google_workspace_technique = technique.clone
        google_workspace_techniqueParent = techniqueParent.clone
        has_azure_ad_tests = false
        azure_ad_technique = technique.clone
        azure_ad_techniqueParent = techniqueParent.clone
        has_office_365_tests = false
        office_365_technique = technique.clone
        office_365_techniqueParent = techniqueParent.clone

        atomic_yaml['atomic_tests'].each do |atomic|
          technique['score'] += 1
          if atomic['supported_platforms'].any? {|platform| platform.downcase =~ /windows/} then
            has_windows_tests = true
            win_technique['score'] += 1
            win_technique['comment'] += "- " + atomic['name'] + "\n"
          end
          if atomic['supported_platforms'].any? {|platform| platform.downcase =~ /macos/} then 
            has_macos_tests = true
            macos_technique['score'] += 1
            macos_technique['comment'] += "- " + atomic['name'] + "\n"
          end
          if atomic['supported_platforms'].any? {|platform| platform.downcase =~ /linux/} then
            has_linux_tests = true
            linux_technique['score'] += 1
            linux_technique['comment'] += "- " + atomic['name'] + "\n"
          end
          if atomic['supported_platforms'].any? {|platform| platform.downcase =~ /^iaas/} then
            has_iaas_tests = true
            iaas_technique['score'] += 1
            iaas_technique['comment'] += "- " + atomic['name'] + "\n"
          end
          if atomic['supported_platforms'].any? {|platform| platform.downcase =~ /^iaas:aws/} then
            has_iaas_aws_tests = true
            iaas_aws_technique['score'] += 1
            iaas_aws_technique['comment'] += "- " + atomic['name'] + "\n"
          end
          if atomic['supported_platforms'].any? {|platform| platform.downcase =~ /^iaas:azure/} then
            has_iaas_azure_tests = true
            iaas_azure_technique['score'] += 1
            iaas_azure_technique['comment'] += "- " + atomic['name'] + "\n"
          end
          if atomic['supported_platforms'].any? {|platform| platform.downcase =~ /^iaas:gcp/} then
            has_iaas_gcp_tests = true
            iaas_gcp_technique['score'] += 1
            iaas_gcp_technique['comment'] += "- " + atomic['name'] + "\n"
          end
          if atomic['supported_platforms'].any? {|platform| platform.downcase =~ /^containers/} then
            has_containers_tests = true
            containers_technique['score'] += 1
            containers_technique['comment'] += "- " + atomic['name'] + "\n"
          end
          if atomic['supported_platforms'].any? {|platform| platform.downcase =~ /^google-workspace/} then
            has_google_workspace_tests = true
            google_workspace_technique['score'] += 1
            google_workspace_technique['comment'] += "- " + atomic['name'] + "\n"
          end
          if atomic['supported_platforms'].any? {|platform| platform.downcase =~ /^azure-ad/} then
            has_azure_ad_tests = true
            azure_ad_technique['score'] += 1
            azure_ad_technique['comment'] += "- " + atomic['name'] + "\n"
          end
          if atomic['supported_platforms'].any? {|platform| platform.downcase =~ /^office-365/} then
            has_office_365_tests = true
            office_365_technique['score'] += 1
            office_365_technique['comment'] += "- " + atomic['name'] + "\n"
          end
        end
        
        # Update full Atomic Layer
        update_techniquesList(technique, techniqueParent, techniques, atomic_yaml, false)
        # Update all other Atomic Layers
        if has_windows_tests then
          update_techniquesList(win_technique, win_techniqueParent, techniques_win, atomic_yaml, true)
        end
        if has_macos_tests then
          update_techniquesList(macos_technique, macos_techniqueParent, techniques_mac, atomic_yaml, true)
        end
        if has_linux_tests then
          update_techniquesList(linux_technique, linux_techniqueParent, techniques_lin, atomic_yaml, true)
        end
        if has_iaas_tests then
          update_techniquesList(iaas_technique, iaas_techniqueParent, techniques_iaas, atomic_yaml, true)
        end
        if has_iaas_aws_tests then
          update_techniquesList(iaas_aws_technique, iaas_aws_techniqueParent, techniques_iaas_aws, atomic_yaml, true)
        end
        if has_iaas_azure_tests then
          update_techniquesList(iaas_azure_technique, iaas_azure_techniqueParent, techniques_iaas_azure, atomic_yaml, true)
        end
        if has_iaas_gcp_tests then
          update_techniquesList(iaas_gcp_technique, iaas_gcp_techniqueParent, techniques_iaas_gcp, atomic_yaml, true)
        end
        if has_containers_tests then
          update_techniquesList(containers_technique, containers_techniqueParent, techniques_containers, atomic_yaml, true)
        end
        if has_google_workspace_tests then
          update_techniquesList(google_workspace_technique, google_workspace_techniqueParent, techniques_google_workspace, atomic_yaml, true)
        end
        if has_azure_ad_tests then
          update_techniquesList(azure_ad_technique, azure_ad_techniqueParent, techniques_azure_ad, atomic_yaml, true)
        end
        if has_office_365_tests then
          update_techniquesList(office_365_technique, office_365_techniqueParent, techniques_office_365, atomic_yaml, true)
        end
      end
    end
    
    puts techniques_iaas_gcp
    
    layer = get_layer techniques, "Atomic Red Team"
    layer_win = get_layer techniques_win, "Atomic Red Team (Windows)"
    layer_mac = get_layer techniques_mac, "Atomic Red Team (macOS)"
    layer_lin = get_layer techniques_lin, "Atomic Red Team (Linux)"
    layer_iaas = get_layer techniques_iaas, "Atomic Red Team (Iaas)"
    layer_iaas_aws = get_layer techniques_iaas_aws, "Atomic Red Team (Iaas:AWS)"
    layer_iaas_azure = get_layer techniques_iaas_azure, "Atomic Red Team (Iaas:Azure)"
    layer_iaas_gcp = get_layer techniques_iaas_gcp, "Atomic Red Team (Iaas:GCP)"
    layer_containers = get_layer techniques_containers, "Atomic Red Team (Containers)"
    layer_google_workspace = get_layer techniques_google_workspace, "Atomic Red Team (Google-Workspace)"
    layer_azure_ad = get_layer techniques_azure_ad, "Atomic Red Team (Azure-AD)"
    layer_office_365 = get_layer techniques_office_365, "Atomic Red Team (Office-365)"


    File.write output_layer_path,layer.to_json
    File.write output_layer_path_win,layer_win.to_json
    File.write output_layer_path_mac,layer_mac.to_json
    File.write output_layer_path_lin,layer_lin.to_json
    File.write output_layer_path_iaas,layer_iaas.to_json
    File.write output_layer_path_iaas_aws,layer_iaas_aws.to_json
    File.write output_layer_path_iaas_azure,layer_iaas_azure.to_json
    File.write output_layer_path_iaas_gcp,layer_iaas_gcp.to_json
    File.write output_layer_path_containers,layer_containers.to_json
    File.write output_layer_path_google_workspace,layer_google_workspace.to_json
    File.write output_layer_path_azure_ad,layer_azure_ad.to_json
    File.write output_layer_path_office_365,layer_office_365.to_json

    puts "Generated Atomic Red Team ATT&CK Navigator Layers at #{output_layer_path}"
    puts "Generated Atomic Red Team ATT&CK Navigator Layers at #{output_layer_path_win}"
    puts "Generated Atomic Red Team ATT&CK Navigator Layers at #{output_layer_path_mac}"
    puts "Generated Atomic Red Team ATT&CK Navigator Layers at #{output_layer_path_lin}"
    puts "Generated Atomic Red Team ATT&CK Navigator Layers at #{output_layer_path_iaas}"
    puts "Generated Atomic Red Team ATT&CK Navigator Layers at #{output_layer_path_iaas_aws}"
    puts "Generated Atomic Red Team ATT&CK Navigator Layers at #{output_layer_path_iaas_azure}"
    puts "Generated Atomic Red Team ATT&CK Navigator Layers at #{output_layer_path_iaas_gcp}"
    puts "Generated Atomic Red Team ATT&CK Navigator Layers at #{output_layer_path_containers}"
    puts "Generated Atomic Red Team ATT&CK Navigator Layers at #{output_layer_path_google_workspace}"
    puts "Generated Atomic Red Team ATT&CK Navigator Layers at #{output_layer_path_azure_ad}"
    puts "Generated Atomic Red Team ATT&CK Navigator Layers at #{output_layer_path_office_365}"
  end
end

#
# MAIN
#
oks, fails = AtomicRedTeamDocs.new.generate_all_the_docs!

exit fails.count
