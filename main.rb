require "yaml"

class Hangman
  def initialize
    @game
  end

  def start
    loop do
      load_file
      choose_mode
      @game.play
      puts 'Do you want to play again?'
      puts "Type in 'y' to play again, other to exit"
      again = gets.chomp
      break if again != 'y'
      puts ''
    end
  end

  private

  def load_file
    game_file = File.open('game_class.yml', "r")
    Game.from_yaml(game_file)
  end

  def choose_mode
    if Game.all.empty?
      puts 'There are no saved games. Starting a new game...'
      @game = Game.new
      return
    end
    loop do
      mode = ask_mode
      if mode == '1'
        @game = Game.new
        break
      elsif mode == '2'
        puts "Saved games:"
        Game.all.each_with_index {|game, i| puts "#{i+1}. #{game.name}"}
        puts "Type in the game number you want to load."
        file_number = get_file_number
        @game = Game.all[file_number - 1]
        break
      else
        puts 'Choose only 1 or 2'
      end
    end
  end
  
  def ask_mode
    puts 'Press 1 to start a new game.'
    puts 'Press 2 to load a saved game.'
    gets.chomp
  end

  def get_file_number
    file_number = 0
    loop do
      file_number = Integer(gets, exception: false)
      if file_number == nil
        puts 'Invalid answer. Please type in a number.'
      elsif file_number <= Game.all.length
        break
      else
        puts 'Invalid number. Please type a valid the number only.'
      end
    end
    file_number
  end
  
end

class Game
  @@all = []
  @@alphabet = [*('a'..'z')]
  MAX_MISTAKE = 10

  attr_reader :name

  def initialize
    @@dictionary = read_words
    @name = @@dictionary.sample + @@dictionary.sample
    @secret_word = @@dictionary.sample
    @progress = blank_space(@secret_word)
    @incorrect = []
    @fname = 'game_class.yml'
    @@all << self
  end

  def self.all
    @@all
  end

  def play
    exit = false
    while @incorrect.length < MAX_MISTAKE
      puts @progress.join(' ')
      puts "Incorrect letters: #{@incorrect.join(' ')}"
      puts "Mistakes allowed: #{MAX_MISTAKE - @incorrect.length}"
      loop do
        turn = take_turn
        if turn == 'save'
          save_game
          exit = true
          break
        elsif @incorrect.include?(turn) || @progress.include?(turn)
          puts 'You have guessed that letter. Choose another one.'
        elsif @@alphabet.include?(turn)
          evaluate(turn)
          break
        else
          puts 'Invalid input.'
        end
      end

      if win?
        puts @progress.join(' ')
        puts 'You guessed the word. You win!'
        break
      elsif @incorrect.length == MAX_MISTAKE
        puts "You lose. The secret word is '#{@secret_word}'."
      elsif exit == true
        break
      end
    end
  end
  
  private

  def read_words
    words = []
    fname = 'google-10000-english-no-swears.txt'
    File.open(fname, 'r').each do |line|
      word = line.chomp
      words << word if word.length <= 12 && word.length >= 5
    end
    words
  end

  def blank_space(word)
    Array.new(word.split('').length, '_')
  end

  def take_turn
    puts 'Type in a letter to guess.'
    puts "Type in 'save' to save your progress and go back to main menu."
    gets.chomp.downcase
  end

  def evaluate(guess)
    count = 0
    if @secret_word.include?(guess)
      @secret_word.split('').each_with_index do |letter, i|
        if letter == guess
          @progress[i] = guess
          count += 1
        end
      end
    else
      @incorrect << guess
    end
    puts "There are #{count} #{guess}('s)."
  end

  def win?
    !@progress.include?('_')
  end

  def to_yaml
    YAML.dump(@@all.each {|game| game})
  end

  def self.from_yaml(string)
    saved_games = YAML.load string
    if saved_games == false
      @all = []
    else
      @@all = saved_games
    end
  end
  
  def save_game
    game_file = File.open(@fname, "w")
    game_file.puts (to_yaml)
    game_file.close
  end
  
end

game = Hangman.new.start