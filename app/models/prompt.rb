class Prompt < ApplicationRecord
  belongs_to :bot
  # Nếu bạn muốn liên kết danh mục:
  belongs_to :prompt_category, optional: true # nếu có prompt_category_id

  delegate :name, to: :category, prefix: true, allow_nil: true
end