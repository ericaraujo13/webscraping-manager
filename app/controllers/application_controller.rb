class ApplicationController < ActionController::Base
  include Authenticable
  before_action :require_login

  allow_browser versions: :modern
  stale_when_importmap_changes
end
