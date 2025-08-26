RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  # Filter lines from Rails gems in backtraces.
  config.filter_gems_from_backtrace "rails", "rack", "rack-test", "activesupport"
end

