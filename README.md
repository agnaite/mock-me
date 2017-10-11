# mock-me
scrape a user's tweets and use markov chains to generate text 🐦⛓

## To set-up:
- `$ git clone https://github.com/agnaite/mock-me.git`
- set up twitter application/get consumer key and secret [here](https://apps.twitter.com)
- `$ touch secrets.sh`
- paste your twitter key and secret into your `secrets.sh`, like so:
```
export CONSUMER_SECRET="my_secret"
export CONSUMER_KEY="my_key"
```
- `$ source secrets.sh`
- `$ bundle install`
- `$ ruby controllers/app.rb`
