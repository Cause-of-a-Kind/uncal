class WorkflowScheduler
  def initialize(booking)
    @booking = booking
    @link = booking.schedule_link
  end

  def schedule_all
    workflow = @link.workflow
    return unless workflow&.active?

    workflow.workflow_steps.each do |step|
      send_time = calculate_send_time(step)
      next if send_time <= Time.current

      WorkflowEmailJob.set(wait_until: send_time).perform_later(step, @booking)
    end
  end

  private

  def calculate_send_time(step)
    if step.timing_direction == "before"
      @booking.start_time - step.timing_minutes.minutes
    else
      @booking.end_time + step.timing_minutes.minutes
    end
  end
end
