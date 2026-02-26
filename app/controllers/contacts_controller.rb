class ContactsController < ApplicationController
  before_action :set_contact, only: %i[show update]

  def index
    @contacts = Current.user.contacts.order(last_booked_at: :desc)
    if params[:q].present?
      query = "%#{params[:q]}%"
      @contacts = @contacts.where("name LIKE ? OR email LIKE ?", query, query)
    end
  end

  def export
    contacts = Current.user.contacts.order(last_booked_at: :desc)
    csv = generate_csv(contacts)
    send_data csv, filename: "contacts.csv", type: "text/csv"
  end

  def show
    @bookings = Booking
      .joins(schedule_link: :schedule_link_members)
      .where(schedule_link_members: { user_id: Current.user.id })
      .where(invitee_email: @contact.email)
      .order(start_time: :desc)
  end

  def update
    @contact.update!(notes: params.require(:contact).permit(:notes)[:notes])
    redirect_to contact_path(@contact), notice: "Notes updated."
  end

  private

  def set_contact
    @contact = Current.user.contacts.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  def generate_csv(contacts)
    require "csv"
    zone = Time.zone

    CSV.generate do |csv|
      csv << [ "Name", "Email", "Total Bookings", "Last Booked", "Notes", "Created At" ]
      contacts.each do |contact|
        csv << [
          contact.name,
          contact.email,
          contact.total_bookings_count,
          contact.last_booked_at&.in_time_zone(zone)&.strftime("%Y-%m-%d %H:%M"),
          contact.notes,
          contact.created_at.in_time_zone(zone).strftime("%Y-%m-%d %H:%M")
        ]
      end
    end
  end
end
