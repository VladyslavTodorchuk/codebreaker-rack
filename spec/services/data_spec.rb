# frozen_string_literal: true

RSpec.describe 'SaveService' do
  let(:table) { Entities::Rating.new }
  let(:load) { Services::LoadService.new './tmp/data.yml' }
  let(:save) { Services::SaveService.new table, './tmp/data.yml' }
  let(:game) { CodeBreaker::Game.new name: 'Vlad', difficulty: 'easy', secret_code: [1, 1, 1, 1] }
  let(:data) do
    {
      name: game.name, difficulty: game.difficulty, total_attempts: game.total_attempts,
      used_attempts: game.used_attempts, total_hints: game.total_hints,
      used_hints: game.used_hints, date: Date.parse(DateTime.now.to_s)
    }
  end

  describe '#execute' do
    context 'when data save to file the same as read' do
      before do
        FileUtils.mkdir './tmp'

        table.rating << data
        save.save
      end

      after { FileUtils.remove_dir './tmp' }

      it 'load object Table and check if it been saved correctly' do
        expect(load.load.rating).to match_array(table.rating)
      end
    end
  end
end
