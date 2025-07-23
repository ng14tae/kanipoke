class User < ApplicationRecord

  authenticates_with_sorcery!

  validates :first_name, presence: true, uniqueness: true
  validates :last_name, presence: true
  validates :password, presence: true, length: { minimum: 4 }

  enum role: { user: 0, admin: 1 }

  def admin?
    role == 'admin'
  end

  has_many :battles
  has_many :battles_as_opponent, class_name: 'Battle', foreign_key: 'opponent_id'

  has_many :won_battles, class_name: 'Battle', foreign_key: 'winner_id'
  has_many :lost_battles, class_name: 'Battle', foreign_key: 'loser_id'
end
