require 'yaml'

begin
  configfile = YAML.load_file("#{Rails.root}/config/curvature.yml")
  APP_CONFIG = file[Rails.env]
rescue
  APP_CONFIG = { :no_config => true }
end
