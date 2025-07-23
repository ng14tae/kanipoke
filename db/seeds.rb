admin_user = User.create!(
  first_name: "てー",
  last_name: "ほげがめ",
  encrypted_password: "password",
  role: "admin"
)

# テスト用一般ユーザー
User.create!(
  first_name: "ユーザー",
  last_name: "テスト",
  encrypted_password: "password",
  role: "user"
)

# NPCキャラクター
Character.create!([
  {
    first_name: "らんてくん",
    last_name: "ロボ",
    personality: "cautious",
    description: "論理的思考で慎重に判断するAI"
  },
  {
    first_name: "金髪校長",
    last_name: "オレンジ",
    personality: "balanced",
    description: "教育的配慮でバランス良く対戦"
  },
  {
    first_name: "かに",
    last_name: "たし",
    personality: "random",
    description: "予測不可能な行動を取る謎の存在"
  }
])
