require 'sinatra'
require 'twitter'
require 'awesome_print'
require 'json'

# set :public_folder, File.dirname(__FILE__) + '/static'

get '/' do
  make_text(make_chains(get_text(get_tweets('realdonaldtrump'))))
end

# Twitter

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
    key = [words[i], words[i + 1]]
    value = words[i + 2]

    if !chains.include? key
      chains[key] = []
    end

    chains[key] << value
  end
  chains
end

def make_text(chains)
  key = chains.keys.sample
  words = [key.first, key.last]
  word = chains[key].sample

  File.open("chains.json","w") do |f|
    f.write(chains.to_json)
  end

  while word.nil?
    key = [key[1], word]
    words << word
    word = chains[key].sample
  end

  words.join(' ')
end
