class ScheduleLink < ApplicationRecord
  belongs_to :created_by, class_name: "User"
  belongs_to :workflow, optional: true
  has_many :schedule_link_members, dependent: :destroy
  has_many :members, through: :schedule_link_members, source: :user
  has_many :availability_windows, dependent: :destroy
  has_many :bookings, dependent: :destroy

  before_validation :generate_slug, on: :create

  validates :name, presence: true
  validates :meeting_name, presence: true
  validates :meeting_duration_minutes, presence: true, numericality: { greater_than: 0 }
  validates :meeting_location_type, presence: true, inclusion: { in: %w[link physical] }
  validates :timezone, presence: true, inclusion: { in: ActiveSupport::TimeZone::MAPPING.values }
  validates :buffer_minutes, numericality: { greater_than_or_equal_to: 0 }
  validates :max_future_days, numericality: { greater_than: 0 }
  validates :max_bookings_per_day, numericality: { greater_than: 0 }, allow_nil: true
  validates :slug, presence: true, uniqueness: true
  validates :status, inclusion: { in: %w[active inactive] }

  scope :active, -> { where(status: "active") }

  private

  def generate_slug
    self.slug ||= loop do
      candidate = SecureRandom.alphanumeric(8).downcase
      break candidate unless ScheduleLink.exists?(slug: candidate)
    end
  end
end
