class Invitation < ApplicationRecord
  belongs_to :invited_by, class_name: "User"

  normalizes :email, with: ->(e) { e.strip.downcase }

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true

  before_validation :generate_token, on: :create
  before_validation :set_expiry, on: :create

  scope :pending, -> { where(accepted_at: nil).where("expires_at > ?", Time.current) }
  scope :accepted, -> { where.not(accepted_at: nil) }
  scope :expired, -> { where(accepted_at: nil).where("expires_at <= ?", Time.current) }

  def pending?
    accepted_at.nil? && expires_at > Time.current
  end

  def accepted?
    accepted_at.present?
  end

  def expired?
    accepted_at.nil? && expires_at <= Time.current
  end

  def accept!(user_params)
    transaction do
      user = User.new(user_params.merge(email_address: email))
      user.save!
      update!(accepted_at: Time.current)
      user
    end
  end

  private

  def generate_token
    self.token ||= SecureRandom.urlsafe_base64(32)
  end

  def set_expiry
    self.expires_at ||= 7.days.from_now
  end
end
