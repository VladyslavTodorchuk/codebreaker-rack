
module Entities
  class Rating
    attr_accessor :rating

    def initialize
      @rating = []
    end

    def hell_games
      @rating.select { |hash| hash[:game].difficulty == 'hell' }
    end

    def medium_games
      @rating.select { |hash| hash[:game].difficulty == 'medium' }
    end

    def easy_games
      @rating.select { |hash| hash[:game].difficulty == 'easy' }
    end

    def sort_games(games, top_rating = 1)
      games = games.sort_by! do |elem|
        [elem[:game].used_attempts, elem[:game].used_hints, elem[:game].name]
      end
      games.uniq { |u| u[:game].name }.first(top_rating)
    end

    def all_games
      easy = sort_games(easy_games, 3)
      medium = sort_games(medium_games, 3)
      hell = sort_games(hell_games, 3)

      hell + medium + easy
    end
  end
end
