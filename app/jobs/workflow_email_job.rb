class WorkflowEmailJob < ApplicationJob
  discard_on ActiveJob::DeserializationError

  def perform(step, booking)
    return unless booking.status == "confirmed"
    return unless step.workflow.active?

    WorkflowMailer.workflow_email(step, booking).deliver_now
  end
end
