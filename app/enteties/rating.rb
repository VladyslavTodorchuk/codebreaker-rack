# frozen_string_literal: true

module Entities
  class Rating
    attr_accessor :rating

    def initialize
      @rating = []
    end

    def all_games
      sort_games(group_games, 3)
    end

    def group_games
      rating.group_by { |game| game[:difficulty] }
    end

    def sort_games(games_hash, top_rating = 1)
      games_hash.each do |difficulty, games|
        sorted_games = games.sort_by! do |elem|
          [elem[:used_attempts], elem[:used_hints], elem[:user]]
        end
        games_hash[difficulty] = sorted_games.uniq { |u| [u[:user]] }.first(top_rating)
      end
      games_hash
    end
  end
end
