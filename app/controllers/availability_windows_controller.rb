class AvailabilityWindowsController < ApplicationController
  before_action :set_schedule_link
  before_action :authorize_member

  def index
    @selected_user = if creator? && params[:user_id].present?
      @schedule_link.members.find_by(id: params[:user_id]) || Current.user
    else
      Current.user
    end

    @windows_by_day = @schedule_link.availability_windows
      .where(user: @selected_user)
      .order(:start_time)
      .group_by(&:day_of_week)

    @window = AvailabilityWindow.new(schedule_link: @schedule_link, user: @selected_user)
  end

  def create
    @window = @schedule_link.availability_windows.new(window_params)
    @window.user = resolve_user

    if @window.save
      @selected_user = @window.user
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to schedule_link_availability_windows_path(@schedule_link, user_id: @selected_user.id) }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace(
          "window_form_day_#{@window.day_of_week}",
          partial: "availability_windows/form",
          locals: { schedule_link: @schedule_link, window: @window, selected_user: @window.user }
        ), status: :unprocessable_entity }
        format.html { redirect_to schedule_link_availability_windows_path(@schedule_link), alert: @window.errors.full_messages.join(", ") }
      end
    end
  end

  def destroy
    @window = @schedule_link.availability_windows.find(params[:id])
    authorize_window_owner(@window)
    day_of_week = @window.day_of_week
    @selected_user = @window.user
    @window.destroy

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to schedule_link_availability_windows_path(@schedule_link, user_id: @selected_user.id) }
    end
  end

  def copy
    @selected_user = resolve_selected_user
    @other_links = Current.user.schedule_links
      .where.not(id: @schedule_link.id)
      .joins(:availability_windows)
      .where(availability_windows: { user_id: @selected_user.id })
      .distinct
  end

  def perform_copy
    @selected_user = resolve_selected_user
    source_link = Current.user.schedule_links.find(params[:source_link_id])
    source_windows = source_link.availability_windows.where(user: @selected_user)

    if params[:mode] == "replace"
      @schedule_link.availability_windows.where(user: @selected_user).destroy_all
    end

    source_windows.each do |sw|
      existing = @schedule_link.availability_windows.where(
        user: @selected_user,
        day_of_week: sw.day_of_week
      )

      overlapping = existing.where("start_time < ? AND end_time > ?", sw.end_time, sw.start_time)
      next if params[:mode] == "merge" && overlapping.exists?

      @schedule_link.availability_windows.create!(
        user: @selected_user,
        day_of_week: sw.day_of_week,
        start_time: sw.start_time,
        end_time: sw.end_time
      )
    end

    redirect_to schedule_link_availability_windows_path(@schedule_link, user_id: @selected_user.id),
                notice: "Availability copied successfully."
  end

  private

  def set_schedule_link
    @schedule_link = ScheduleLink.find(params[:schedule_link_id])
  end

  def authorize_member
    unless @schedule_link.created_by == Current.user || @schedule_link.members.include?(Current.user)
      redirect_to schedule_links_path, alert: "Not authorized."
    end
  end

  def authorize_window_owner(window)
    unless creator? || window.user == Current.user
      redirect_to schedule_link_availability_windows_path(@schedule_link), alert: "Not authorized."
    end
  end

  def creator?
    @schedule_link.created_by == Current.user
  end

  def resolve_user
    if creator? && params.dig(:availability_window, :user_id).present?
      user = @schedule_link.members.find_by(id: params[:availability_window][:user_id])
      user || Current.user
    else
      Current.user
    end
  end

  def resolve_selected_user
    if creator? && params[:user_id].present?
      @schedule_link.members.find_by(id: params[:user_id]) || Current.user
    else
      Current.user
    end
  end

  def window_params
    params.require(:availability_window).permit(:day_of_week, :start_time, :end_time)
  end
end
