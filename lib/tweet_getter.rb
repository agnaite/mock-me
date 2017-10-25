class TweetGetter

  def initialize username
    @username = username

    @client = Twitter::REST::Client.new do |config|
      config.consumer_key    = ENV['CONSUMER_KEY']
      config.consumer_secret = ENV['CONSUMER_SECRET']
    end
  end

  def is_user_with_tweets?
    begin
      (@client.user?(@username)) && (@client.user(@username).statuses_count > 0)
    rescue Twitter::Error::Forbidden => error
      false
    end
  end

  def get_tweets!
    get_all_tweets.map { |tweet| tweet.text }
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
end
