class BattlesController < ApplicationController

  def index
  end

  def new
    @battle = Battle.new
    @opponents = User.where.not(id: current_user.id)
  end

  def create
  @battle = Battle.new(battle_params)
  @battle.user_card = rand(1..13)
  @battle.opponent_card = rand(1..13)

  # 勝敗判定の呼び出し
  winner_user = @battle.determine_winner

  if winner_user
    @battle.winner_id = winner_user.id
    @battle.loser_id = winner_user == @battle.user ? @battle.opponent.id : @battle.user.id
  end
  end

  def show
  end
end
