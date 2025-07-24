class BattlesController < ApplicationController
  def index
  end

  def new
    @battle = Battle.new
    @opponent = User.find(params[:opponent_id])
    @opponents = User.where.not(id: current_user.id)
  end

  def create
  @battle = Battle.new(battle_params)
  retry_count = 0
  max_retries = 3

  # 決着がつくまで最大3回
  max_retries.times do |i|
  @battle.user_card = rand(1..13)
  @battle.opponent_card = rand(1..13)
  retry_count = i + 1

  # 勝敗判定の呼び出し
  winner_user = @battle.determine_winner
  break if winner_user # 勝負がついたら終了
  end

  winner_user = @battle.determine_winner
  message = "戦闘が完了しました！"

    if winner_user.nil?
      # 3回でも引き分け → ランダム決定
      winner_user = [ @battle.user, @battle.opponent ].sample
      message = "#{retry_count}回の引き分けの末、ランダムで#{winner_user.name}の勝利が決定しました！"
    elsif retry_count > 1
      # 再戦があった場合
      message = "#{retry_count}回の激戦の末、#{winner_user.name}の勝利です！"
    end

  # 勝敗を設定
  @battle.winner_id = winner_user.id
  @battle.loser_id = winner_user == @battle.user ? @battle.opponent.id : @battle.user.id

    if @battle.save
      redirect_to @battle, notice: message
    else
      @opponents = User.where.not(id: current_user.id)
      render :new
    end
  end

  def show
    @battle = Battle.find(params[:id])
  end

  private

def battle_params
  params.require(:battle).permit(:opponent_id).merge(user_id: current_user.id)
end
end
