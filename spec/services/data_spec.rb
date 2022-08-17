# frozen_string_literal: true

RSpec.describe 'SaveService' do
  let(:table) { Entities::Rating.new }
  let(:load) { Services::LoadService.new './tmp/data.yml' }
  let(:save) { Services::SaveService.new table, './tmp/data.yml' }

  describe '#execute' do
    context 'when data save to file the same as read' do
      before do
        FileUtils.mkdir './tmp'

        data = CodeBreaker::Game.new name: 'Vlad', difficulty: 'easy', secret_code: [1, 1, 1, 1]
        table.rating << {
          name: data.name, difficulty: data.difficulty, total_attempts: data.total_attempts,
          used_attempts: data.used_attempts, total_hints: data.total_hints,
          used_hints: data.used_hints, date: Date.parse(DateTime.now.to_s)
        }
        save.save
      end

      after { FileUtils.remove_dir './tmp' }

      it do
        expect(load.load.rating).to match_array(table.rating)
      end
    end
  end
end
