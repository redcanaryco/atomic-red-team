#! /usr/bin/env ruby
require 'yaml'
require 'fileutils'

def usage!
  $stderr.puts "Usage: new_atomic.rb <technique identifier (ex: T1234)>"
  exit 1
end

def template_technique_tests(technique_id=nil)
  template = File.read "#{File.dirname(File.dirname(__FILE__))}/atomic_red_team/atomic_test_template.yaml"
  template.gsub! /attack_technique: TODO/, "attack_technique: #{technique_id.upcase}" if technique_id
  template
end

def template_technique_atomic_test
  # hacky way to extract out everything after the "atomic_tests:" element
  # would do this by loading the yaml except that loses any comments we put in the template
  template_technique_tests.gsub /.*atomic_tests:\n(.*)/m, '\1'
end

technique_id = ARGV[0]
usage! if technique_id.nil?

technique_id = technique_id.upcase
technique_atomic_test_file = "#{File.dirname(File.dirname(__FILE__))}/atomics/#{technique_id}/#{technique_id}.yaml"

if File.exist? technique_atomic_test_file
  puts "Atomic tests for #{technique_id} already exist - adding a new atomic test to the end"
  File.open(technique_atomic_test_file, 'a') { |f| f.write("\n#{template_technique_atomic_test}") }

else
  puts "Atomic tests for #{technique_id} do not already exist - creating from template"
  FileUtils.mkdir_p File.dirname(technique_atomic_test_file)
  File.open(technique_atomic_test_file, 'w') { |f| f.write(template_technique_tests(technique_id)) }
end

# open the file in the default editor
exec("#{ENV.fetch('EDITOR', 'vi')} '#{technique_atomic_test_file}'")