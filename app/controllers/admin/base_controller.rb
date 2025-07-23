class Admin::BaseController < ApplicationController
  before_action :require_admin_login
  before_action :authenticate_user!
  before_action :ensure_admin

  layout "admin"

  private

  def ensure_admin
    redirect_to root_path unless current_user&.role == "admin"
  end

  def require_admin_login
    # ここで認証に失敗すると、リダイレクトされる可能性があります
  end
end
