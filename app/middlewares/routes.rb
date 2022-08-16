
require 'codebreaker'
require 'erb'

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
      when '/' then Rack::Response.new(render('menu.html.erb'))
      when '/statistics' then Rack::Response.new(render('statistics.html.erb'))
      when '/game' then Rack::Response.new(render('game.html.erb'))
      when '/lose' then Rack::Response.new(render('lose.html.erb'))
      when '/start_game' then start_game
      when '/submit_answer' then submit_answer
      when '/receive_hint' then receive_hint
      when '/win' then Rack::Response.new(render('win.html.erb'))
      else
        Rack::Response.new('Not Found', 404)
      end
    end

    def start_game
      name = @request.params['player_name']
      difficulty = @request.params['level']

      @request.session[:game_obj] = CodeBreaker::CodeBreakerGame.new(name, difficulty)
      @request.session[:hints] = []

      Rack::Response.new { |response| response.redirect("/game") }
    end

    def submit_answer
      begin
        number = @request.params['number'].to_i
        result =  @request.session[:game_obj].action(:guess, number)
        @request.session[:result] = result.chars

        if result == '++++'
          Rack::Response.new { |response| response.redirect("/win") }
        else
          Rack::Response.new { |response| response.redirect("/game") }
        end
      rescue CodeBreaker::NoAttemptsLeftError => e
        Rack::Response.new { |response| response.redirect("/lose") }
      end
    end

    def receive_hint
      begin
        @request.session[:hints] << @request.session[:game_obj].action(:hint)

        Rack::Response.new { |response| response.redirect("/game") }
      rescue CodeBreaker::NoHintsLeftError => e
        puts e
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