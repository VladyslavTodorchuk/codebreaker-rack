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
        table.rating << data

        save.save
      end

      after { FileUtils.remove_dir './tmp' }

      it do
        expect(load.load.rating[0].used_attempts).to eq(table.rating[0].used_attempts)
      end

      it do
        expect(load.load.rating[0].used_hints).to eq(table.rating[0].used_hints)
      end

      it do
        expect(load.load.rating[0].name).to eq(table.rating[0].name)
      end

      it do
        expect(load.load.rating[0].difficulty).to eq(table.rating[0].difficulty)
      end
    end
  end
end
