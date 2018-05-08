#! /usr/bin/env ruby

Dir["/path/to/search/*/.yaml"]

ruby -e "require 'yaml';puts YAML.load_file('./data.yaml')"