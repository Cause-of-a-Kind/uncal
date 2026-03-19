class WorkflowStep < ApplicationRecord
  ALLOWED_VARIABLES = %w[
    invitee_name invitee_email meeting_name meeting_date
    meeting_time meeting_duration meeting_location host_names
  ].freeze

  belongs_to :workflow

  validates :timing_direction, presence: true, inclusion: { in: %w[before after] }
  validates :timing_minutes, presence: true, numericality: { greater_than: 0 }
  validates :email_subject, presence: true
  validates :email_body, presence: true
  validates :recipient_type, presence: true, inclusion: { in: %w[invitee host all] }
  validate :no_unknown_template_variables

  private

  def no_unknown_template_variables
    check_template_variables(:email_subject)
    check_template_variables(:email_body)
  end

  def check_template_variables(attribute)
    value = public_send(attribute)
    return if value.blank?

    unknown = value.scan(/\{\{(\w+)\}\}/).flatten - ALLOWED_VARIABLES
    if unknown.any?
      errors.add(attribute, "contains unknown variable(s): #{unknown.join(', ')}")
    end
  end
end
