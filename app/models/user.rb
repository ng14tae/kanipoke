class User < ApplicationRecord
  authenticates_with_sorcery!

  validates :first_name, presence: true, uniqueness: true
  validates :last_name, presence: true
  validates :last_name, uniqueness: { scope: :first_name, message: "その組み合わせは既に使用されています" }
  validates :password, length: { minimum: 4 }, if: -> { new_record? || changes[:crypted_password] }

  enum role: { user: 0, admin: 1 }

  def display_name
    "#{first_name}の#{last_name}"
  end

  def name
    display_name  # 既存のdisplay_nameを使用
  end

  def admin?
    role == "admin"
  end

  has_many :battles
  has_many :battles_as_opponent, class_name: "Battle", foreign_key: "opponent_id"
  has_many :won_battles, class_name: "Battle", foreign_key: "winner_id"
  has_many :lost_battles, class_name: "Battle", foreign_key: "loser_id"
end
