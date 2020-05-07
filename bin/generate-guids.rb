#! /usr/bin/env ruby
$LOAD_PATH << "#{File.dirname(File.dirname(__FILE__))}/atomic_red_team" unless $LOAD_PATH.include? "#{File.dirname(File.dirname(__FILE__))}/atomic_red_team"
require 'yaml'
require 'atomic_red_team'

ATOMIC_RED_TEAM = AtomicRedTeam.new
ATOMIC_TEST_TEMPLATE = "#{File.dirname(File.dirname(__FILE__))}/atomic_red_team/atomic_test_template.yaml"

oks = []
fails = []

ATOMIC_RED_TEAM.atomic_test_paths.each do |path|
  begin
    print "Validating #{path}..."
    YAML.load_file(path)
    AtomicRedTeam.new.generate_guids_for_yaml! path

    oks << path
    puts "OK"
  rescue => ex
    fails << path
    puts "FAIL\n#{ex}\n"
  end
end

puts
puts "#{oks.count + fails.count} techniques, #{fails.count} failures"

exit fails.count