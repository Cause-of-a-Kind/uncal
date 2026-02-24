module AvailabilityWindowsHelper
  def time_select_options
    (0..23).flat_map do |hour|
      [ 0, 15, 30, 45 ].map do |minute|
        time_value = format("%02d:%02d", hour, minute)
        time_label = Time.parse(time_value).strftime("%-l:%M %p")
        [ time_label, time_value ]
      end
    end
  end

  DAY_NAMES = %w[Monday Tuesday Wednesday Thursday Friday Saturday Sunday].freeze

  def day_name(day_of_week)
    DAY_NAMES[day_of_week]
  end

  def format_window_time(time)
    time.strftime("%-l:%M %p")
  end
end
