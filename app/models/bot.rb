class Bot < ApplicationRecord
    has_many :prompts, dependent: :destroy
end
