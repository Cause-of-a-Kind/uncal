class AvailabilityWindowsController < ApplicationController
  before_action :set_schedule_link
  before_action :require_creator

  def index
    @windows_by_day = @schedule_link.availability_windows
      .order(:start_time)
      .group_by(&:day_of_week)

    @window = AvailabilityWindow.new(schedule_link: @schedule_link)
  end

  def create
    @window = @schedule_link.availability_windows.new(window_params)

    if @window.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to schedule_link_availability_windows_path(@schedule_link) }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace(
          "window_form_day_#{@window.day_of_week}",
          partial: "availability_windows/form",
          locals: { schedule_link: @schedule_link, window: @window }
        ), status: :unprocessable_entity }
        format.html { redirect_to schedule_link_availability_windows_path(@schedule_link), alert: @window.errors.full_messages.join(", ") }
      end
    end
  end

  def destroy
    @window = @schedule_link.availability_windows.find(params[:id])
    @window.destroy

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to schedule_link_availability_windows_path(@schedule_link) }
    end
  end

  def copy
    @other_links = Current.user.created_schedule_links
      .where.not(id: @schedule_link.id)
      .joins(:availability_windows)
      .distinct
  end

  def perform_copy
    source_link = Current.user.created_schedule_links.find(params[:source_link_id])
    source_windows = source_link.availability_windows

    if params[:mode] == "replace"
      @schedule_link.availability_windows.destroy_all
    end

    source_windows.each do |sw|
      existing = @schedule_link.availability_windows.where(
        day_of_week: sw.day_of_week
      )

      overlapping = existing.where("start_time < ? AND end_time > ?", sw.end_time, sw.start_time)
      next if params[:mode] == "merge" && overlapping.exists?

      @schedule_link.availability_windows.create!(
        day_of_week: sw.day_of_week,
        start_time: sw.start_time,
        end_time: sw.end_time
      )
    end

    redirect_to schedule_link_availability_windows_path(@schedule_link),
                notice: "Availability copied successfully."
  end

  private

  def set_schedule_link
    @schedule_link = ScheduleLink.find(params[:schedule_link_id])
  end

  def require_creator
    unless @schedule_link.created_by == Current.user
      redirect_to schedule_links_path, alert: "Not authorized."
    end
  end

  def window_params
    params.require(:availability_window).permit(:day_of_week, :start_time, :end_time)
  end
end
