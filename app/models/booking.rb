class Booking < ApplicationRecord
  belongs_to :schedule_link
  belongs_to :contact, optional: true

  validates :start_time, presence: true
  validates :end_time, presence: true
  validates :invitee_name, presence: true
  validates :invitee_email, presence: true
  validates :invitee_timezone, presence: true
  validates :status, inclusion: { in: %w[confirmed cancelled] }

  scope :confirmed, -> { where(status: "confirmed") }
end
