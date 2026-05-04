class User < ApplicationRecord
  has_secure_password

  before_destroy :prevent_owner_destruction

  has_many :sessions, dependent: :destroy
  has_many :sent_invitations, class_name: "Invitation", foreign_key: :invited_by_id, dependent: :nullify
  has_many :schedule_link_members, dependent: :destroy
  has_many :schedule_links, through: :schedule_link_members
  has_many :created_schedule_links, class_name: "ScheduleLink", foreign_key: :created_by_id, dependent: :destroy

  has_many :contacts, dependent: :destroy
  has_many :workflows, dependent: :destroy
  has_many :google_calendar_connections, dependent: :destroy
  has_many :google_calendar_events, through: :google_calendar_connections

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :name, presence: true
  validates :timezone, presence: true, inclusion: { in: ActiveSupport::TimeZone::MAPPING.values }

  encrypts :google_calendar_token
  encrypts :google_calendar_refresh_token

  def active_google_calendar_connections
    google_calendar_connections.active.primary_first
  end

  def primary_google_calendar_connection
    active_google_calendar_connections.find_by(primary: true) || active_google_calendar_connections.first
  end

  def google_calendar_connected?
    primary_google_calendar_connection.present? || google_calendar_connected
  end

  def promote_google_calendar_primary!
    return if google_calendar_connections.active.where(primary: true).exists?

    replacement = google_calendar_connections.active.order(:created_at).first
    replacement&.update!(primary: true)
  end

  private

  def prevent_owner_destruction
    if owner?
      errors.add(:base, "Owner account cannot be deleted")
      throw :abort
    end
  end
end
