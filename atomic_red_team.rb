#! /usr/bin/env ruby
require 'yaml'
require 'erb'
require './attack_api'

class AtomicRedTeam
  ATTACK_API = Attack.new

  # TODO- should these all be relative URLs?
  ROOT_GITHUB_URL = "https://github.com/redcanaryco/atomic-red-team"
  
  #
  # Returns a list of Atomic Tests in Atomic Red Team (as Hashes from source YAML) 
  #
  def atomic_tests
    @atomic_tests ||= Dir["#{File.dirname(__FILE__)}/atomics/t*/t*.yaml"].sort.collect do |path| 
      atomic_yaml = YAML.load(File.read path)
      atomic_yaml['atomic_yaml_path'] = path
      atomic_yaml
    end
  end

  #
  # Returns the individual Atomic Tests for a given identifer, passed as either a string (T1234) or an ATT&CK technique object
  #
  def atomic_tests_for_technique(technique_or_technique_identifier)
    technique_identifier = if technique_or_technique_identifier.is_a? Hash
      ATTACK_API.technique_identifier_for_technique technique_or_technique_identifier
    else
      technique_or_technique_identifier
    end

    atomic_tests.find do |atomic_yaml| 
      atomic_yaml.fetch('attack_technique').downcase == technique_identifier.downcase
    end.to_h.fetch('atomic_tests', [])
  end

  #
  # Returns a Markdown formatted Github link to a technique. This will be to the edit page for 
  # techniques that already have one or more Atomic Red Team tests, or the create page for
  # techniques that have no existing tests.
  #
  def github_link_to_technique(technique, include_identifier=false)
    technique_identifier = ATTACK_API.technique_identifier_for_technique(technique).downcase
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