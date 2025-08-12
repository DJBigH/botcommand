class PromptCategory < ApplicationRecord
  has_many :prompts

  validates :name, presence: true, uniqueness: true
end