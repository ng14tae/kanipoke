# 各admin controllerで継承
class Admin::DashboardController < Admin::BaseController
  def index
    @users_count = User.count
    @characters_count = Character.count
    @battles_count = Battle.count
  end
end