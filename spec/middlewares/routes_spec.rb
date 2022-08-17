# frozen_string_literal: true

RSpec.describe Middlewares::Routes do
  include Rack::Test::Methods

  def app
    Rack::Builder.parse_file('config.ru').first
  end

  let(:code_breaker) do
    CodeBreaker::CodeBreakerGame.new('Vlad', 'easy')
  end

  context 'when wrong route' do
    it 'returns status not found' do
      get '/wrong_path'
      expect(last_response).to be_not_found
    end
  end

  context 'when menu' do
    it 'returns status ok' do
      get '/'
      expect(last_response).to be_ok
    end
  end

  context 'when statistics' do
    it 'returns status ok' do
      get '/statistics'
      expect(last_response).to be_ok
    end
  end

  context 'when rules' do
    it 'returns status ok' do
      get '/rules'
      expect(last_response).to be_ok
    end
  end

  context 'when game' do
    it 'redirects to lose page' do
      code_breaker.game.instance_variable_set(:@total_attempts, 0)
      env('rack.session', game_obj: code_breaker)
      get '/submit_answer', number: 1243
      expect(last_response.header['Location']).to eq('/lose')
    end
  end

  context 'when game lose' do
    before do
      env('rack.session', game_obj: code_breaker)
    end

    it 'redirects to game if attempts exist' do
      get '/lose'
      expect(last_response.header['Location']).to eq('/game')
    end

    it 'shows lose page' do
      code_breaker.game.instance_variable_set(:@total_attempts, 0)
      get '/submit_answer', number: 1254
      expect(last_response.header['Location']).to eq('/lose')
    end

    it 'shows a game' do
      env('rack.session', game_obj: code_breaker)
      get '/game'
      expect(last_response.body).to include("Hello, #{last_request.session[:game_obj].game.name}!")
    end
  end

  context 'when game win' do
    before { env('rack.session', game_obj: code_breaker) }

    it 'redirects to game if attempts exist' do
      get '/win'
      expect(last_response.header['Location']).to eq('/game')
    end

    it 'shows win page' do
      code_breaker.game.instance_variable_set(:@secret_code, [1, 2, 3, 4])
      env('rack.session', game_obj: code_breaker)
      get '/submit_answer', number: 1234
      expect(last_response.header['Location']).to eq('/win')
    end
  end

  context 'when game show hint' do
    before do
      env('rack.session', game_obj: code_breaker, hints: [])
    end

    it 'gives hint' do
      get '/receive_hint'
      expect(last_request.session[:hints].size).to be 1
    end
  end

  context 'when game start' do
    context 'when without parameters' do
      it 'returns redirect' do
        get '/start_game'
        expect(last_response).to be_redirect
      end
    end

    context 'when received user params' do
      before do
        post '/start_game', player_name: 'Vlad', level: 'easy'
      end

      it 'sets a game_obj into session' do
        expect(last_request.session).to include(:game_obj)
      end

      it 'redirects to game page' do
        expect(get('/start_game')).to be_redirect
      end
    end
  end
end
