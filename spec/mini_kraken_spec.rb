# frozen_string_literal: true

require_relative '../lib/mini_kraken/version/'

RSpec.describe MiniKraken do
  it 'has a version number' do
    expect(MiniKraken::VERSION).not_to be nil
  end
end
