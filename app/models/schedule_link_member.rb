class ScheduleLinkMember < ApplicationRecord
  belongs_to :schedule_link
  belongs_to :user

  validates :user_id, uniqueness: { scope: :schedule_link_id }
end
