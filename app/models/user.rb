class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :sent_invitations, class_name: "Invitation", foreign_key: :invited_by_id, dependent: :nullify

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :name, presence: true
  validates :timezone, presence: true, inclusion: { in: ActiveSupport::TimeZone::MAPPING.values }

  encrypts :google_calendar_token
  encrypts :google_calendar_refresh_token
end
