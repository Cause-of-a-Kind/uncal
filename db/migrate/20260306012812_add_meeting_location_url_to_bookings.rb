class AddMeetingLocationUrlToBookings < ActiveRecord::Migration[8.1]
  def change
    add_column :bookings, :meeting_location_url, :string
  end
end
