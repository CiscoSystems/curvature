class User < ActiveRecord::Base
  has_many :environments
end
