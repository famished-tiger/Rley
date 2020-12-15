# frozen_string_literal: true

require_relative '../spec_helper' # Use the RSpec framework

# Load the class under test
require_relative '../../lib/mini_kraken/core/bookmark'

module MiniKraken
  module Core
    describe Bookmark do
      let(:one_ser_num) { 42 }
      let(:a_kind) { :scope }
      subject { Bookmark.new(a_kind, one_ser_num) }

      context 'Initialization:' do
        it 'should be initialized with a Symbol and an Integer' do
          expect { Bookmark.new(a_kind, one_ser_num) }.not_to raise_error
        end

        it 'should know its kind' do
          expect(subject.kind).to eq(a_kind)
        end

        it 'should know its serial number' do
          expect(subject.ser_num).to eq(one_ser_num)
        end
      end # context

      context 'Provided services:' do
        it 'should compare to another instance' do
          same = Bookmark.new(a_kind, one_ser_num)
          expect(subject).to eq(same)

          distinct = Bookmark.new(a_kind, 3)
          expect(subject).not_to eq(distinct)
        end
      end # context
    end # describe
  end # module
end # module
