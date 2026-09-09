# frozen_string_literal: true

require "officer_neetzsche"
require "rubocop/rspec/support"

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.order = :random
  Kernel.srand config.seed
end
