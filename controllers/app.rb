require 'sinatra'
require 'twitter'
require 'json'

set :root, File.join(File.dirname(__FILE__), '..')
set :views, Proc.new { File.join(root, "views") }

get '/' do
  username = params[:username]
  if !username.nil?
    @tweet_getter = TweetGetter.new(username)
    if @tweet_getter.is_user?
      generated_text = @tweet_getter.get_tweets!
    end
  end
  erb :index, :locals => {:text => generated_text || '[user not found]'}
end

class TweetGetter

  def initialize username
    @username = username

    @client = Twitter::REST::Client.new do |config|
      config.consumer_key    = ENV['CONSUMER_KEY']
      config.consumer_secret = ENV['CONSUMER_SECRET']
    end
  end

  def username
    @username
  end

  def is_user?
    @client.user?(@username)
  end

  def get_tweets!
    # if no file, scrape twitter and write to json
    if !has_tweet_file?
      tweets = scrape_twitter
      File.open('./data/'+tweet_file, 'w') do |handle|
        handle.puts JSON.pretty_generate(tweets)
      end
    end

    file = File.read('./data/'+tweet_file)
    data_hash = JSON.parse(file)
    make_text(data_hash)
  end

  private

  def scrape_twitter
    response = get_tweets(@username)
    text = clean_up_text(response)
    chains = make_chains(text)
  end

  def has_tweet_file?
    File.exists?('./data/'+tweet_file)
  end

  def tweet_file
    "#{username}.json"
  end

  # get max tweets for given user, from twitter gem
  def collect_with_max_id(collection=[], max_id=nil, &block)
    response = yield(max_id)
    collection += response
    response.empty? ? collection.flatten : collect_with_max_id(collection, response.last.id - 1, &block)
  end

  def get_all_tweets(user)
    collect_with_max_id do |max_id|
      options = {count: 200, include_rts: false}
      options[:max_id] = max_id unless max_id.nil?
      @client.user_timeline(user, options)
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

  def clean_up_text(response)
    tweets = []

    # get rid of links and @usernames
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
    word_1 = get_first_word(chains)
    word_2 = chains[word_1].keys.sample

    words = [word_1, word_2]
    word = chains[word_1][word_2].sample

    while (chains.include? word_1) && (chains[word_1].include? word_2) && (words.length < 50)
       word_1 = word_2
       word_2 = word
       words << word
       if (chains.include? word_1) && (chains[word_1].include? word_2)
         word = chains[word_1][word_2].sample
       end
    end
    end_in_punctuation(words).join(' ')
  end

  def get_first_word(chains)
    word_1 = chains.keys.sample

    # make sure first word is capitalized
    while word_1 != word_1.capitalize
      word_1 = chains.keys.sample
    end
    word_1
  end

  def end_in_punctuation(words)
    # make sure the text ends in punctuation
    words.to_enum.with_index.reverse_each do |word, index|
      if ['!', '.', '?'].include? word[-1]
        words = words[0, index+1]
        break
      end
    end
    words
  end
end

