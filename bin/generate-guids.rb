#! /usr/bin/env ruby
$LOAD_PATH << "#{File.dirname(File.dirname(__FILE__))}/atomic_red_team" unless $LOAD_PATH.include? "#{File.dirname(File.dirname(__FILE__))}/atomic_red_team"
require 'yaml'
require 'atomic_red_team'

ATOMIC_RED_TEAM = AtomicRedTeam.new
USED_GUIDS_FILE = "#{File.dirname(File.dirname(__FILE__))}/atomics/used_guids.txt"

oks = []
fails = []

ATOMIC_RED_TEAM.atomic_test_paths.each do |path|
  begin
    print "Generating guids #{path}..."
    
    ATOMIC_RED_TEAM.record_used_guids!(YAML.load_file(path), USED_GUIDS_FILE)
    AtomicRedTeam.new.generate_guids_for_yaml!(path, USED_GUIDS_FILE)

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