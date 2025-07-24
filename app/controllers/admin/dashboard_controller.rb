# 各admin controllerで継承
class Admin::DashboardController < Admin::BaseController
  def index
    @users_count = User.count
    @battles_count = Battle.count
  end
end
