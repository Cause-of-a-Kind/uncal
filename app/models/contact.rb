class Contact < ApplicationRecord
  belongs_to :user

  normalizes :email, with: ->(e) { e.strip.downcase }

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { scope: :user_id }
end
