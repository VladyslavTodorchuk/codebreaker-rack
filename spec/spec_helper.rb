# frozen_string_literal: true

require 'simplecov'
require 'codebreaker'
require 'rack/test'

require_relative '../app/enteties/rating'
require_relative '../app/services/load_service'
require_relative '../app/services/save_service'
require_relative '../app/middlewares/routes'

SimpleCov.start do
  minimum_coverage 95
end
