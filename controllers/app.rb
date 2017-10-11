require 'sinatra'
require 'twitter'
require 'json'

set :root, File.join(File.dirname(__FILE__), '..')
set :views, Proc.new { File.join(root, "views") }

get '/' do
  username = params[:username]

  if !username.nil?
    @markov = MarkovGenerator.new
    @tweet_getter = TweetGetter.new(username)

    if (!@markov.has_file?(username)) && (@tweet_getter.is_user_with_tweets?)
      tweets = @tweet_getter.get_tweets!
      @markov.write_file(@markov.make_chains(tweets), username)
    end
    
    if @tweet_getter.is_user_with_tweets?
      user_color = @tweet_getter.get_color!
      generated_text = @markov.generate_text(@markov.read_file(username))
    end
  end

  erb :index, :locals => {:text => generated_text || '',
                          :user => username,
                          :color => user_color || '000'}
end

class TweetGetter

  def initialize username
    @username = username

    @client = Twitter::REST::Client.new do |config|
      config.consumer_key    = ENV['CONSUMER_KEY']
      config.consumer_secret = ENV['CONSUMER_SECRET']
    end
  end

  def is_user_with_tweets?
    (@client.user?(@username)) && (@client.user(@username).statuses_count > 0)
  end

  def get_tweets!
    clean_up_tweets(get_all_tweets)
  end

  def get_color!
    @client.user(@username).profile_link_color
  end

  private

  # get max tweets for given user, from twitter gem
  def collect_with_max_id(collection=[], max_id=nil, &block)
    response = yield(max_id)
    collection += response
    response.empty? ? collection.flatten : collect_with_max_id(collection, response.last.id - 1, &block)
  end

  def get_all_tweets
    begin
      collect_with_max_id do |max_id|
        options = {count: 200, include_rts: false}
        options[:max_id] = max_id unless max_id.nil?
        @client.user_timeline(@username, options)
      end
    rescue Twitter::Error::TooManyRequests => error
      sleep error.rate_limit.reset_in + 1
      retry
    end
  end

  def clean_up_tweets(response)
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
end

class MarkovGenerator

  def has_file?(file)
    File.exists?('./data/'+file_name(file))
  end

  def read_file(file)
    read_file = File.read('./data/'+file_name(file))
    data_hash = JSON.parse(read_file)
  end

  def write_file(chains, file)
    File.open('./data/'+file_name(file), 'w') do |handle|
      handle.puts JSON.pretty_generate(chains)
    end
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

  def generate_text(chains)
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

  private

  def file_name(name)
    "#{name}.json"
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
      if (!word.nil?) && (['!', '.', '?'].include? word[-1])
        words = words[0, index+1]
        break
      end
    end
    words
  end
end
