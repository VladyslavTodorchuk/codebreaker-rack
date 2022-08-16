
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
      when '/game' then Rack::Response.new(render('game.html.erb'))
      when '/lose' then Rack::Response.new(render('lose.html.erb'))
      when '/start_game' then start_game
      when '/submit_answer' then submit_answer
      when '/receive_hint' then receive_hint
      when '/win' then Rack::Response.new(render('win.html.erb'))
      else
        Rack::Response.new(render('error_404.html.erb'), 404)
      end
    end

    def menu
      @request.session[:rating] = load_file
      Rack::Response.new(render('menu.html.erb'))
    end

    def start_game
      name = @request.params['player_name']
      difficulty = @request.params['level']

      @request.session[:game_obj] = CodeBreaker::CodeBreakerGame.new(name, difficulty)
      @request.session[:hints] = []
      puts @request.session[:game_obj].game.secret_code
      Rack::Response.new { |response| response.redirect("/game") }
    end

    def submit_answer
      begin
        number = @request.params['number'].to_i
        result = @request.session[:game_obj].action(:guess, number)
        @request.session[:result] = result.chars

        if result == '++++'
          @request.session[:rating].rating << { game: @request.session[:game_obj].game,
                                                date: Date.parse(DateTime.now.to_s) }
          save_file
          Rack::Response.new { |response| response.redirect("/win") }
        else
          Rack::Response.new { |response| response.redirect("/game") }
        end
      rescue CodeBreaker::NoAttemptsLeftError => e
        Rack::Response.new { |response| response.redirect("/lose") }
      end
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
      begin
        @request.session[:hints] << @request.session[:game_obj].action(:hint)

        Rack::Response.new { |response| response.redirect("/game") }
      rescue CodeBreaker::NoHintsLeftError => e
        Rack::Response.new { |response| response.redirect("/game") }
      end
    end

    def redirect(address = '')
      Rack::Response.new { |response| response.redirect("/#{address}") }
    end

    def render(template)
      path = File.expand_path("../../../templates/#{template}", __FILE__)
      ERB.new(File.read(path)).result(binding)
    end
  end
end