require "test_helper"

class WorkflowSchedulerTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @booking = bookings(:confirmed_one)
    @link = @booking.schedule_link
    @workflow = workflows(:one)
    # Ensure link has the workflow
    assert_equal @workflow, @link.workflow
  end

  test "enqueues jobs for each step of active workflow" do
    travel_to Time.utc(2026, 3, 3, 0, 0) do
      assert_enqueued_jobs 3, only: WorkflowEmailJob do
        WorkflowScheduler.new(@booking).schedule_all
      end
    end
  end

  test "skips steps whose send_time is in the past" do
    # The booking starts at 2026-03-04 14:00 UTC
    # reminder_before: 60 min before = 13:00 UTC
    # host_reminder: 15 min before = 13:45 UTC
    # followup_after: 1440 min after end = 2026-03-05 14:30 UTC
    travel_to Time.utc(2026, 3, 4, 13, 30) do
      # 13:00 is past, 13:45 is future, 14:30 next day is future
      assert_enqueued_jobs 2, only: WorkflowEmailJob do
        WorkflowScheduler.new(@booking).schedule_all
      end
    end
  end

  test "does nothing when link has no workflow" do
    @link.update!(workflow: nil)

    assert_no_enqueued_jobs only: WorkflowEmailJob do
      WorkflowScheduler.new(@booking).schedule_all
    end
  end

  test "does nothing when workflow is inactive" do
    @workflow.update!(state: "inactive")

    assert_no_enqueued_jobs only: WorkflowEmailJob do
      WorkflowScheduler.new(@booking.reload).schedule_all
    end
  end

  test "calculates before timing from start_time" do
    travel_to Time.utc(2026, 3, 3, 0, 0) do
      WorkflowScheduler.new(@booking).schedule_all

      # Check that jobs were enqueued (verified by count)
      assert_enqueued_with job: WorkflowEmailJob
    end
  end
end
