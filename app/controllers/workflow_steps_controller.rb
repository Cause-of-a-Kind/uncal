class WorkflowStepsController < ApplicationController
  before_action :set_workflow

  def show
    @step = @workflow.workflow_steps.find(params[:id])

    sample_data = {
      "invitee_name" => "Jane Smith",
      "invitee_email" => "jane@example.com",
      "meeting_name" => "30-Minute Meeting",
      "meeting_date" => "March 15, 2026",
      "meeting_time" => "2:00 PM",
      "meeting_duration" => "30",
      "meeting_location" => "Zoom",
      "host_names" => "Alex Johnson"
    }

    interpolate = ->(text) { text.gsub(/\{\{(\w+)\}\}/) { sample_data[$1] || "{{#{$1}}}" } }

    @preview_subject = interpolate.call(@step.email_subject)
    @preview_body = MarkdownRenderer.new.to_html(interpolate.call(@step.email_body))
  end

  def edit
    @step = @workflow.workflow_steps.find(params[:id])
  end

  def update
    @step = @workflow.workflow_steps.find(params[:id])

    if @step.update(step_params)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @workflow }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def create
    @step = @workflow.workflow_steps.build(step_params)
    @step.position = @workflow.workflow_steps.maximum(:position).to_i + 1

    if @step.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @workflow }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("step_form", partial: "workflow_steps/form", locals: { workflow: @workflow, step: @step }) }
        format.html { redirect_to @workflow, alert: @step.errors.full_messages.join(", ") }
      end
    end
  end

  def destroy
    @step = @workflow.workflow_steps.find(params[:id])
    @step.destroy!

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @workflow }
    end
  end

  private

  def set_workflow
    @workflow = Current.user.workflows.find(params[:workflow_id])
  end

  def step_params
    params.require(:workflow_step).permit(:timing_direction, :timing_minutes, :email_subject, :email_body, :recipient_type)
  end
end
