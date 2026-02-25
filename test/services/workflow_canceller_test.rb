require "test_helper"

class WorkflowCancellerTest < ActiveSupport::TestCase
  test "does not raise when no SolidQueue jobs exist" do
    booking = bookings(:confirmed_one)
    assert_nothing_raised do
      WorkflowCanceller.new(booking).cancel_all
    end
  end

  test "does not raise for any booking" do
    booking = bookings(:cancelled_one)
    assert_nothing_raised do
      WorkflowCanceller.new(booking).cancel_all
    end
  end
end
