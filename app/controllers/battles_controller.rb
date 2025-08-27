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

    # 引き分けの場合はユーザーカードを変更（見えないので問題なし）
    if @battle.user_card == @battle.opponent_card
      available_user_cards = (1..13).to_a - [@battle.opponent_card]
      @battle.user_card = available_user_cards.sample
    end

    # 勝敗判定（引き分けは発生しない）
    winner_user = @battle.determine_winner
    message = "戦闘が完了しました！#{winner_user.name}の勝利です！"

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
