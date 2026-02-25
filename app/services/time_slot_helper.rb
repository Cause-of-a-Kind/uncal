module TimeSlotHelper
  module_function

  # Intersect two sets of time ranges using a two-pointer sweep.
  # Each set is an array of [start_time, end_time] pairs, sorted by start_time.
  # Returns overlapping portions.
  def intersect_ranges(ranges_a, ranges_b)
    result = []
    i = 0
    j = 0

    while i < ranges_a.length && j < ranges_b.length
      a_start, a_end = ranges_a[i]
      b_start, b_end = ranges_b[j]

      overlap_start = [ a_start, b_start ].max
      overlap_end = [ a_end, b_end ].min

      result << [ overlap_start, overlap_end ] if overlap_start < overlap_end

      if a_end <= b_end
        i += 1
      else
        j += 1
      end
    end

    result
  end

  # Subtract ranges from base ranges. May split base ranges.
  # Both inputs are arrays of [start_time, end_time] pairs.
  def subtract_ranges(base_ranges, subtract_ranges)
    result = base_ranges.dup

    subtract_ranges.each do |sub_start, sub_end|
      new_result = []

      result.each do |base_start, base_end|
        if sub_end <= base_start || sub_start >= base_end
          # No overlap
          new_result << [ base_start, base_end ]
        else
          # Left remainder
          new_result << [ base_start, sub_start ] if base_start < sub_start
          # Right remainder
          new_result << [ sub_end, base_end ] if sub_end < base_end
        end
      end

      result = new_result
    end

    result
  end

  # Split free ranges into bookable slot start times on interval-minute boundaries.
  # Returns array of start Times where a full duration_minutes meeting fits.
  def split_into_slots(ranges, duration_minutes:, interval_minutes: 15)
    duration = duration_minutes * 60
    interval = interval_minutes * 60
    slots = []

    ranges.each do |range_start, range_end|
      # Snap to next interval boundary
      cursor = ceil_to_interval(range_start, interval)

      while cursor + duration <= range_end
        slots << cursor
        cursor += interval
      end
    end

    slots
  end

  # Round up to the next interval boundary
  def ceil_to_interval(time, interval_seconds)
    epoch = time.to_i
    remainder = epoch % interval_seconds
    return time if remainder == 0
    Time.at(epoch + interval_seconds - remainder).utc
  end
end
