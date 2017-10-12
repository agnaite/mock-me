require_relative '../controllers/app.rb'

describe MarkovGenerator do
  let (:markov) { MarkovGenerator.new }
  it 'can be created' do
    expect(MarkovGenerator.new).to_not be_nil
  end

  it 'can check if json file exists' do
    expect(markov.has_file?('agnaite')).to be true
  end

  it 'can parse a json file' do
    expect(markov.read_file('agnaite')).to be_a Hash
  end

  it 'can make markov chains' do
    words = ['Hello', 'how', 'are']
    expect(markov.make_chains(words)).to eq({'Hello'=>{'how'=>['are']},
                                             'how'=>{'are'=>[nil]}})
  end

  it 'can generate text' do
    chains = {'Hello'=>{'how'=>['are']},'how'=>{'are'=>[nil]}}
    expect(markov.generate_text(chains)).to start_with 'Hello'
  end
end