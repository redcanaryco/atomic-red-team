#! /usr/bin/env ruby
require 'yaml'
require 'ostruct'
require 'erb'

def generate_docs!(path)
  atomic_yaml = YAML.load(File.read path)

  technique = {
    # TODO GET FROM MITRE
    'identifier' => "T1234",
    'name' => "Create Account",
  }

  template = ERB.new File.read("#{File.dirname(__FILE__)}/atomics/atomic_doc_template.md.erb"), nil, "-"
  generated_doc = template.result(binding)

  output_doc_path = path.gsub(/.yaml/, '.md')
  print " => #{output_doc_path} => "
  File.write output_doc_path, generated_doc
end

oks = []
fails = []

Dir["#{File.dirname(__FILE__)}/atomics/t*/t*.yaml"].sort.each do |path|
  begin
    print "Generating docs for #{path}"
    generate_docs! path
    puts "OK"
  rescue => ex
    fails << path
    puts "FAIL (#{ex} #{ex.backtrace.join("\n")})"
  end
end

puts
puts "Generated docs for #{oks.count} techniques, #{fails.count} failures"

exit fails.count