class WorkflowMailer < ApplicationMailer
  def workflow_email(step, booking)
    @step = step
    @booking = booking
    @link = booking.schedule_link

    interpolator = WorkflowInterpolator.new(booking)
    @subject = interpolator.interpolate(step.email_subject)
    @body = interpolator.interpolate(step.email_body)

    recipients = resolve_recipients(step, booking)
    return if recipients.empty?

    mail(to: recipients, subject: @subject)
  end

  private

  def resolve_recipients(step, booking)
    case step.recipient_type
    when "invitee"
      [ booking.invitee_email ]
    when "host"
      booking.schedule_link.members.map(&:email_address)
    when "all"
      [ booking.invitee_email ] + booking.schedule_link.members.map(&:email_address)
    else
      []
    end
  end
end
