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

  # アソシエーション
  has_many :battles
  has_many :battles_as_opponent, class_name: "Battle", foreign_key: "opponent_id"
  has_many :won_battles, class_name: "Battle", foreign_key: "winner_id"
  has_many :lost_battles, class_name: "Battle", foreign_key: "loser_id"

  # 戦績付きでユーザーを取得するスコープ
    scope :with_battle_stats, -> {
    select(
      'users.*',
      '(SELECT COUNT(*) FROM battles WHERE winner_id = users.id) as win_count',
      '(SELECT COUNT(*) FROM battles WHERE loser_id = users.id) as lose_count',
      '((SELECT COUNT(*) FROM battles WHERE winner_id = users.id) +
        (SELECT COUNT(*) FROM battles WHERE loser_id = users.id)) as total_battles',
      'CASE
         WHEN ((SELECT COUNT(*) FROM battles WHERE winner_id = users.id) +
               (SELECT COUNT(*) FROM battles WHERE loser_id = users.id)) = 0 THEN 0
         ELSE ROUND((SELECT COUNT(*) FROM battles WHERE winner_id = users.id) * 100.0 /
              ((SELECT COUNT(*) FROM battles WHERE winner_id = users.id) +
               (SELECT COUNT(*) FROM battles WHERE loser_id = users.id)), 2)
       END as win_rate'
    )
    .group('users.id')  # ←この1行を追加するだけ！
  }

    scope :experienced, -> {
      with_battle_stats.having('((SELECT COUNT(*) FROM battles WHERE winner_id = users.id) +
                              (SELECT COUNT(*) FROM battles WHERE loser_id = users.id)) >= 100')
    }

  # === 表示名関連 ===
  def display_name
    "#{first_name}の#{last_name}"
  end

  def name
    display_name
  end

  # === 権限判定 ===
  def expert?
    role == 'expert'
  end

  def admin?
    role == 'admin'
  end

  def general?
    role == 'user' || role.nil?  # enumに合わせて修正
  end

  # === 基本的な戦績取得 ===
  def all_battles
    Battle.where("user_id = ? OR opponent_id = ?", id, id)
  end

  def all_battles_since(start_date)
    all_battles.where('created_at >= ?', start_date)
  end

  # === 総試合数 ===
  def total_battles_count
    all_battles.count
  end

  def total_battles_count_since(start_date)
    return 0 if start_date.nil?
    all_battles_since(start_date).count
  end

  # === 勝利数 ===
  def wins_count
    won_battles.count
  end

  def wins_count_since(start_date)
    won_battles.where('created_at >= ?', start_date).count
  end

  # === 敗北数 ===
  def losses_count
    total_battles_count - wins_count
  end

  def losses_count_since(start_date)
    total_battles_count_since(start_date) - wins_count_since(start_date)
  end

  # === 勝率 ===
  def win_rate
    return 0.0 if total_battles_count.zero?
    ((wins_count.to_f / total_battles_count) * 100).round(1)
  end

  def win_rate_since(start_date)
    total = total_battles_count_since(start_date)
    return 0.0 if total.zero?
    ((wins_count_since(start_date).to_f / total) * 100).round(1)
  end

  # === 対戦履歴確認 ===
  def has_battles?
    all_battles.exists?
  end

  def has_battles_since?(start_date)
    all_battles_since(start_date).exists?
  end

  # === 今週の統計（便利メソッド） ===
  def weekly_total_games
    start_of_week = Time.current.beginning_of_week(:monday)
    total_battles_count_since(start_of_week)
  end

  def weekly_wins
    start_of_week = Time.current.beginning_of_week(:monday)
    wins_count_since(start_of_week)
  end

  def weekly_losses
    start_of_week = Time.current.beginning_of_week(:monday)
    losses_count_since(start_of_week)
  end

  def weekly_win_rate
    start_of_week = Time.current.beginning_of_week(:monday)
    win_rate_since(start_of_week)
  end

  # === ランキング関連（大幅簡略化） ===
  def self.weekly_ranking(week_start = Time.current.beginning_of_week(:monday))
    User.all.filter_map do |user|
      total_games = user.total_battles_count_since(week_start)
      next if total_games.zero?

      {
        user: user,
        total_games: total_games,
        wins: user.wins_count_since(week_start),
        losses: user.losses_count_since(week_start),
        win_rate: user.win_rate_since(week_start)
      }
    end.sort_by { |stats| [-stats[:win_rate], -stats[:wins], -stats[:total_games]] }
  end

  def self.last_week_champion(expert_only: false)
    # すべてのユーザーをチェック
    all_users = User.all

    candidates = []

    all_users.each do |user|
      # エキスパート限定チェック
      if expert_only && user.total_battles_count < 100
        next
      end

      # 先週の統計を取得（既存のメソッドを使用）
      wins = user.last_week_wins
      losses = user.last_week_losses
      total_games = user.last_week_total_games

      # 先週にバトルがなかったユーザーはスキップ
      next if total_games == 0

      win_rate = user.last_week_win_rate

      candidates << {
        user: user,
        wins: wins,
        losses: losses,
        total_games: total_games,
        win_rate: win_rate
      }
    end

    return nil if candidates.empty?

    # 勝率でソートして最高のユーザーを選択
    best_candidate = candidates.max_by { |c| [c[:win_rate], c[:wins], c[:total_games]] }
    champion = best_candidate[:user]

    champion
  rescue => e
    Rails.logger.error "Error in last_week_champion: #{e.message}"
    nil
  end

  # === 先週の統計（便利メソッド） ===

  def last_week_win_rate
    # 先週の勝率を計算するロジック
    last_week_stats = calculate_last_week_stats
    return 0 if last_week_stats[:total_games] == 0

    (last_week_stats[:wins].to_f / last_week_stats[:total_games] * 100).round(1)
  end

  def last_week_wins
    # 先週の勝利数を取得するロジック
    calculate_last_week_stats[:wins]
  end

  def last_week_losses
    calculate_last_week_stats[:losses]
  end

  def last_week_total_games
    calculate_last_week_stats[:total_games]
  end

  private

  def calculate_last_week_stats
    @last_week_stats ||= begin
      # 現在の週の月曜日を基準に先週を明確に定義
      current_week_start = Time.current.beginning_of_week(:monday)
      last_week_start = current_week_start - 1.week
      last_week_end = current_week_start - 1.day  # 先週の日曜日の終わり

      # デバッグ用ログ（必要に応じて）
      Rails.logger.info "先週の期間: #{last_week_start} 〜 #{last_week_end}"

      # 先週の期間内の戦績を集計
      battles_in_last_week = all_battles.where(created_at: last_week_start..last_week_end)
      wins_in_last_week = battles_in_last_week.where(winner_id: id)

      total_games = battles_in_last_week.count
      wins = wins_in_last_week.count
      losses = total_games - wins

      # デバッグ用ログ
      Rails.logger.info "#{name}の先週の戦績: #{wins}勝#{losses}敗（計#{total_games}戦）"

      { wins: wins, losses: losses, total_games: total_games }
    end
  end
end
