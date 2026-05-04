class CalendarController < ApplicationController
  before_action :require_authentication

  def show
    @team_members = scope_team_members
    @selected_user = selected_user
    @week_start = week_start
    @week_days = (0..6).map { |offset| @week_start + offset.days }
    @busy_blocks = busy_blocks_for(@selected_user)
  end

  private

  def scope_team_members
    User.order(:name)
  end

  def selected_user
    return Current.user if params[:user_id].blank?

    scope_team_members.find(params[:user_id])
  rescue ActiveRecord::RecordNotFound
    Current.user
  end

  def week_start
    date = params[:week].present? ? Date.parse(params[:week]) : Time.current.in_time_zone(Current.user.timezone).to_date
    date.beginning_of_week(:monday)
  rescue ArgumentError
    Time.current.in_time_zone(Current.user.timezone).to_date.beginning_of_week(:monday)
  end

  def busy_blocks_for(user)
    user.active_google_calendar_connections.flat_map do |connection|
      GoogleCalendarService.new(connection).busy_times(@week_start, @week_start + 6.days).map do |busy|
        {
          connection: connection,
          start_time: busy[:start],
          end_time: busy[:end]
        }
      end
    rescue GoogleCalendarService::NotConnectedError, GoogleCalendarService::TokenRevokedError
      []
    end
  end
end
