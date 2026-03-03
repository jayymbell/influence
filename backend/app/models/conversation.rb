class Conversation < ApplicationRecord
  belongs_to :user
  has_many :messages, dependent: :destroy

  validates :title, length: { maximum: 255 }

  # Auto-generate a title from the first user message if none provided
  def generate_title_from_first_message!
    return if title.present?

    first_msg = messages.where(role: "user").order(:created_at).first
    return unless first_msg

    update!(title: first_msg.content.truncate(100))
  end
end
