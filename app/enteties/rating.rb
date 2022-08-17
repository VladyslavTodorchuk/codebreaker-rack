# frozen_string_literal: true

module Entities
  class Rating
    attr_accessor :rating

    def initialize
      @rating = []
    end

    def hell_games
      @rating.select { |hash| hash[:difficulty] == 'hell' }
    end

    def medium_games
      @rating.select { |hash| hash[:difficulty] == 'medium' }
    end

    def easy_games
      @rating.select { |hash| hash[:difficulty] == 'easy' }
    end

    def sort_games(games, top_rating = 1)
      games = games.sort_by! do |elem|
        [elem[:used_attempts], elem[:used_hints], elem[:name]]
      end
      games.uniq { |u| u[:name] }.first(top_rating)
    end

    def all_games
      easy = sort_games(easy_games, 3)
      medium = sort_games(medium_games, 3)
      hell = sort_games(hell_games, 3)

      hell + medium + easy
    end
  end
end
