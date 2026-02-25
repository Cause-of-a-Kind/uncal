class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :sent_invitations, class_name: "Invitation", foreign_key: :invited_by_id, dependent: :nullify
  has_many :schedule_link_members, dependent: :destroy
  has_many :schedule_links, through: :schedule_link_members
  has_many :created_schedule_links, class_name: "ScheduleLink", foreign_key: :created_by_id, dependent: :destroy
  has_many :availability_windows, dependent: :destroy
  has_many :contacts, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :name, presence: true
  validates :timezone, presence: true, inclusion: { in: ActiveSupport::TimeZone::MAPPING.values }

  encrypts :google_calendar_token
  encrypts :google_calendar_refresh_token
end
