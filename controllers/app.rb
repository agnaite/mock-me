require 'sinatra'
require 'twitter'
require 'json'

require_relative('../lib/markov_generator.rb')
require_relative('../lib/tweet_getter.rb')

set :root, File.join(File.dirname(__FILE__), '..')
set :views, Proc.new { File.join(root, "views") }

enable :sessions



get '/' do
  @username = params[:username]

  if @username
    markov = MarkovGenerator.new
    tweet_getter = TweetGetter.new(@username)

    if (!markov.has_file?(@username)) && (tweet_getter.is_user_with_tweets?)
      tweets = tweet_getter.get_tweets!
      markov.write_file(markov.make_chains(tweets), @username)
    end

    if tweet_getter.is_user_with_tweets?
      @color = tweet_getter.get_color!
    end

    if markov.has_file?(@username)
      @text = markov.generate_text(markov.read_file(@username))
    else
      session[:flash] = "User does not exist or has no tweets!"
    end
  end

  erb :index
end


