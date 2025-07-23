class Battle < ApplicationRecord
  belongs_to :user
  belongs_to :opponent, class_name: 'User'

  belongs_to :winner, class_name: 'User', optional: true
  belongs_to :loser, class_name: 'User', optional: true

  validate :cannot_battle_self

def determine_winner
  # 特別ルール：1 vs 13 の場合
  if (user_card == 1 && opponent_card == 13)
    return user
  elsif (opponent_card == 1 && user_card == 13)
    return opponent
  end

  # 通常の大小比較
  if user_card > opponent_card
    user
  elsif opponent_card > user_card
    opponent
  else
    nil # 引き分け
  end
end

  def card_strength(card)
  # 1を14として扱う？
  card == 1 ? 14 : card
end

  private

  def cannot_battle_self
    if user_id == opponent_id
      errors.add(:opponent, "自分以外から対戦相手を選んでください")
    end
  end
end
