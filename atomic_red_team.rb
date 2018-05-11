#! /usr/bin/env ruby
require 'yaml'
require 'erb'
require './attack_api'


class AtomicRedTeam
  ATTACK_API = Attack.new

  # TODO- should these all be relative URLs?
  ROOT_GITHUB_URL = "https://github.com/redcanaryco/atomic-red-team"
  
  def atomic_tests
    @atomic_tests ||= Dir["#{File.dirname(__FILE__)}/atomics/t*/t*.yaml"].sort.collect do |path| 
      atomic_yaml = YAML.load(File.read path)
      atomic_yaml['atomic_yaml_path'] = path
      atomic_yaml
    end
  end

  def atomic_tests_for_technique(technique_or_technique_identifier)
    technique_identifier = if technique_or_technique_identifier.is_a? Hash
      technique_or_technique_identifier.fetch('external_references', []).find {|refs| refs['source_name'] == 'mitre-attack'}['external_id'].downcase
    else
      technique_or_technique_identifier
    end

    atomic_tests.find do |atomic_yaml| 
      atomic_yaml.fetch('attack_technique').downcase == technique_identifier.downcase
    end.to_h.fetch('atomic_tests', [])
  end

  def github_link_to_technique(technique, include_identifier=false)
    technique_identifier = technique.fetch('external_references', []).find {|refs| refs['source_name'] == 'mitre-attack'}['external_id'].downcase
    link_display = "#{"#{technique_identifier.upcase} " if include_identifier}#{technique['name']}"

    if File.exists? "#{File.dirname(__FILE__)}/atomics/#{technique_identifier}/#{technique_identifier}.md"
      # we have a file for this technique, so link to it's Markdown file
      "[#{link_display}](#{ROOT_GITHUB_URL}/tree/master/atomics/#{technique_identifier}/#{technique_identifier}.md)"
    else
      # we don't have a file for this technique, so link to an edit page
      "[#{link_display}](#{ROOT_GITHUB_URL}/edit/master/atomics/#{technique_identifier}/#{technique_identifier}.md)"
    end
  end
end