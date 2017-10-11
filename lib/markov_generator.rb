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