# frozen_string_literal: true

require_relative '../enteties/rating'
require 'yaml'

module Services
  class LoadService
    attr_accessor :yml_file

    def initialize(yml_file)
      @yml_file = yml_file
    end

    def load
      YAML.load_file(@yml_file,
                     permitted_classes: [Entities::Rating, CodeBreaker::Game, Symbol, Date],
                     aliases: true)
    end
  end
end
