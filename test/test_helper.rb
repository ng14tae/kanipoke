ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase
  include Sorcery::TestHelpers::Rails::Controller
  fixtures :all
end

class ActionDispatch::IntegrationTest
  include Sorcery::TestHelpers::Rails::Integration
end