#! /usr/bin/env ruby
require 'fileutils'
require 'shellwords'

def usage!
  $stderr.puts "Usage: new_atomic.rb <technique identifier (ex: T1234)>"
  exit 1
end

def template_technique_tests(technique_id=nil)
  template_path = "#{File.dirname(File.dirname(__FILE__))}/atomic_red_team/atomic_test_template.yaml"
  abort "Template not found: #{template_path}" unless File.exist? template_path
  template = File.read template_path
  template.sub!(/attack_technique: TODO/) { "attack_technique: #{technique_id.upcase}" } if technique_id
  template
end

def template_technique_atomic_test
  # hacky way to extract out everything after the "atomic_tests:" element
  # would do this by loading the yaml except that loses any comments we put in the template
  template_technique_tests.sub(/\A.*?^atomic_tests:\n/m, '')
end

technique_id = ARGV[0]
usage! if technique_id.nil?

technique_id = technique_id.upcase
usage! unless technique_id.match?(/\AT\d{4}(\.\d{3})?\z/)
technique_atomic_test_file = "#{File.dirname(File.dirname(__FILE__))}/atomics/#{technique_id}/#{technique_id}.yaml"

if File.exist? technique_atomic_test_file
  puts "Atomic tests for #{technique_id} already exist - adding a new atomic test to the end"
  new_test = template_technique_atomic_test
  File.open(technique_atomic_test_file, 'a') { |f| f.write("\n#{new_test}") }

else
  puts "Atomic tests for #{technique_id} do not already exist - creating from template"
  new_file = template_technique_tests(technique_id)
  FileUtils.mkdir_p File.dirname(technique_atomic_test_file)
  File.open(technique_atomic_test_file, 'w') { |f| f.write(new_file) }
end

# open the file in the default editor
editor = ENV['EDITOR'].to_s.strip
editor = 'vi' if editor.empty?
begin
  exec(*Shellwords.split(editor), technique_atomic_test_file)
rescue SystemCallError => e
  abort "Could not launch editor '#{editor}': #{e.message}"
end
