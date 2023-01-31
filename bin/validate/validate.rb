require 'yaml'
require "json"
require "json-schema"


schema_file = File.open("./bin/validate/atomic-red-team.schema.json").read
schema = YAML.load(schema_file)

Dir.glob("./atomics/T*/T*.yaml").each do |atomic_test|
    puts "Attempting to validate Atomic Test #{atomic_test}."
    file = File.open(atomic_test).read
    a_test = YAML.load(file)
    begin
        JSON::Validator.validate!(schema, a_test)
    rescue JSON::Schema::ValidationError => e
        puts e.message
    rescue JSON::Schema::JsonParseError => e
        puts e
    end
    puts "Successfully validated Atomic Test #{atomic_test}."
end
