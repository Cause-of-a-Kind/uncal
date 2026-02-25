class Workflow < ApplicationRecord
  belongs_to :user
  has_many :workflow_steps, -> { order(:position) }, dependent: :destroy
  has_many :schedule_links

  validates :name, presence: true
  validates :state, inclusion: { in: %w[active inactive] }

  scope :active, -> { where(state: "active") }

  def active?
    state == "active"
  end
end
