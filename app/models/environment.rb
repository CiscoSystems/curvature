class Environment < ActiveRecord::Base
  validates :name, uniqueness: true
  belongs_to :user
end
