admin_user = User.create!(
  first_name: "てー",
  last_name: "ほげがめ",
  encrypted_password: "password",
  role: "admin"
)

# テスト用一般ユーザー
User.create!([
  { first_name: "ユーザー",
  last_name: "テスト",
  encrypted_password: "password",
  role: "user"
  },
  {
  first_name: "らんてくん",
  last_name: "ロボ",
  encrypted_password: "password",
  role: "user"
  },
  {
  first_name: "金髪校長",
  last_name: "オレンジ",
  encrypted_password: "password",
  role: "user"
  },
  {
  first_name: "かに",
  last_name: "たし",
  encrypted_password: "password",
  role: "user"
  }
])
