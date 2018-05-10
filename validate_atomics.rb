#! /usr/bin/env ruby
require 'yaml'

def validate_is_yaml!(path)
  YAML.load_file(path)
rescue
  raise 'Invalid YAML'
end

def validate_is_atomic!(path)
  yaml = YAML.load_file(path)
  raise("YAML file has no elements") if yaml.nil?

  raise('`attack_technique` element is required') unless yaml.has_key?('attack_technique')
  raise('`attack_technique` element must be an array') unless yaml['attack_technique'].is_a?(String)

  raise('`display_name` element is required') unless yaml.has_key?('display_name')
  raise('`display_name` element must be an array') unless yaml['display_name'].is_a?(String)

  raise('`atomic_tests` element is required') unless yaml.has_key?('atomic_tests')
  raise('`atomic_tests` element must be an array') unless yaml['atomic_tests'].is_a?(Array)
  raise('`atomic_tests` element is empty - you have no tests') unless yaml['atomic_tests'].count > 0

  yaml['atomic_tests'].each_with_index do |atomic, i|
    raise("`atomic_tests[#{i}].name` element is required") unless atomic.has_key?('name')
    raise("`atomic_tests[#{i}].name` element must be a string") unless atomic['name'].is_a?(String)

    raise("`atomic_tests[#{i}].description` element is required") unless atomic.has_key?('description')
    raise("`atomic_tests[#{i}].description` element must be a string") unless atomic['description'].is_a?(String)

    raise("`atomic_tests[#{i}].supported_platforms` element is required") unless atomic.has_key?('supported_platforms')
    raise("`atomic_tests[#{i}].supported_platforms` element must be an Array (was a #{atomic['supported_platforms'].class.name})") unless atomic['supported_platforms'].is_a?(Array)

    valid_supported_platforms = ['windows', 'centos', 'ubuntu', 'macos', 'linux']
    atomic['supported_platforms'].each do |platform|
      if !valid_supported_platforms.include?(platform)
        raise("`atomic_tests[#{i}].supported_platforms` '#{platform}' must be one of #{valid_supported_platforms.join(', ')}")
      end
    end

    (atomic['input_arguments'] || {}).each_with_index do |arg_kvp, iai|
      arg_name, arg = arg_kvp
      raise("`atomic_tests[#{i}].input_arguments[#{iai}].description` element is required") unless arg.has_key?('description')
      raise("`atomic_tests[#{i}].input_arguments[#{iai}].description` element must be a string") unless arg['description'].is_a?(String)

      raise("`atomic_tests[#{i}].input_arguments[#{iai}].type` element is required") unless arg.has_key?('type')
      raise("`atomic_tests[#{i}].input_arguments[#{iai}].type` element must be a string") unless arg['type'].is_a?(String)
      raise("`atomic_tests[#{i}].input_arguments[#{iai}].type` element must be lowercased and underscored (was #{arg['type']})") unless arg['type'] =~ /[a-z_]+/

      # TODO: determine if we think default values are required for EVERY input argument
      # raise("`atomic_tests[#{i}].input_arguments[#{iai}].default` element is required") unless arg.has_key?('default')
      # raise("`atomic_tests[#{i}].input_arguments[#{iai}].default` element must be a string (was a #{arg['default'].class.name})") unless arg['default'].is_a?(String)
    end

    raise("`atomic_tests[#{i}].executor` element is required") unless atomic.has_key?('executor')
    executor = atomic['executor']
    raise("`atomic_tests[#{i}].executor.name` element is required") unless executor.has_key?('name')
    raise("`atomic_tests[#{i}].executor.name` element must be a string") unless executor['name'].is_a?(String)
    raise("`atomic_tests[#{i}].executor.name` element must be lowercased and underscored (was #{executor['name']})") unless executor['name'] =~ /[a-z_]+/

    valid_executor_types = ['command_prompt', 'sh', 'bash', 'powershell', 'manual']
    case executor['name']
      when 'manual'
        raise("`atomic_tests[#{i}].executor.steps` element is required") unless executor.has_key?('steps')
        raise("`atomic_tests[#{i}].executor.steps` element must be a string") unless executor['steps'].is_a?(String)

      when 'command_prompt', 'sh', 'bash', 'powershell'
        raise("`atomic_tests[#{i}].executor.command` element is required") unless executor.has_key?('command')
        raise("`atomic_tests[#{i}].executor.command` element must be a string") unless executor['command'].is_a?(String)

      else
        raise("`atomic_tests[#{i}].executor.name` '#{executor['name']}' must be one of #{valid_executor_types.join(', ')}")
    end
  end
end

oks = []
fails = []

(Dir["#{File.dirname(__FILE__)}/atomics/t*/t*.yaml"] + 
 Dir["#{File.dirname(__FILE__)}/atomics/template.yaml"]).sort.each do |path|
  begin
    print "Validating #{path}..."
    validate_is_yaml! path
    validate_is_atomic! path

    puts "OK"
  rescue => ex
    fails << path
    if ENV['DEBUG'] == 'true'
      puts "FAIL (#{ex} #{ex.backtrace.join("\n")})"
    else
      puts "FAIL (#{ex})"
    end
  end
end

puts
puts "#{oks.count + fails.count} techniques, #{fails.count} failures"

exit fails.count