class ChatSession < ApplicationRecord
  belongs_to :bot
    has_many :chat_messages
end
