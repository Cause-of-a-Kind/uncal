require "test_helper"

class TimeSlotHelperTest < ActiveSupport::TestCase
  # intersect_ranges

  test "intersect_ranges with two overlapping ranges returns overlap" do
    a = [ [ Time.utc(2026, 3, 4, 9, 0), Time.utc(2026, 3, 4, 12, 0) ] ]
    b = [ [ Time.utc(2026, 3, 4, 10, 0), Time.utc(2026, 3, 4, 14, 0) ] ]

    result = TimeSlotHelper.intersect_ranges(a, b)

    assert_equal 1, result.length
    assert_equal Time.utc(2026, 3, 4, 10, 0), result[0][0]
    assert_equal Time.utc(2026, 3, 4, 12, 0), result[0][1]
  end

  test "intersect_ranges with non-overlapping ranges returns empty" do
    a = [ [ Time.utc(2026, 3, 4, 9, 0), Time.utc(2026, 3, 4, 10, 0) ] ]
    b = [ [ Time.utc(2026, 3, 4, 11, 0), Time.utc(2026, 3, 4, 12, 0) ] ]

    result = TimeSlotHelper.intersect_ranges(a, b)

    assert_empty result
  end

  test "intersect_ranges with multiple ranges on each side" do
    a = [
      [ Time.utc(2026, 3, 4, 9, 0), Time.utc(2026, 3, 4, 11, 0) ],
      [ Time.utc(2026, 3, 4, 13, 0), Time.utc(2026, 3, 4, 16, 0) ]
    ]
    b = [
      [ Time.utc(2026, 3, 4, 10, 0), Time.utc(2026, 3, 4, 14, 0) ]
    ]

    result = TimeSlotHelper.intersect_ranges(a, b)

    assert_equal 2, result.length
    assert_equal [ Time.utc(2026, 3, 4, 10, 0), Time.utc(2026, 3, 4, 11, 0) ], result[0]
    assert_equal [ Time.utc(2026, 3, 4, 13, 0), Time.utc(2026, 3, 4, 14, 0) ], result[1]
  end

  test "intersect_ranges where one range fully contains the other" do
    a = [ [ Time.utc(2026, 3, 4, 9, 0), Time.utc(2026, 3, 4, 17, 0) ] ]
    b = [ [ Time.utc(2026, 3, 4, 10, 0), Time.utc(2026, 3, 4, 12, 0) ] ]

    result = TimeSlotHelper.intersect_ranges(a, b)

    assert_equal 1, result.length
    assert_equal [ Time.utc(2026, 3, 4, 10, 0), Time.utc(2026, 3, 4, 12, 0) ], result[0]
  end

  # subtract_ranges

  test "subtract_ranges removes a middle section splitting the base range" do
    base = [ [ Time.utc(2026, 3, 4, 9, 0), Time.utc(2026, 3, 4, 17, 0) ] ]
    subtract = [ [ Time.utc(2026, 3, 4, 12, 0), Time.utc(2026, 3, 4, 13, 0) ] ]

    result = TimeSlotHelper.subtract_ranges(base, subtract)

    assert_equal 2, result.length
    assert_equal [ Time.utc(2026, 3, 4, 9, 0), Time.utc(2026, 3, 4, 12, 0) ], result[0]
    assert_equal [ Time.utc(2026, 3, 4, 13, 0), Time.utc(2026, 3, 4, 17, 0) ], result[1]
  end

  test "subtract_ranges removes start of base range" do
    base = [ [ Time.utc(2026, 3, 4, 9, 0), Time.utc(2026, 3, 4, 12, 0) ] ]
    subtract = [ [ Time.utc(2026, 3, 4, 8, 0), Time.utc(2026, 3, 4, 10, 0) ] ]

    result = TimeSlotHelper.subtract_ranges(base, subtract)

    assert_equal 1, result.length
    assert_equal [ Time.utc(2026, 3, 4, 10, 0), Time.utc(2026, 3, 4, 12, 0) ], result[0]
  end

  test "subtract_ranges removes end of base range" do
    base = [ [ Time.utc(2026, 3, 4, 9, 0), Time.utc(2026, 3, 4, 12, 0) ] ]
    subtract = [ [ Time.utc(2026, 3, 4, 11, 0), Time.utc(2026, 3, 4, 13, 0) ] ]

    result = TimeSlotHelper.subtract_ranges(base, subtract)

    assert_equal 1, result.length
    assert_equal [ Time.utc(2026, 3, 4, 9, 0), Time.utc(2026, 3, 4, 11, 0) ], result[0]
  end

  test "subtract_ranges with no overlap returns base unchanged" do
    base = [ [ Time.utc(2026, 3, 4, 9, 0), Time.utc(2026, 3, 4, 12, 0) ] ]
    subtract = [ [ Time.utc(2026, 3, 4, 13, 0), Time.utc(2026, 3, 4, 14, 0) ] ]

    result = TimeSlotHelper.subtract_ranges(base, subtract)

    assert_equal 1, result.length
    assert_equal [ Time.utc(2026, 3, 4, 9, 0), Time.utc(2026, 3, 4, 12, 0) ], result[0]
  end

  test "subtract_ranges with complete overlap returns empty" do
    base = [ [ Time.utc(2026, 3, 4, 9, 0), Time.utc(2026, 3, 4, 12, 0) ] ]
    subtract = [ [ Time.utc(2026, 3, 4, 8, 0), Time.utc(2026, 3, 4, 13, 0) ] ]

    result = TimeSlotHelper.subtract_ranges(base, subtract)

    assert_empty result
  end

  test "subtract_ranges with multiple subtractions" do
    base = [ [ Time.utc(2026, 3, 4, 9, 0), Time.utc(2026, 3, 4, 17, 0) ] ]
    subtract = [
      [ Time.utc(2026, 3, 4, 10, 0), Time.utc(2026, 3, 4, 11, 0) ],
      [ Time.utc(2026, 3, 4, 14, 0), Time.utc(2026, 3, 4, 15, 0) ]
    ]

    result = TimeSlotHelper.subtract_ranges(base, subtract)

    assert_equal 3, result.length
    assert_equal [ Time.utc(2026, 3, 4, 9, 0), Time.utc(2026, 3, 4, 10, 0) ], result[0]
    assert_equal [ Time.utc(2026, 3, 4, 11, 0), Time.utc(2026, 3, 4, 14, 0) ], result[1]
    assert_equal [ Time.utc(2026, 3, 4, 15, 0), Time.utc(2026, 3, 4, 17, 0) ], result[2]
  end

  # split_into_slots

  test "split_into_slots divides a range into 30-minute slots on 15-min intervals" do
    ranges = [ [ Time.utc(2026, 3, 4, 9, 0), Time.utc(2026, 3, 4, 11, 0) ] ]

    result = TimeSlotHelper.split_into_slots(ranges, duration_minutes: 30)

    # 15-min interval default: 9:00, 9:15, 9:30, 9:45, 10:00, 10:15, 10:30
    assert_equal 7, result.length
    assert_equal Time.utc(2026, 3, 4, 9, 0), result[0]
    assert_equal Time.utc(2026, 3, 4, 9, 15), result[1]
    assert_equal Time.utc(2026, 3, 4, 10, 30), result.last
  end

  test "split_into_slots starts on 15-minute boundaries" do
    # Range starts at 9:07 — first slot should be 9:15
    ranges = [ [ Time.utc(2026, 3, 4, 9, 7), Time.utc(2026, 3, 4, 10, 30) ] ]

    result = TimeSlotHelper.split_into_slots(ranges, duration_minutes: 30)

    # 9:15, 9:30, 9:45, 10:00 (10:15 would need 10:45 > 10:30)
    assert_equal 4, result.length
    assert_equal Time.utc(2026, 3, 4, 9, 15), result[0]
    assert_equal Time.utc(2026, 3, 4, 10, 0), result.last
  end

  test "split_into_slots drops partial slots that don't fit" do
    # 45 min range, 30 min duration — 9:00 and 9:15 fit, 9:30 would need 10:00 > 9:45
    ranges = [ [ Time.utc(2026, 3, 4, 9, 0), Time.utc(2026, 3, 4, 9, 45) ] ]

    result = TimeSlotHelper.split_into_slots(ranges, duration_minutes: 30)

    assert_equal 2, result.length
    assert_equal Time.utc(2026, 3, 4, 9, 0), result[0]
    assert_equal Time.utc(2026, 3, 4, 9, 15), result[1]
  end

  test "split_into_slots with custom interval" do
    ranges = [ [ Time.utc(2026, 3, 4, 9, 0), Time.utc(2026, 3, 4, 10, 0) ] ]

    result = TimeSlotHelper.split_into_slots(ranges, duration_minutes: 30, interval_minutes: 30)

    assert_equal 2, result.length
    assert_equal Time.utc(2026, 3, 4, 9, 0), result[0]
    assert_equal Time.utc(2026, 3, 4, 9, 30), result[1]
  end

  test "split_into_slots with multiple non-contiguous ranges" do
    ranges = [
      [ Time.utc(2026, 3, 4, 9, 0), Time.utc(2026, 3, 4, 10, 0) ],
      [ Time.utc(2026, 3, 4, 14, 0), Time.utc(2026, 3, 4, 15, 0) ]
    ]

    result = TimeSlotHelper.split_into_slots(ranges, duration_minutes: 30)

    # Each 1-hour range: 3 slots (x:00, x:15, x:30)
    assert_equal 6, result.length
    assert_equal Time.utc(2026, 3, 4, 9, 0), result[0]
    assert_equal Time.utc(2026, 3, 4, 9, 30), result[2]
    assert_equal Time.utc(2026, 3, 4, 14, 0), result[3]
    assert_equal Time.utc(2026, 3, 4, 14, 30), result[5]
  end
end
