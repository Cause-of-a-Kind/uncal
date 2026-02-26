class WorkflowMailerPreview < ActionMailer::Preview
  def workflow_email
    step = WorkflowStep.first
    booking = Booking.find_by(status: "confirmed") || Booking.first
    WorkflowMailer.workflow_email(step, booking)
  end
end
