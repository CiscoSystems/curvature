class User < ActiveRecord::Base
  has_many :environments, dependent: :destroy
end
