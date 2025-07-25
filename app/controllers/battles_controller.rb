class BattlesController < ApplicationController
  def index
  end

  def new
    @battle = Battle.new
    @opponent = User.find(params[:opponent_id])
    # カードを事前に生成してインスタンス変数に保存
    @user_card = rand(1..13)
    @opponent_card = rand(1..13)
  end

  def create
    @battle = Battle.new(battle_params)

    # hiddenフィールドから受け取ったカード情報を設定
    @battle.user_card = params[:battle][:user_card].to_i
    @battle.opponent_card = params[:battle][:opponent_card].to_i

    retry_count = 0
    max_retries = 3

    # 決着がつくまで最大3回
    max_retries.times do |i|
    if i > 0
      @battle.user_card = rand(1..13)
      @battle.opponent_card = rand(1..13)
    end

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
    params.require(:battle).permit(:opponent_id, :user_card, :opponent_card)
      .merge(user_id: current_user.id)
  end
end
