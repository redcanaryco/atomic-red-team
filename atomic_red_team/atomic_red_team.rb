require 'yaml'
require 'erb'
require 'attack_api'

class AtomicRedTeam
  ATTACK_API = Attack.new

  ATOMICS_DIRECTORY = "#{File.dirname(File.dirname(__FILE__))}/atomics"

  # TODO- should these all be relative URLs?
  ROOT_GITHUB_URL = "https://github.com/redcanaryco/atomic-red-team"
  
  #
  # Returns a list of paths that contain Atomic Tests
  #
  def atomic_test_paths
    Dir["#{ATOMICS_DIRECTORY}/T*/T*.yaml"].sort
  end

  #
  # Returns a list of Atomic Tests in Atomic Red Team (as Hashes from source YAML) 
  #
  def atomic_tests
    @atomic_tests ||= atomic_test_paths.collect do |path| 
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
      atomic_yaml.fetch('attack_technique').upcase == technique_identifier.upcase
    end.to_h.fetch('atomic_tests', [])
  end

  #
  # Returns a Markdown formatted Github link to a technique. This will be to the edit page for 
  # techniques that already have one or more Atomic Red Team tests, or the create page for
  # techniques that have no existing tests.
  #
  def github_link_to_technique(technique, include_identifier: false, link_new_to_contrib: true)
    technique_identifier = ATTACK_API.technique_identifier_for_technique(technique).upcase
    link_display = "#{"#{technique_identifier.upcase} " if include_identifier}#{technique['name']}"

    if File.exists? "#{ATOMICS_DIRECTORY}/#{technique_identifier}/#{technique_identifier}.md"
      # we have a file for this technique, so link to it's Markdown file
      "[#{link_display}](./#{technique_identifier}/#{technique_identifier}.md)"
    else
      # we don't have a file for this technique, so link to an edit page
      "#{link_display} [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)"
    end
  end

  ATOMIC_TEMPLATE_FILENAME = "atomic_test_template.yaml"

  def validate_atomic_yaml!(file_path)
    yaml = YAML.load_file(file_path)

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

          validate_input_args_vs_string! input_args: (atomic['input_arguments'] || {}).keys,
                                         string: executor['steps'],
                                         string_description: "atomic_tests[#{i}].executor.steps"

        when 'command_prompt', 'sh', 'bash', 'powershell'
          raise("`atomic_tests[#{i}].executor.command` element is required") unless executor.has_key?('command')
          raise("`atomic_tests[#{i}].executor.command` element must be a string") unless executor['command'].is_a?(String)

          validate_input_args_vs_string! input_args: (atomic['input_arguments'] || {}).keys,
                                         string: executor['command'],
                                         string_description: "atomic_tests[#{i}].executor.command"
        else
          raise("`atomic_tests[#{i}].executor.name` '#{executor['name']}' must be one of #{valid_executor_types.join(', ')}")
      end

      validate_no_todos!(atomic, path: "atomic_tests[#{i}]") unless file_path.end_with? ATOMIC_TEMPLATE_FILENAME
    end
  end

  #
  # Validates that the arguments (specified in "#{arg}" format) in a string
  # match the input_arguments for a test
  #
  def validate_input_args_vs_string!(input_args:, string:, string_description:)
    input_args_in_string = string.scan(/#\{([^}]+)\}/).to_a.flatten

    input_args_in_string_and_not_specced = input_args_in_string - input_args
    if input_args_in_string_and_not_specced.count > 0
      raise("`#{string_description}` contains args #{input_args_in_string_and_not_specced} not in input_arguments")
    end

    input_args_in_spec_not_string = input_args - input_args_in_string
    if input_args_in_string_and_not_specced.count > 0
      raise("`atomic_tests[#{i}].input_arguments` contains args #{input_args_in_spec_not_string} not in command")
    end
  end

  #
  # Recursively validates that the hash (or something) doesn't contain a TODO
  #
  def validate_no_todos!(hashish, path:)
    if hashish.is_a? String
      raise "`#{path}` contains a TODO" if hashish.include? 'TODO'
    elsif hashish.is_a? Array
      hashish.each_with_index do |item, i|
        validate_no_todos! item, path: "#{path}[#{i}]"
      end
    elsif hashish.is_a? Hash
      hashish.each do |k, v|
        validate_no_todos! v, path: "#{path}.#{k}"
      end
    end
  end
end
