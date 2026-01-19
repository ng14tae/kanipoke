class UsersController < ApplicationController
  before_action :require_login, except: [ :new, :create ]
  before_action :set_user, only: [ :show, :edit, :update, :destroy ]

  # Zeitwerk/autoloading が有効でない環境向けにサービスを明示的に読み込む
  begin
    require_dependency Rails.root.join("app/services/user_top_opponents_service.rb")
  rescue LoadError, NameError
    # ignore; autoload may work in other environments
  end

  def index
    @my_win_count = current_user.won_battles.count
    @my_lose_count = current_user.lost_battles.count
    @my_total_battles = @my_win_count + @my_lose_count

    case params[:sort]
    when "experienced_ranking"
      @users = User.experienced
                  .where.not(id: current_user.id)
                  .order("win_rate DESC, total_battles DESC")
                  .page(params[:page])
                  .per(12)

      @sort_type = "\u30A8\u30AD\u30B9\u30D1\u30FC\u30C8\u30E9\u30F3\u30AD\u30F3\u30B0\uFF08\u6226\u7E3E100\u56DE\u4EE5\u4E0A\uFF09"
      @total_experienced_users = @users.total_count

    else
      @users = User.where.not(id: current_user.id)
                  .order(created_at: :asc)
                  .page(params[:page])
                  .per(12)
      @sort_type = "\u767B\u9332\u9806"
    end
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      redirect_to root_path
    else
      render :new
    end
  end

  def show
    # トップ対戦相手はサービスで取得
    @top_opponents = ::UserTopOpponentsService.call(@user, limit: 5)
    @total_battles = Battle.where("user_id = ? OR opponent_id = ?", @user.id, @user.id).count
  end

  def edit
  end

  def update
    if @user.update(user_params)
      redirect_to @user, notice: "プロフィールを更新しました！"
    else
      render :edit
    end
  end

  def destroy
    @user.destroy
    redirect_to users_path, notice: "\u30E6\u30FC\u30B6\u30FC\u3092\u524A\u9664\u3057\u307E\u3057\u305F"
  end

  def weekly_ranking
    @start_date, @end_date = current_week_range  # ← 共通メソッドを使用
    @users = build_ranking_users(@start_date, 10)

    last_week_start, last_week_end = last_week_range  # ← 共通メソッドを使用
    @last_week_champion = User.last_week_champion(
      expert_only: false,
      start_date: last_week_start,
      end_date: last_week_end
    )

    @total_users = User.count
    @active_users_this_week = @users.count
    @average_battles_this_week = @users.empty? ? 0 : (@users.sum(&:weekly_total_games) / @users.count.to_f).round(1)
    @update_time = Time.zone.now
  end

  def experienced_ranking
    @users = build_experienced_ranking_users
    @ranking_type = "\u30A8\u30AD\u30B9\u30D1\u30FC\u30C8\u30E9\u30F3\u30AD\u30F3\u30B0\uFF08\u6226\u7E3E100\u56DE\u4EE5\u4E0A\uFF09"
    render :ranking # rankingビューを再利用
  end

  def expert_weekly_ranking
    # 日本時間での現在日時を取得
    today = Time.zone.now.to_date
    monday_this_week = today.beginning_of_week(:monday)

    # 日本時間での期間設定
    @start_date = Time.zone.parse("#{monday_this_week} 00:00:00")
    @end_date = Time.zone.parse("#{monday_this_week + 6.days} 23:59:59")
    @update_time = Time.zone.now

    # エキスパート専用の今週ランキングを取得
    @users = build_ranking_users(@start_date, 20, expert_only: true)

    @ranking_type = "\u30A8\u30AD\u30B9\u30D1\u30FC\u30C8"
    @period_description = "第#{today.cweek}週（#{@start_date.strftime('%m/%d')}〜#{@end_date.strftime('%m/%d')}）"
    @expert_only = true

    # 先週の期間を正確に設定してエキスパート限定チャンピオン取得
    last_week_start = Time.zone.parse("#{monday_this_week - 7.days} 00:00:00")
    last_week_end = Time.zone.parse("#{monday_this_week - 1.day} 23:59:59")
    @last_week_champion = User.last_week_champion(
      expert_only: true,
      start_date: last_week_start,
      end_date: last_week_end
    )

    render :weekly_ranking
  end

  private

  def build_ranking_users(start_date = nil, limit = nil, expert_only: false)
    # データ規模に合わせた適切なlimit設定
    limit ||= determine_appropriate_limit(start_date, expert_only)

    query = build_ranking_query(start_date, expert_only)

    users_with_stats = query.limit(limit).map do |user|
      add_weekly_stats_methods(user)
      user
    end

    users_with_stats
  end

  def build_experienced_ranking_users
    User.joins(:battles)
        .group("users.id")
        .having("COUNT(battles.id) >= 100")
        .select('users.*,
                COUNT(battles.id) as total_battles,
                SUM(CASE WHEN battles.winner_id = users.id THEN 1 ELSE 0 END) as wins_count,
                ROUND((SUM(CASE WHEN battles.winner_id = users.id THEN 1 ELSE 0 END) * 100.0 / COUNT(battles.id)), 1) as win_rate')
        .order("win_rate DESC, total_battles DESC")
        .limit(20)
        .map { |user| add_total_stats_methods(user) }
  end

  def determine_appropriate_limit(start_date, expert_only)
    if expert_only
      20    # エキスパートユーザー（100戦以上）は少数想定
    elsif start_date
      30    # 週間アクティブユーザー
    else
      50    # 全ユーザー（40人なので全員でもOK）
    end
  end

def build_ranking_query(start_date, expert_only)
  # ユーザーが参加した全試合を取得
  query = User.joins("LEFT JOIN battles ON (battles.user_id = users.id OR battles.opponent_id = users.id)")
              .where("battles.id IS NOT NULL")

  # 期間フィルター（週間ランキングの場合）
  if start_date
    end_date = start_date.end_of_week(:monday).end_of_day
    query = query.where(battles: { created_at: start_date..end_date })
  end

  # グループ化
  query = query.group("users.id")

  # エキスパートのみに絞り込む（全期間100戦以上）
  if expert_only
    # SQLで直接100戦以上を判定（確実な方法）
    expert_ids = ActiveRecord::Base.connection.execute(<<-SQL
      SELECT users.id
      FROM users
      WHERE (
        SELECT COUNT(*)
        FROM battles
        WHERE battles.user_id = users.id OR battles.opponent_id = users.id
      ) >= 100
    SQL
    ).map { |row| row["id"] }

    Rails.logger.info "🔍 Expert user IDs (100+ battles): #{expert_ids.inspect}"

      if expert_ids.any?
        query = query.where("users.id IN (?)", expert_ids)
      else
        # エキスパートが0人の場合は空結果
        return User.none
      end
  end

    # 今週の戦績がある人のみ
    query = query.having("COUNT(battles.id) > 0")

    # 統計情報を選択
    query.select(
      "users.*, " \
      "COUNT(battles.id) as weekly_total_games, " \
      "SUM(CASE WHEN battles.winner_id = users.id THEN 1 ELSE 0 END) as weekly_wins, " \
      "(COUNT(battles.id) - SUM(CASE WHEN battles.winner_id = users.id THEN 1 ELSE 0 END)) as weekly_losses, " \
      "ROUND((SUM(CASE WHEN battles.winner_id = users.id THEN 1 ELSE 0 END) * 100.0 / COUNT(battles.id)), 1) as weekly_win_rate"
    ).order("weekly_win_rate DESC, weekly_total_games DESC")
  end

  def add_weekly_stats_methods(user)
    total = user.read_attribute("weekly_total_games") || 0
    wins = user.read_attribute("weekly_wins") || 0
    losses = user.read_attribute("weekly_losses") || 0
    win_rate = user.read_attribute("weekly_win_rate") || 0.0

    user.define_singleton_method(:weekly_total_games) { total }
    user.define_singleton_method(:weekly_wins) { wins }
    user.define_singleton_method(:weekly_losses) { losses }
    user.define_singleton_method(:weekly_win_rate) { win_rate }
    user
  end

  def add_total_stats_methods(user)
    total = user.read_attribute("total_battles") || 0
    wins = user.read_attribute("wins_count") || 0
    win_rate = user.read_attribute("win_rate") || 0.0

    user.define_singleton_method(:total_battles_count) { total }
    user.define_singleton_method(:wins_count) { wins }
    user.define_singleton_method(:win_rate) { win_rate }
    user
  end

  # 先週の王者を取得する統一メソッド
  def get_last_week_champion(start_date, end_date, expert_only: false)
    last_week_ranking = User.weekly_ranking(start_date)
    return nil if last_week_ranking.blank?

    if expert_only
      last_week_ranking = last_week_ranking.select { |stats| stats[:total_games] >= 100 }
      return nil if last_week_ranking.blank?
    end

    champion_stats = last_week_ranking.first
    return nil unless champion_stats

    # ✅ 安全なユーザー取得
    user_id = champion_stats[:user_id] || champion_stats["user_id"]
    return nil if user_id.blank?

    begin
      champion = User.find(user_id)
    rescue ActiveRecord::RecordNotFound
      Rails.logger.warn "Champion user not found: #{user_id}"
      return nil
    end

    # 統計メソッドの追加
    champion.define_singleton_method(:weekly_wins) { champion_stats[:wins] || 0 }
    champion.define_singleton_method(:weekly_losses) { champion_stats[:losses] || 0 }
    champion.define_singleton_method(:weekly_total_games) { champion_stats[:total_games] || 0 }
    champion.define_singleton_method(:weekly_win_rate) { champion_stats[:win_rate] || 0.0 }

    champion
  rescue => e
    Rails.logger.error "Error in get_last_week_champion: #{e.message}"
    nil
  end

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name, :password, :password_confirmation)
  end

  def current_week_range
    start_date, end_date = User.current_week_range
    [
      Time.zone.parse("#{start_date.to_date} 00:00:00"),
      Time.zone.parse("#{end_date.to_date} 23:59:59")
    ]
  end

  def last_week_range
    start_date, end_date = User.last_week_range
    [
      Time.zone.parse("#{start_date.to_date} 00:00:00"),
      Time.zone.parse("#{end_date.to_date} 23:59:59")
    ]
  end
end
