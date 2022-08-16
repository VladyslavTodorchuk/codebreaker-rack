# frozen_string_literal: true

require 'codebreaker'
require 'erb'
require 'date'

require_relative '../services/load_service'
require_relative '../services/save_service'

module Middlewares
  class Routes
    def self.call(env)
      new(env).response.finish
    end

    def initialize(env)
      @request = Rack::Request.new(env)
    end

    def response
      case @request.path
      when '/' then menu
      when '/statistics' then statistics
      when '/game' then game
      when '/lose' then lose
      when '/leave_game' then leave_game
      when '/start_game' then start_game
      when '/submit_answer' then submit_answer
      when '/receive_hint' then receive_hint
      when '/win' then win
      else Rack::Response.new(render('error_404.html.erb'), 404)
      end
    end

    def leave_game
      return redirect '/' unless @request.session.key?(:game_obj)

      @request.session.delete(:game_obj)

      redirect '/'
    end

    def game
      return redirect '/' unless @request.session.key?(:game_obj)

      Rack::Response.new(render('game.html.erb'))
    end

    def win
      return redirect '/' unless @request.session.key?(:game_obj)

      if @request.session[:game_obj].game.total_attempts > @request.session[:game_obj].game.used_attempts
        return redirect '/game'
      end

      Rack::Response.new(render('win.html.erb'))
    end

    def lose
      return redirect '/' unless @request.session.key?(:game_obj)

      if @request.session[:game_obj].game.total_attempts != @request.session[:game_obj].game.used_attempts
        return redirect '/game'
      end

      Rack::Response.new(render('lose.html.erb'))
    end

    def menu
      @request.session[:rating] = load_file
      Rack::Response.new(render('menu.html.erb'))
    end

    def start_game
      name = @request.params['player_name']
      difficulty = @request.params['level']

      begin
        @request.session[:game_obj] = CodeBreaker::CodeBreakerGame.new(name, difficulty)
        @request.session[:hints] = []
        puts @request.session[:game_obj].game.secret_code
        redirect '/game'
      rescue CodeBreaker::ValidatorError => e
        @request.session[:error] = e
        redirect '/'
      end
    end

    def submit_answer
      result = request_params_game

      if result == '++++'
        add_game_to_rating
        save_file
        redirect '/win'
      end
      redirect '/game'
    rescue CodeBreaker::NoAttemptsLeftError
      redirect '/lose'
    end

    def statistics
      @request.session[:statistics] = @request.session[:rating].all_games
      Rack::Response.new(render('statistics.html.erb'))
    end

    def load_file
      Services::LoadService.new('./storage/data.yml').load
    end

    def save_file
      Services::SaveService.new(@request.session[:rating], './storage/data.yml').save
    end

    def receive_hint
      @request.session[:hints] << @request.session[:game_obj].action(:hint)

      redirect '/game'
    rescue CodeBreaker::NoHintsLeftError
      redirect '/game'
    end

    def add_game_to_rating
      @request.session[:rating].rating << { game: @request.session[:game_obj].game,
                                            date: Date.parse(DateTime.now.to_s) }
    end

    def request_params_game
      number = @request.params['number'].to_i
      result = @request.session[:game_obj].action(:guess, number)
      @request.session[:result] = result.chars

      result
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
