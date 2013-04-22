require 'yaml'

APP_CONFIG = YAML.load_file("#{Rails.root}/config/curvature.yml")[Rails.env]
