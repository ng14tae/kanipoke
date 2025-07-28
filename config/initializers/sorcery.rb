Rails.application.config.sorcery.submodules = []

Rails.application.config.sorcery.configure do |config|
  config.user_config do |user|
    user.username_attribute_names = [ :first_name, :last_name ] # またはカスタム
    user.password_attribute_name = :password
    user.crypted_password_attribute_name = :crypted_password
    user.salt_attribute_name = :salt
    user.stretches = 1 if Rails.env.test?
  end

  config.user_class = "User"
end
