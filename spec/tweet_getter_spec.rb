require_relative '../controllers/app.rb'

describe TweetGetter do
  let (:tweet_getter) { TweetGetter.new 'agnaite' }

  it 'can be created' do
    expect(TweetGetter.new 'agnaite').to_not be_nil
  end

  it 'can look up twitter user' do
    expect(tweet_getter.is_user_with_tweets?).to be true
  end

  it 'can look up user profile color' do
    expect(tweet_getter.get_color!).to be_a String
  end
end

