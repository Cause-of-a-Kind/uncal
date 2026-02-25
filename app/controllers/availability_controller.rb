class AvailabilityController < ApplicationController
  allow_unauthenticated_access

  def show
    @link = ScheduleLink.active.find_by(slug: params[:slug])
    return head :not_found unless @link

    return head :bad_request if params[:date].blank?

    begin
      date = Date.parse(params[:date])
    rescue Date::Error
      return head :bad_request
    end

    timezone_name = params[:timezone].presence || @link.timezone
    timezone = ActiveSupport::TimeZone[timezone_name]
    return head :bad_request unless timezone

    slots = AvailabilityCalculator.new(@link, date).available_slots

    render json: {
      date: date.to_s,
      timezone: timezone_name,
      slots: slots.map { |slot|
        {
          start_time: slot[:start_time].in_time_zone(timezone).iso8601,
          end_time: slot[:end_time].in_time_zone(timezone).iso8601
        }
      }
    }
  end
end
