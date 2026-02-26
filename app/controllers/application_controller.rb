class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  around_action :set_time_zone, if: -> { Current.user }

  private

  def set_time_zone(&block)
    Time.use_zone(Current.user.timezone, &block)
  end

  def render_not_found
    head :not_found
  end
end
