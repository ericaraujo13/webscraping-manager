# frozen_string_literal: true

module Authenticable
  extend ActiveSupport::Concern

  included do
    helper_method :current_user, :logged_in?
  end

  def current_user
    return nil unless session[:auth_token].present?
    @current_user ||= session[:user_id] ? { id: session[:user_id], email: session[:user_email], name: session[:user_name] } : nil
  end

  def logged_in?
    current_user.present?
  end

  def require_login
    return if logged_in?
    redirect_to login_path, alert: "Please login to continue."
  end
end
