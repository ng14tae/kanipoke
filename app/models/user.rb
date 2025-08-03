class User < ApplicationRecord
  authenticates_with_sorcery!

  attr_accessor :password_confirmation

  validates :first_name, presence: true, uniqueness: true
  validates :last_name, presence: true
  validates :last_name, uniqueness: { scope: :first_name, message: "その組み合わせは既に使用されています" }
  validates :password, length: { minimum: 4 }, if: -> { new_record? || changes[:crypted_password] }
  validates :password, confirmation: true, if: -> { new_record? || changes[:crypted_password] }
  validates :password_confirmation, presence: true, if: -> { new_record? || changes[:crypted_password] }

  enum :role, { user: 0, admin: 1 }

  has_many :battles
  has_many :battles_as_opponent, class_name: "Battle", foreign_key: "opponent_id"
  has_many :won_battles, class_name: "Battle", foreign_key: "winner_id"
  has_many :lost_battles, class_name: "Battle", foreign_key: "loser_id"

  def display_name
    "#{first_name}の#{last_name}"
  end

  def name
    display_name  # 既存のdisplay_nameを使用
  end

  def admin?
    role == "admin"
  end

  def all_battles
    Battle.where("user_id = ? OR opponent_id = ?", id, id)
  end

  # 期間指定で全バトルを取得
  def all_battles_since(start_date)
    all_battles.where('created_at >= ?', start_date)
  end

  # 総試合数
  def total_battles_count
    all_battles.count
  end

  # 期間指定での総試合数
  def total_battles_count_since(start_date)
    all_battles_since(start_date).count
  end

  # 勝利数（変更なし - winner_idで正しく集計される）
  def wins_count
    won_battles.count
  end

  # 期間指定での勝利数
  def wins_count_since(start_date)
    won_battles.where('created_at >= ?', start_date).count
  end

  # 敗北数
  def losses_count
    total_battles_count - wins_count
  end

  # 期間指定での敗北数
  def losses_count_since(start_date)
    total_battles_count_since(start_date) - wins_count_since(start_date)
  end

  # 勝率
  def win_rate
    return 0.0 if total_battles_count.zero?
    ((wins_count.to_f / total_battles_count) * 100).round(1)
  end

  # 期間指定での勝率
  def win_rate_since(start_date)
    total = total_battles_count_since(start_date)
    return 0.0 if total.zero?
    ((wins_count_since(start_date).to_f / total) * 100).round(1)
  end

  # バトル経験があるかどうか
  def has_battles?
    total_battles_count > 0
  end

  # 期間指定でバトル経験があるかどうか
  def has_battles_since?(start_date)
    total_battles_count_since(start_date) > 0
  end

end
