class UserTopOpponentsService
  def initialize(user, limit: 5)
    @user = user
    @limit = limit
  end

  def call
    id = @user.id

    rows = ActiveRecord::Base.connection.exec_query(<<-SQL.squish)
      SELECT CASE WHEN user_id = #{id} THEN opponent_id ELSE user_id END AS other_id,
            COUNT(*) AS cnt
      FROM battles
      WHERE user_id = #{id} OR opponent_id = #{id}
      GROUP BY other_id
      ORDER BY cnt DESC
      LIMIT #{@limit}
    SQL

    other_ids = rows.map { |r| r["other_id"] }
    users_map = User.where(id: other_ids).index_by(&:id)

    rows.map do |r|
      other_id = r["other_id"]
      total = r["cnt"].to_i

      vs = ActiveRecord::Base.connection.exec_query(<<-SQL.squish).first
        SELECT
          SUM(CASE WHEN winner_id = #{id} THEN 1 ELSE 0 END) AS wins,
          SUM(CASE WHEN winner_id = #{other_id} THEN 1 ELSE 0 END) AS losses,
          SUM(CASE WHEN winner_id IS NULL THEN 1 ELSE 0 END) AS draws
        FROM battles
        WHERE (user_id = #{id} AND opponent_id = #{other_id}) OR (user_id = #{other_id} AND opponent_id = #{id})
      SQL

      {
        user: users_map[other_id],
        total: total,
        wins: vs["wins"].to_i,
        losses: vs["losses"].to_i,
        draws: vs["draws"].to_i
      }
    end
  end

  def self.call(user, limit: 5)
    new(user, limit: limit).call
  end
end
