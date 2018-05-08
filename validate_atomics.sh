#! /usr/bin/env ruby
require 'yaml'

oks = []
fails = []

Dir["#{File.dirname(__FILE__)}/atomics/t*/t*.yaml"].sort.each do |path|
  begin
    print "Validating #{path}..."
    YAML.load_file(path)
    oks << path
    puts "OK"
  rescue
    fails << path
    puts "FAIL"
  end
end

puts
puts "#{oks.count + fails.count} techniques, #{fails.count} failures"

exit fails.count