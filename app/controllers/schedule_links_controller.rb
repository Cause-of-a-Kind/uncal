class ScheduleLinksController < ApplicationController
  before_action :set_schedule_link, only: %i[show edit update destroy]
  before_action :authorize_member, only: %i[edit update destroy]

  def index
    @schedule_links = ScheduleLink.active
      .joins(:schedule_link_members)
      .where(schedule_link_members: { user_id: Current.user.id })
      .or(ScheduleLink.active.where(created_by: Current.user))
      .distinct
      .order(created_at: :desc)
  end

  def show
    @windows_by_member = @schedule_link.availability_windows
      .includes(:user)
      .order(:day_of_week, :start_time)
      .group_by(&:user)
  end

  def new
    @schedule_link = ScheduleLink.new(timezone: Current.user.timezone)
    @users = User.where.not(id: Current.user.id)
  end

  def create
    @schedule_link = ScheduleLink.new(schedule_link_params)
    @schedule_link.created_by = Current.user

    if @schedule_link.save
      @schedule_link.members << Current.user
      add_selected_members
      redirect_to @schedule_link, notice: "Schedule link created."
    else
      @users = User.where.not(id: Current.user.id)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @users = User.where.not(id: Current.user.id)
  end

  def update
    if @schedule_link.update(schedule_link_params)
      sync_members
      redirect_to @schedule_link, notice: "Schedule link updated."
    else
      @users = User.where.not(id: Current.user.id)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @schedule_link.update!(status: "inactive")
    redirect_to schedule_links_path, notice: "Schedule link deactivated."
  end

  private

  def set_schedule_link
    @schedule_link = ScheduleLink.find(params[:id])
  end

  def authorize_member
    unless @schedule_link.created_by == Current.user || @schedule_link.members.include?(Current.user)
      redirect_to schedule_links_path, alert: "Not authorized."
    end
  end

  def schedule_link_params
    params.require(:schedule_link).permit(
      :name, :meeting_name, :meeting_duration_minutes,
      :meeting_location_type, :meeting_location_value,
      :timezone, :buffer_minutes, :max_bookings_per_day,
      :max_future_days
    )
  end

  def add_selected_members
    member_ids = params.dig(:schedule_link, :member_ids)&.reject(&:blank?) || []
    member_ids.each do |user_id|
      @schedule_link.schedule_link_members.create(user_id: user_id) unless user_id.to_i == Current.user.id
    end
  end

  def sync_members
    member_ids = params.dig(:schedule_link, :member_ids)&.reject(&:blank?)&.map(&:to_i) || []
    member_ids << Current.user.id unless member_ids.include?(Current.user.id)

    # Remove members not in the new list
    @schedule_link.schedule_link_members.where.not(user_id: member_ids).destroy_all

    # Add new members
    member_ids.each do |user_id|
      @schedule_link.schedule_link_members.find_or_create_by(user_id: user_id)
    end
  end
end
