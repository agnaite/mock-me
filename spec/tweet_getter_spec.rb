require_relative '../controllers/app.rb'

describe TweetGetter do
  it 'can be created' do
    expect(TweetGetter.new 'agnaite').to_not be_nil
  end
end

expect(asdf).to be_a(String)