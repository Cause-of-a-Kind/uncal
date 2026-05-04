class GoogleCalendarConnection < ApplicationRecord
  belongs_to :user
  has_many :google_calendar_events, dependent: :destroy

  encrypts :access_token
  encrypts :refresh_token

  before_validation :assign_primary, on: :create

  validates :calendar_id, presence: true
  validates :account_email, uniqueness: { scope: :user_id, conditions: -> { active.where.not(account_email: nil) } }, allow_blank: true
  validate :only_one_active_primary

  scope :active, -> { where(revoked_at: nil) }
  scope :primary_first, -> { order(primary: :desc, created_at: :asc) }

  def active?
    revoked_at.nil?
  end

  def display_name
    account_email.presence || label.presence || "Google Calendar"
  end

  def disconnect!
    transaction do
      update!(revoked_at: Time.current, primary: false, access_token: nil, refresh_token: nil, token_expires_at: nil)
      user.promote_google_calendar_primary!
    end
  end

  private

  def assign_primary
    self.primary = true unless user.google_calendar_connections.active.exists?
  end

  def only_one_active_primary
    return unless primary? && active?

    relation = user.google_calendar_connections.active.where(primary: true)
    relation = relation.where.not(id: id) if persisted?
    errors.add(:primary, "calendar already exists") if relation.exists?
  end
end
