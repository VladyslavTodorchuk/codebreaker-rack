# frozen_string_literal: true

require 'codebreaker'
require 'erb'
require 'date'

require_relative '../enteties/rating'
require_relative '../services/load_service'
require_relative '../services/save_service'

module Middlewares
  class Routes
    def self.call(env)
      new(env).response.finish
    end

    def initialize(env)
      @request = Rack::Request.new(env)
      @rating = load_file
    end

    def response
      case @request.path
      when '/' then menu
      when '/statistics' then statistics
      when '/game' then game
      when '/rules' then rules
      when '/lose' then lose
      when '/play_again' then play_again
      when '/start_game' then start_game
      when '/submit_answer' then submit_answer
      when '/receive_hint' then receive_hint
      when '/win' then win
      else Rack::Response.new(render('error_404.html.erb'), 404)
      end
    end

    private

    def play_again
      check
      redirect '/'
    end

    def check
      return unless @request.session.key?(:is_win)

      clear_cookies if @request.session[:is_win] || !@request.session[:is_win]
    end

    def rules
      Rack::Response.new(render('rules.html.erb'))
    end

    def game
      return redirect '/' unless @request.session.key?(:game_obj)

      Rack::Response.new(render('game.html.erb'))
    end

    def win
      return redirect '/game' unless @request.session.key?(:is_win)

      return redirect '/' unless @request.session[:is_win]

      Rack::Response.new(render('win.html.erb'))
    end

    def lose
      return redirect '/game' unless @request.session.key?(:is_win)

      return redirect '/' if @request.session[:is_win]

      Rack::Response.new(render('lose.html.erb'))
    end

    def clear_cookies
      @request.session.delete(:game_obj) if @request.session.key?(:game_obj)
      @request.session.delete(:is_win) if @request.session.key?(:is_win)
      @request.session.delete(:result) if @request.session.key?(:result)
    end

    def menu
      return redirect('/game') if @request.session.key?(:game_obj)

      Rack::Response.new(render('menu.html.erb'))
    end

    def start_game
      return redirect '/game' if @request.session.key?(:game_obj) && @request.session.key?(:is_win)

      name = @request.params['player_name']
      difficulty = @request.params['level']

      begin
        initialize_game(name, difficulty)
        redirect '/game'
      rescue CodeBreaker::ValidatorError
        redirect '/'
      end
    end

    def initialize_game(name, difficulty)
      game = CodeBreaker::CodeBreakerGame.new(name, difficulty)
      game.game.used_attempts = 1
      @request.session[:game_obj] = game
      @request.session[:hints] = []
    end

    def submit_answer
      result = request_params_game
      if result == '++++'
        add_game_to_rating
        save_file
        @request.session[:is_win] = true
        return redirect '/win'
      end
      redirect '/game'
    rescue CodeBreaker::NoAttemptsLeftError
      @request.session[:is_win] = false
      redirect '/lose'
    end

    def request_params_game
      number = @request.params['number'].to_i
      result = @request.session[:game_obj].action(:guess, number)
      @request.session[:result] = result.chars
      @request.session[:number] = number

      result
    end

    def statistics
      check
      @request.session[:statistics] = @rating.all_games
      Rack::Response.new(render('statistics.html.erb'))
    end

    def load_file
      Services::LoadService.new('./storage/data.yml').load
    end

    def save_file
      Services::SaveService.new(@rating, './storage/data.yml').save
    end

    def receive_hint
      @request.session[:hints] << @request.session[:game_obj].action(:hint)

      redirect '/game'
    rescue CodeBreaker::NoHintsLeftError
      redirect '/game'
    end

    def add_game_to_rating
      game = @request.session[:game_obj].game
      @rating.rating << {
        name: game.name, difficulty: game.difficulty, total_attempts: game.total_attempts,
        used_attempts: game.used_attempts, total_hints: game.total_hints,
        used_hints: game.used_hints, date: Date.parse(DateTime.now.to_s)
      }
    end

    def render(template)
      path = File.expand_path("../../../templates/#{template}", __FILE__)
      ERB.new(File.read(path)).result(binding)
    end

    def redirect(path)
      Rack::Response.new { |response| response.redirect(path) }
    end
  end
end
