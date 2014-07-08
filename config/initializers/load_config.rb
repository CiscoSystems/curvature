require 'yaml'

begin
  configfile = YAML.load_file("#{Rails.root}/config/curvature.yml")
  APP_CONFIG = configfile[Rails.env]
rescue Exception => e
  puts e
  APP_CONFIG = { :no_config => true }
end
