require 'sinatra'
require 'twitter'
require 'awesome_print'
require 'json'

# set :public_folder, File.dirname(__FILE__) + '/static'

get '/' do
  # username = params['username']
  @tweet_getter = TweetGetter.new('agnaite')
  @tweet_getter.get_tweets!
end

class TweetGetter

  def initialize username
    @username = username
  end

  def username
    @username
  end

  def get_tweets!
    if has_tweet_file?
      file = File.read(tweet_file)
      data_hash = JSON.parse(file)
      make_text(data_hash)
    else
      tweets = scrape_twitter
      File.open(tweet_file, 'w') do |handle|
        handle.puts JSON.pretty_generate(tweets)
      end
    end
  end

  private

  def scrape_twitter
    response = get_tweets(@username)
    text = get_text(response)
    chains = make_chains(text)
  end

  def has_tweet_file?
    File.exists?(tweet_file)
  end

  def tweet_file
    "#{username}.json"
  end
end

def collect_with_max_id(collection=[], max_id=nil, &block)
  response = yield(max_id)
  collection += response
  response.empty? ? collection.flatten : collect_with_max_id(collection, response.last.id - 1, &block)
end

def get_all_tweets(user)
  client = Twitter::REST::Client.new do |config|
    config.consumer_key    = ENV['CONSUMER_KEY']
    config.consumer_secret = ENV['CONSUMER_SECRET']
  end

  collect_with_max_id do |max_id|
    options = {count: 200, include_rts: true}
    options[:max_id] = max_id unless max_id.nil?
    client.user_timeline(user, options)
  end
end

def get_tweets(user)
  begin
    get_all_tweets(user)
  rescue Twitter::Error::TooManyRequests => error
    sleep error.rate_limit.reset_in + 1
    retry
  end
end

def get_text(response)
  tweets = []

  for tweet in response
    for word in tweet.text.split
      if word[0] != '@' && !word.start_with?('http')
        tweets.push(word)
      end
    end
  end
  tweets << nil
end

def make_chains(words)
  chains = {}

  for i in 0..words.length-2
    word_1 = words[i]
    word_2 = words[i + 1]
    value = words[i + 2]

    if !chains.include? word_1
      chains[word_1] = {}
    end
    if !chains[word_1].include? word_2
      chains[word_1][word_2] = []
    end

    chains[word_1][word_2] << value
  end
  chains
end

def make_text(chains)
  word_1 = chains.keys.sample
  word_2 = chains[word_1].keys.sample

  words = [word_1, word_2]
  word = chains[word_1][word_2].sample

  while word.nil?
     word_1 = word_2
     word_2 = word
     words << word
     word = chains[word_1][word_2].sample
  end

  words.join(' ')
end
