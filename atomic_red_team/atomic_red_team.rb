require 'yaml'
require 'erb'
require 'attack_api'
require 'securerandom'

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
  def atomic_tests_for_technique_by_platform(technique_or_technique_identifier, platform)
    technique_identifier = if technique_or_technique_identifier.is_a? Hash
      ATTACK_API.technique_identifier_for_technique technique_or_technique_identifier
    else
      technique_or_technique_identifier
    end

    test_list = Array.new
    atomic_tests.find do |atomic_yaml| 
      if atomic_yaml.fetch('attack_technique').upcase == technique_identifier.upcase
        atomic_yaml['atomic_tests'].each do |a_test|
          if a_test["supported_platforms"].include?(platform[:platform])
              test_list.append(a_test)
          end
        end
      end
    end
    test_list
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
  # techniques that have no existing tests for the given OS.
  #
  def github_link_to_technique(technique, include_identifier: false, only_platform: self.only_platform)
    technique_identifier = ATTACK_API.technique_identifier_for_technique(technique).upcase
    link_display = "#{"#{technique_identifier.upcase} " if include_identifier}#{technique['name']}"
    yaml_file = "#{ATOMICS_DIRECTORY}/#{technique_identifier}/#{technique_identifier}.yaml"
    markdown_file = "#{ATOMICS_DIRECTORY}/#{technique_identifier}/#{technique_identifier}.md"

    if atomic_yaml_has_test_for_platform(yaml_file, only_platform) && (File.exists? markdown_file)
      # we have a file for this technique, so link to it's Markdown file
      "[#{link_display}](../../#{technique_identifier}/#{technique_identifier}.md)"
    else
      # we don't have a file for this technique, or there are not tests for the given platform, so link to an edit page
      "#{link_display} [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)"
    end
  end

  def atomic_yaml_has_test_for_platform(yaml_file, only_platform)
    has_test_for_platform = false
    if File.exists? yaml_file
      yaml = YAML.load_file(yaml_file)
      yaml['atomic_tests'].each_with_index do |atomic, i|
        if atomic["supported_platforms"].any? {|platform| platform.downcase =~ only_platform}
          has_test_for_platform = true
          break
        end
      end
    end
    return has_test_for_platform
  end

  def validate_atomic_yaml!(yaml, used_guids_file, unique_guid_array)
    raise("YAML file has no elements") if yaml.nil?
  
    raise('`attack_technique` element is required') unless yaml.has_key?('attack_technique')
    raise('`attack_technique` element must be a string') unless yaml['attack_technique'].is_a?(String)
  
    raise('`display_name` element is required') unless yaml.has_key?('display_name')
    raise('`display_name` element must be an array') unless yaml['display_name'].is_a?(String)
  
    raise('`atomic_tests` element is required') unless yaml.has_key?('atomic_tests')
    raise('`atomic_tests` element must be an array') unless yaml['atomic_tests'].is_a?(Array)
    raise('`atomic_tests` element is empty - you have no tests') unless yaml['atomic_tests'].count > 0
  
    yaml['atomic_tests'].each_with_index do |atomic, i|
      raise("`atomic_tests[#{i}].name` element is required") unless atomic.has_key?('name')
      raise("`atomic_tests[#{i}].name` element must be a string") unless atomic['name'].is_a?(String)

      if atomic.has_key?('auto_generated_guid')
        guid = atomic["auto_generated_guid"].to_s
        raise("`atomic_tests[#{i}].auto_generated_guid` element not a proper guid") unless /[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89aAbB][a-f0-9]{3}-[a-f0-9]{12}/.match(guid)
        raise("`atomic_tests[#{i}].auto_generated_guid` element must be unique") unless !unique_guid_array.include?(guid)
        unique_guid_array << guid
      end

      raise("`atomic_tests[#{i}].description` element is required") unless atomic.has_key?('description')
      raise("`atomic_tests[#{i}].description` element must be a string") unless atomic['description'].is_a?(String)
  
      raise("`atomic_tests[#{i}].supported_platforms` element is required") unless atomic.has_key?('supported_platforms')
      raise("`atomic_tests[#{i}].supported_platforms` element must be an Array (was a #{atomic['supported_platforms'].class.name})") unless atomic['supported_platforms'].is_a?(Array)
  
      valid_supported_platforms = ['windows', 'macos', 'linux', 'office-365', 'azure-ad', 'google-workspace', 'saas', 'iaas', 'containers', 'iaas:aws', 'iaas:azure', 'iaas:gcp']
      atomic['supported_platforms'].each do |platform|
        if !valid_supported_platforms.include?(platform)
          raise("`atomic_tests[#{i}].supported_platforms` '#{platform}' must be one of #{valid_supported_platforms.join(', ')}")
        end
      end

      if atomic['dependencies']
        atomic['dependencies'].each do |dependency|
          raise("`atomic_tests[#{i}].dependencies` '#{dependency}' must be have a description}") unless dependency.has_key?('description')
          raise("`atomic_tests[#{i}].dependencies` '#{dependency}' must be have a prereq_command}") unless dependency.has_key?('prereq_command')
          raise("`atomic_tests[#{i}].dependencies` '#{dependency}' must be have a get_prereq_command}") unless dependency.has_key?('get_prereq_command')
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
  
      valid_executor_types = ['command_prompt', 'sh', 'bash', 'powershell', 'manual', 'aws', 'az', 'gcloud', 'kubectl']
      case executor['name']
        when 'manual'
          raise("`atomic_tests[#{i}].executor.steps` element is required") unless executor.has_key?('steps')
          raise("`atomic_tests[#{i}].executor.steps` element must be a string") unless executor['steps'].is_a?(String)

          validate_input_args_vs_string! input_args: (atomic['input_arguments'] || {}).keys,
                                         string: executor['steps'],
                                         string_description: "atomic_tests[#{i}].executor.steps"

        when 'command_prompt', 'sh', 'bash', 'powershell', 'aws', 'az', 'gcloud', 'kubectl'
          raise("`atomic_tests[#{i}].executor.command` element is required") unless executor.has_key?('command')
          raise("`atomic_tests[#{i}].executor.command` element must be a string") unless executor['command'].is_a?(String)

          validate_input_args_vs_string! input_args: (atomic['input_arguments'] || {}).keys,
                                         string: executor['command'],
                                         string_description: "atomic_tests[#{i}].executor.command"
        else
          raise("`atomic_tests[#{i}].executor.name` '#{executor['name']}' must be one of #{valid_executor_types.join(', ')}")
      end

      validate_no_todos!(atomic, path: "atomic_tests[#{i}]")
    end
  end

  def record_used_guids!(yaml, used_guids_file)
    return unless !yaml.nil?
 
    yaml['atomic_tests'].each_with_index do |atomic, i|
      next unless atomic.has_key?('auto_generated_guid')
      guid = atomic["auto_generated_guid"].to_s
      add_guid_to_used_guid_file(guid, used_guids_file) unless guid == ''
    end
  end

  def generate_guids_for_yaml!(path, used_guids_file)
    text = File.read(path) 
    # add the "auto_generated_guid:" element after the "- name:" element if it isn't already there
    text.gsub!(/(?i)(^([ \t]*-[ \t]*)name:.*$(?!\s*auto_generated_guid))/) { |m| "#{$1}\n#{$2.gsub(/-/," ")}auto_generated_guid:"}
    # fill the "auto_generated_guid:" element in if it doesn't contain a guid
    text.gsub!(/(?i)^([ \t]*auto_generated_guid:)(?!([ \t]*[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89aAbB][a-f0-9]{3}-[a-f0-9]{12})).*$/) { |m| "#{$1} #{get_unique_guid!(used_guids_file)}"}

    File.open(path, "w") { |file| file << text }
  end

  # generates a unique guid and records the guid as having been used by writing it to the used_guids_file
  def get_unique_guid!(used_guids_file)
    new_guid = ''
    20.times do |i| # if it takes more than 20 tries to get a unique guid, there must be something else going on
      new_guid = SecureRandom.uuid
      break unless !is_unique_guid(new_guid, used_guids_file)
    end
    # add this new unique guid to the used guids file
    add_guid_to_used_guid_file(new_guid, used_guids_file) 
    return new_guid
  end

  # add guid to used guid file if it is the proper format and is not already in the file. raises an exception if guid isn't valid
  def add_guid_to_used_guid_file(guid, used_guids_file)
    open(used_guids_file, 'a') { |f|
      raise("the GUID (#{guid}) does not match the required format for the `auto_generated_guid` element") unless /[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89aAbB][a-f0-9]{3}-[a-f0-9]{12}/ =~ guid
      f.puts guid unless !is_unique_guid(guid, used_guids_file)
    }
  end

  def is_unique_guid(guid, used_guids_file)
    return !File.foreach(used_guids_file).grep(/#{guid}/).any?
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
