class AvailabilityWindow < ApplicationRecord
  belongs_to :schedule_link

  validates :day_of_week, inclusion: { in: 0..6 }
  validates :start_time, presence: true
  validates :end_time, presence: true

  validate :start_time_before_end_time
  validate :no_overlapping_windows

  private

  def start_time_before_end_time
    return if start_time.blank? || end_time.blank?
    if start_time >= end_time
      errors.add(:start_time, "must be before end time")
    end
  end

  def no_overlapping_windows
    return if schedule_link.blank? || day_of_week.blank? || start_time.blank? || end_time.blank?

    scope = AvailabilityWindow.where(
      schedule_link: schedule_link,
      day_of_week: day_of_week
    )
    scope = scope.where.not(id: id) if persisted?

    overlapping = scope.where("start_time < ? AND end_time > ?", end_time, start_time)
    if overlapping.exists?
      errors.add(:base, "overlaps with an existing availability window")
    end
  end
end
