ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../config/environment', __dir__)
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'

# Maintain test schema (no-op if using db:prepare in CI)
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  config.use_transactional_fixtures = true

  # Infer spec type from file location (models, controllers, etc.)
  config.infer_spec_type_from_file_location!

  # Exclude Rails gems from backtraces
  config.filter_rails_from_backtrace!

  # ActiveJob test helpers for request/job specs
  config.include ActiveJob::TestHelper
  config.before(:each) { ActiveJob::Base.queue_adapter = :test }
end
