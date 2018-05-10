#! /usr/bin/env ruby
require 'yaml'
require 'ostruct'
require 'erb'
require 'open-uri'
require 'json'

def attack_technique_library
  @attack_json ||= begin
    local_attack_json_to_try = "#{File.dirname(__FILE__)}/enterprise-attack.json"
    if File.exists? local_attack_json_to_try
      JSON.parse File.read(local_attack_json_to_try)
    else
      JSON.parse open('https://raw.githubusercontent.com/mitre/cti/master/enterprise-attack/enterprise-attack.json').read
    end
  end
end

def attack_technique_info(technique_id)
  attack_technique_library.fetch("objects").find do |item| 
    item.fetch('external_references', []).find do |references|
      references['source_name'] == 'mitre-attack' && references['external_id'] == technique_id.upcase
    end
  end
end

def generate_docs!(path)
  atomic_yaml = YAML.load(File.read path)

  technique = attack_technique_info(atomic_yaml.fetch('attack_technique'))
  technique['identifier'] = atomic_yaml.fetch('attack_technique').upcase

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