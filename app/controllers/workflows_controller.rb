class WorkflowsController < ApplicationController
  before_action :set_workflow, only: %i[show edit update destroy toggle]

  def index
    @workflows = Current.user.workflows.order(created_at: :desc)
  end

  def new
    @workflow = Workflow.new
  end

  def create
    @workflow = Current.user.workflows.build(workflow_params)

    if @workflow.save
      redirect_to @workflow, notice: "Workflow created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
  end

  def edit
  end

  def update
    if @workflow.update(workflow_params)
      redirect_to @workflow, notice: "Workflow updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @workflow.destroy!
    redirect_to workflows_path, notice: "Workflow deleted."
  end

  def toggle
    new_state = @workflow.active? ? "inactive" : "active"
    @workflow.update!(state: new_state)
    redirect_to @workflow, notice: "Workflow #{new_state}."
  end

  private

  def set_workflow
    @workflow = Current.user.workflows.find(params[:id])
  end

  def workflow_params
    params.require(:workflow).permit(:name)
  end
end
