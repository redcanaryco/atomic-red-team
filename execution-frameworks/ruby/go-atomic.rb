#!/usr/bin/env ruby
#
# USAGE: ./go-atomic.rb -t T1087 -n 'List all accounts' --input-output_file=bar
#
#
# Example output:
#
#
#     ___    __                  _         ____           __   ______
#    /   | / /_____  ____ ___  (_)____   / __ \___  ____/ /  /_  __/__  ____ _____ ___
#   / /| |/ __/ __ \/ __ `__ \/ / ___/  / /_/ / _ \/ __  /    / / / _ \/ __ `/ __ `__ \
#  / ___ / /_/ /_/ / / / / / / / /__   / _, _/  __/ /_/ /    / / /  __/ /_/ / / / / / /
# /_/  |_\__/\____/_/ /_/ /_/_/\___/  /_/ |_|\___/\__,_/    /_/  \___/\__,_/_/ /_/ /_/
#
# ***** EXECUTION PLAN IS *****
#  Technique  T1087
#  Test       List all accounts
#  Inputs     output_file = bar
#             foo = bar
#
#  * Use at your own risk :) *
# ***** ***************** *****
#
# Getting Atomic Tests technique=T1087 from Github repo_org_branch=redcanaryco/master ...
#   - technique has 10 tests
#   - found test named 'List all accounts'
#
# Checking arguments...
#   - supplied on command line: ["output_file", "foo"]
#   - checking for argument name=output_file
#     * OK - found argument in supplied args
#     * using name=output_file value=bar
#
# Checking platform vs our platform (macos)...
#   - OK - our platform is supported!
#
# Interpolating command with input arguments...
#   - interpolating [#{output_file}] => [bar]
#
# Executing executor=sh command=[cat /etc/passwd > bar]
#
# Execution Results:
# **************************************************
#
# **************************************************
#
#
# EXECUTION COMPLETE
#   - Writing results to atomic-test-executor-execution-2018-06-23T04:05:06Z.yaml
#
require 'yaml'
require 'rbconfig'
require 'time'
require 'optparse'
require 'net/http'

class AtomicTestExecutor
  # executes a test and returns the recorded Execution Plan
  def execute!(technique_id:, test_name:, repo_org_branch:, input_args: {})
    puts <<-'EOF'
    ___   __                  _         ____           __   ______                   
   /   | / /_____  ____ ___  (_)____   / __ \___  ____/ /  /_  __/__  ____ _____ ___
  / /| |/ __/ __ \/ __ `__ \/ / ___/  / /_/ / _ \/ __  /    / / / _ \/ __ `/ __ `__ \
 / ___ / /_/ /_/ / / / / / / / /__   / _, _/  __/ /_/ /    / / /  __/ /_/ / / / / / /
/_/  |_\__/\____/_/ /_/ /_/_/\___/  /_/ |_|\___/\__,_/    /_/  \___/\__,_/_/ /_/ /_/

    EOF

    puts "***** EXECUTION PLAN IS *****"
    puts " Technique  #{technique_id}"
    puts " Test       #{test_name}"
    puts " Inputs     #{input_args.collect {|name, val| "#{name} = #{val}\n            "}.join}"
    puts " * Use at your own risk :) *"
    puts "***** ***************** *****"

    # find the test
    test = get_test technique_id: technique_id, test_name: test_name, repo_org_branch: repo_org_branch

    # check our args to make sure we have them all, and get defaults if so
    input_args = check_args_and_get_defaults atomic_test: test, input_args: input_args

    # check if we're on the right platform for the test
    check_platform atomic_test: test

    raise "Test has no executor" unless test.has_key? 'executor'
    test_executor_name = test.fetch('executor').fetch('name')
    supported_executors = ['command_prompt', 'sh', 'bash', 'powershell']
    raise "Executor #{test_executor_name} is not supported" unless supported_executors.include? test_executor_name

    # interpolate our input args into the test's command
    command_to_exec = interpolate_with_args interpolatee: test.fetch('executor').fetch('command').strip,
                                            input_args: input_args

    # run the command and get the results
    executor_results = case test_executor_name
                         when 'command_prompt'
                           execute_command_prompt!(atomic_test: test, command: command_to_exec)
                         when 'sh'
                           execute_sh!(atomic_test: test, command: command_to_exec)
                         when 'bash'
                           execute_bash!(atomic_test: test, command: command_to_exec)
                         when 'powershell'
                           execute_powershell!(atomic_test: test, command: command_to_exec)
                       end

    puts
    puts "Execution Results:\n#{'*' * 50}\n#{executor_results}\n#{'*' * 50}"

    # mix the results into the Atomic Test so we have an "execution plan"
    test.fetch('input_arguments', []).each do |arg, options|
      options['executed_value'] = input_args[arg['name']]
    end
    test.fetch('executor')['executed_command'] = {
        'command' => command_to_exec,
        'results' => executor_results
    }

    # return the execution plan
    test
  end

  private

  def get_test(technique_id:, test_name:, repo_org_branch:)
    repo_org, branch = repo_org_branch.split('/', 2)
    raise "REPO/BRANCH must be in format <repo>/<branch>" unless (repo_org && branch)

    technique_id.upcase!
    technique_id = "T#{technique_id}" unless technique_id.start_with? 'T'

    puts "\nGetting Atomic Tests technique=#{technique_id} from Github repo_org_branch=#{repo_org_branch} ..."
    url = "https://raw.githubusercontent.com/#{repo_org}/atomic-red-team/#{branch}/atomics/#{technique_id}/#{technique_id}.yaml"
    atomic_yaml = YAML.safe_load Net::HTTP.get(URI(url))

    puts "  - technique has #{atomic_yaml['atomic_tests'].count} tests"
    test = atomic_yaml['atomic_tests'].find do |test|
      test['name'] == test_name
    end
    raise "Could not find test #{technique_id}/[#{test_name}]" unless test
    puts "  - found test named '#{test_name}'"
    test
  end

  def check_args_and_get_defaults(atomic_test:, input_args:)
    puts "\nChecking arguments..."
    puts "  - supplied on command line: #{input_args.keys}"
    updated_args = {}
    atomic_test.fetch('input_arguments', []).each do |arg_name, arg_options|
      puts "  - checking for argument name=#{arg_name}"
      arg_value = input_args[arg_name]
      if arg_value
        puts "    * OK - found argument in supplied args"
      else
        puts "    * XX not found, trying default arg"
        arg_value = arg_options['default']
        if arg_value
          puts "    * OK - found argument in defaults"
        else
          raise "Argument [#{arg}] is required but not set and has no default" unless arg_value
        end
      end

      updated_args[arg_name] = arg_value
      puts "    * using name=#{arg_name} value=#{arg_value}"
    end
    updated_args
  end

  # checks our platform vs test supported platforms, raise exception if not
  def check_platform(atomic_test:)
    our_platform = case RbConfig::CONFIG['host_os']
                     when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
                       'windows'
                     when /darwin|mac os/
                       'macos'
                     when /linux|solaris|bsd/
                       'linux'
                   end

    puts "\nChecking platform vs our platform (#{our_platform})..."
    test_supported_platforms = atomic_test['supported_platforms']

    if !test_supported_platforms.include? our_platform
      raise "Unable to run test that supports platforms #{test_supported_platforms} because we are on #{our_platform}"
    end
    puts "  - OK - our platform is supported!"
  end

  def interpolate_with_args(interpolatee:, input_args:)
    puts "\nInterpolating command with input arguments..."
    interpolated = interpolatee
    input_args.each do |name, value|
      puts "  - interpolating [\#{#{name}}] => [#{value}]"
      interpolated = interpolated.gsub("\#{#{name}}", value)
    end
    interpolated
  end

  def execute_command_prompt!(atomic_test:, command:)
    puts "\nExecuting executor=cmd command=[#{command}]"
    command_results = `cmd.exe /c #{command}`
  end

  def execute_sh!(atomic_test:, command:)
    puts "\nExecuting executor=sh command=[#{command}]"
    command_results = `sh -c "#{command}"`
  end

  def execute_bash!(atomic_test:, command:)
    puts "\nExecuting executor=bash command=[#{command}]"
    command_results = `bash -c #{command}`
  end

  def execute_powershell!(atomic_test:, command:)
    puts "\nExecuting executor=powershell command=[#{command}]"
    command_results = `powershell -iex #{command}`
  end
end


cli_args = []
input_args = {}
ARGV.each do |arg|
  if arg.start_with? '--input-'
    name = arg.split('=', 2).first.gsub(/--input-/, '')
    value = arg.split('=', 2).last
    input_args[name] = value
  else
    cli_args << arg
  end
end

options = {
    repo: 'redcanaryco/master'
}
parser = OptionParser.new do |opts|
  opts.banner = "Usage: bin/dataset create <dataset> [options]"

  opts.on('-tTECHNIQUE_ID', '--techniqueTECHNIQUE_ID', 'Technique identifier') do |opt|
    options[:technique_id] = opt
  end

  opts.on('-nTEST_NAME', '--nameTEST_NAME', 'Test name') do |opt|
    options[:test_name] = opt
  end

  opts.on('-rREPO', '--repoREPO', 'Atomic Red Team repo/branch name (ie, redcanaryco/master)') do |opt|
    options[:repo] = opt
  end
end
parser.parse! cli_args

begin
  execution_plan = AtomicTestExecutor.new.execute! technique_id: options[:technique_id],
                                                   test_name: options[:test_name],
                                                   repo_org_branch: options[:repo],
                                                   input_args: input_args

  output_filename = "atomic-test-executor-execution-#{Time.now.utc.iso8601}.yaml"
  puts "\n\nEXECUTION COMPLETE"
  puts "  - Writing results to #{output_filename}"
  File.write(output_filename, YAML.dump(execution_plan))

rescue => ex
  puts "\n\nFATAL ERROR: #{ex.message}"
  puts ex.backtrace.join("\n")
  exit 1
end