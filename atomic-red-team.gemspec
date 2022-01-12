# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'atomic-red-team'
  s.version     = '1.0'
  s.authors     = ['Red Canary', 'Casey Smith', 'Mike Haag']
  s.email       = ['it@redcanary.com', 'opensource@redcanary.com']
  s.summary     = 'Small, highly portable, community developed detection tests mapped to ATT&CK.'
  s.license     = "MIT"
  s.homepage    = "https://redcanary.com/atomic-red-team"
  s.files       = %w(atomic-red-team.gemspec) + Dir['{atomic_red_team}/**/*', '*.md', 'bin/*']
  s.test_files  = Dir['spec/**/*']
  s.require_paths = %w(atomic_red_team)

  s.add_development_dependency 'github-pages'
end
