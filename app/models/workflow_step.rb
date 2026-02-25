class WorkflowStep < ApplicationRecord
  belongs_to :workflow

  validates :timing_direction, presence: true, inclusion: { in: %w[before after] }
  validates :timing_minutes, presence: true, numericality: { greater_than: 0 }
  validates :email_subject, presence: true
  validates :email_body, presence: true
  validates :recipient_type, presence: true, inclusion: { in: %w[invitee host all] }
end
