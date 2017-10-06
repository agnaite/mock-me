require 'sinatra'
require 'twitter'

# set :public_folder, File.dirname(__FILE__) + '/static'

client = Twitter::REST::Client.new do |config|
  config.consumer_key    = "4CoafBxL4HkxdPNZqRO5Bq3FE"
  config.consumer_secret = "96nN6p4FicafklCPQ47awscYYM85vvpEAt0vAR61BTaogiuLWe"
end

get '/' do
  client.get_all_tweets("agnaite")
end

# Twitter

def collect_with_max_id(collection=[], max_id=nil, &block)
  response = yield(max_id)
  collection += response
  response.empty? ? collection.flatten : collect_with_max_id(collection, response.last.id - 1, &block)
end

def client.get_all_tweets(user)
  collect_with_max_id do |max_id|
    options = {count: 2, include_rts: false}
    options[:max_id] = max_id unless max_id.nil?
    user_timeline(user, options)
  end
end
