require 'sinatra'
require 'twitter'
require 'tuples'
require 'pp'

# set :public_folder, File.dirname(__FILE__) + '/static'

get '/' do
  make_text(make_chains(get_text(get_tweets('heyaudy', 200))))
end

# Twitter

def get_tweets(user, count)

  client = Twitter::REST::Client.new do |config|
    config.consumer_key    = ENV['CONSUMER_KEY']
    config.consumer_secret = ENV['CONSUMER_SECRET']
  end

  options = {count: count, include_rts: true}
  response = client.user_timeline(user, options)
end

def get_text(response)
  tweets = []

  for tweet in response
    for word in tweet.text.split
      if word[0] != '@'
        tweets.push(word)
      end
    end
  end
  tweets << nil
end

def make_chains(words)
  chains = {}

  for i in 0..words.length-2
    key = Tuple.new(words[i], words[i + 1])
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

  puts chains

  while word.nil?
    key = Tuple.new(key[1], word)
    words << word
    word = chains[key].sample
  end

  words.join(' ')
end
