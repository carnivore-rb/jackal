require 'jackal/utils/spec/helpers'

path = File.join(Dir.pwd, 'test', 'specs')

if(File.directory?(path))
  Dir.glob(File.join(path, '*.rb')).each do |spec|
    require spec
  end
else
  raise "No specs directory found: #{path}"
end
