require "test_helper"

class WorkflowEmailJobTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  setup do
    @booking = bookings(:confirmed_one)
    @step = workflow_steps(:reminder_before)
  end

  test "sends email for confirmed booking with active workflow" do
    assert_emails 1 do
      WorkflowEmailJob.perform_now(@step, @booking)
    end
  end

  test "does not send email if booking is cancelled" do
    @booking.update!(status: "cancelled")

    assert_no_emails do
      WorkflowEmailJob.perform_now(@step, @booking)
    end
  end

  test "does not send email if workflow is inactive" do
    @step.workflow.update!(state: "inactive")

    assert_no_emails do
      WorkflowEmailJob.perform_now(@step, @booking)
    end
  end

  test "sends to invitee for invitee recipient type" do
    WorkflowEmailJob.perform_now(@step, @booking)
    email = ActionMailer::Base.deliveries.last
    assert_includes email.to, @booking.invitee_email
  end

  test "sends to hosts for host recipient type" do
    host_step = workflow_steps(:host_reminder)
    WorkflowEmailJob.perform_now(host_step, @booking)
    email = ActionMailer::Base.deliveries.last
    host_emails = @booking.schedule_link.members.map(&:email_address)
    host_emails.each do |addr|
      assert_includes email.to, addr
    end
  end

  test "interpolates variables in subject and body" do
    WorkflowEmailJob.perform_now(@step, @booking)
    email = ActionMailer::Base.deliveries.last
    assert_includes email.subject, "Daily Standup"
    assert_includes email.body.encoded, "Alice Visitor"
  end
end
