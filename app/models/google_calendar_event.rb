class GoogleCalendarEvent < ApplicationRecord
  belongs_to :booking
  belongs_to :google_calendar_connection

  validates :google_event_id, presence: true
  validates :google_calendar_connection_id, uniqueness: { scope: :booking_id }
end
