require 'yaml'
require "json"
require "json-schema"


schema_file = File.open("./bin/validate/atomic-red-team.schema.yaml").read
schema = YAML.load(schema_file)

# Validating that the attack_technique property is in the correct format. This is based off of the `format: technique_id` attribute in the schema.

format_proc = -> value {
  raise JSON::Schema::CustomFormatError.new("Must be T1234 format.") unless value.match("T#{/[0-9]/}") or value.match("T#{/[0-9]/}\./[0-9]/")
}
# register the proc for format 'technique_id' for schema
JSON::Validator.register_format_validator("technique_id", format_proc)

Dir.glob("./atomics/T*/T*.yaml").each do |atomic_test|
    puts "Attempting to validate Atomic Test #{atomic_test}."
    file = File.open(atomic_test).read
    a_test = YAML.load(file)
    begin
        JSON::Validator.validate!(schema, a_test)
    rescue JSON::Schema::ValidationError => e
        puts "Error of type '#{e.class}' occurred."
        puts "\n#{e.message}"
    rescue JSON::Schema::JsonParseError => e
        puts e
    end
    JSON::Validator::fully_validate(schema, a_test, :errors_as_objects => true)
    puts "Successfully validated Atomic Test #{atomic_test}."
end
