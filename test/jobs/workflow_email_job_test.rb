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

  test "renders markdown in HTML email part" do
    @step.update!(email_body: "Hi **{{invitee_name}}**, your meeting is coming up.")
    WorkflowEmailJob.perform_now(@step, @booking)
    email = ActionMailer::Base.deliveries.last
    html = email.html_part.body.to_s
    assert_includes html, "<strong>"
    assert_includes html, "Alice Visitor"
    refute_includes html, "**"
  end

  test "text email part preserves markdown syntax" do
    @step.update!(email_body: "Hi **{{invitee_name}}**, click [here](https://example.com)")
    WorkflowEmailJob.perform_now(@step, @booking)
    email = ActionMailer::Base.deliveries.last
    text = email.text_part.body.to_s
    assert_includes text, "Alice Visitor"
    assert_includes text, "**"
  end
end
