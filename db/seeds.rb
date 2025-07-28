admin_user = User.create!(
  first_name: "ほげがめ",
  last_name: "てー",
  password: "admin1234",
  password_confirmation: "admin1234",
  role: "admin"
)

# テスト用一般ユーザー
User.create!([
  { first_name: "テスト",
  last_name: "ユーザー",
  password: "1234",
  password_confirmation: "1234",
  role: "user"
  },
  {
  first_name: "ロボ",
  last_name: "らんてくん",
  password: "1234",
  password_confirmation: "1234",
  role: "user"
  },
  {
  first_name: "オレンジ",
  last_name: "金髪校長",
  password: "1234",
  password_confirmation: "1234",
  role: "user"
  },
  {
  first_name: "たし",
  last_name: "かに",
  password: "1234",
  password_confirmation: "1234",
  role: "user"
  }
])
