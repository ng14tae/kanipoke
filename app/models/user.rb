class User < ApplicationRecord
  authenticates_with_sorcery!

  attr_accessor :password_confirmation

  validates :first_name, presence: true, uniqueness: true
  validates :last_name, presence: true
  validates :last_name, uniqueness: { scope: :first_name, message: "その組み合わせは既に使用されています" }
  validates :password, length: { minimum: 4 }, if: -> { new_record? || changes[:crypted_password] }
  validates :password, confirmation: true, if: -> { new_record? || changes[:crypted_password] }
  validates :password_confirmation, presence: true, if: -> { new_record? || changes[:crypted_password] }

  enum :role, { user: 0, admin: 1, expert: 2 }

  has_many :battles
  has_many :battles_as_opponent, class_name: "Battle", foreign_key: "opponent_id"
  has_many :won_battles, class_name: "Battle", foreign_key: "winner_id"
  has_many :lost_battles, class_name: "Battle", foreign_key: "loser_id"

  def display_name
    "#{first_name}の#{last_name}"
  end

  def name
    display_name
  end

def expert?
    role == 'expert'
  end

  # 管理者かどうかを判定するメソッド
  def admin?
    role == 'admin'
  end

  # 一般ユーザーかどうかを判定するメソッド
  def general?
    role == 'general' || role.nil?
  end

  def all_battles
    Battle.where("user_id = ? OR opponent_id = ?", id, id)
  end

  # 期間指定で全バトルを取得
  def all_battles_since(start_date)
    all_battles.where('created_at >= ?', start_date)
  end

  # 総試合数
  def total_battles_count_since(start_date)
    return 0 if start_date.nil?

    battles_count = battles.where(created_at: start_date..).count
    opponent_battles_count = battles_as_opponent.where(created_at: start_date..).count

    battles_count + opponent_battles_count
  rescue => e
    Rails.logger.error "Error in total_battles_count_since: #{e.message}"
    0
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

  def total_battles_count
    battles.count
  end

  def total_battles_count_since(start_date)
    battles.where('created_at >= ?', start_date).count
  end

  def has_battles?
    battles.exists?  # より効率的
  end

  def has_battles_since?(start_date)
    battles.where('created_at >= ?', start_date).exists?
  end

  def self.last_week_champion(expert_only: false)
    # 先週の期間を計算
    last_week_start = 1.week.ago.beginning_of_week(:monday).beginning_of_day
    last_week_end = 1.week.ago.end_of_week(:sunday).end_of_day

    # 先週のランキングを構築
    users = includes(:battles, :battles_as_opponent, :won_battles)

    users_with_battles = users.select do |user|
      battles = user.battles.where(created_at: last_week_start..last_week_end) +
                user.battles_as_opponent.where(created_at: last_week_start..last_week_end)
      battles.any?
    end

    # エキスパートのみの場合はフィルタリング
    users_with_battles = users_with_battles.select(&:expert?) if expert_only
    return nil if users_with_battles.empty?

    # 先週の統計を計算してランキング作成
    users_with_stats = users_with_battles.map do |user|
      total_games = user.total_battles_count_since(last_week_start)
      wins = user.wins_count_since(last_week_start)
      losses = user.losses_count_since(last_week_start)
      win_rate = user.win_rate_since(last_week_start)

      # 統計メソッドを動的追加
      user.define_singleton_method(:last_week_total_games) { total_games }
      user.define_singleton_method(:last_week_wins) { wins }
      user.define_singleton_method(:last_week_losses) { losses }
      user.define_singleton_method(:last_week_win_rate) { win_rate }

      user
    end

    # 勝率でソート（同率の場合は勝利数、さらに同じなら総試合数で判定）
    sorted_users = users_with_stats.sort_by do |user|
      [-user.last_week_win_rate, -user.last_week_wins, -user.last_week_total_games]
    end

    sorted_users.first # 1位のユーザーを返す
  end

end
