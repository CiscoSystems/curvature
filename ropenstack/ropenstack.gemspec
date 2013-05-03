Gem::Specification.new do |s|
	s.name		= 'ropenstack'
	s.version	= '1.2.1'
	s.date		= '2013-01-15'
	s.summary 	= 'Openstack for Ruby'
	s.description 	= 'A Ruby wrapper for all the openstack api calls'
	s.authors	= '["Sam "Tehsmash" Betts"]'
	s.email		= 'sam@code-smash.net'
	s.files		= `git ls-files`.split("\n")
	s.require_paths = ["lib"]
end
