#! /usr/bin/env ruby
$LOAD_PATH << "#{File.dirname(File.dirname(__FILE__))}/atomic_red_team" unless $LOAD_PATH.include? "#{File.dirname(File.dirname(__FILE__))}/atomic_red_team"
require 'yaml'
require 'atomic_red_team'

ATOMIC_RED_TEAM = AtomicRedTeam.new
ATOMIC_TEST_TEMPLATE = "#{File.dirname(File.dirname(__FILE__))}/atomic_red_team/atomic_test_template.yaml"
USED_GUIDS_FILE = "#{File.dirname(File.dirname(__FILE__))}/atomics/used_guids.txt"

oks = []
fails = []
unique_guid_array = []

ATOMIC_RED_TEAM.atomic_test_paths.each do |path|
  begin
    print "Validating #{path}..."
    AtomicRedTeam.new.validate_atomic_yaml!(YAML.load_file(path), USED_GUIDS_FILE, unique_guid_array)

    oks << path
    puts "OK"
  rescue => ex
    fails << path
    puts "FAIL\n#{ex}\n"
    # puts "FAIL\n#{ex}\n#{ex.backtrace.join("\n")})"
  end
end

puts
puts "#{oks.count + fails.count} techniques, #{fails.count} failures"

exit fails.count