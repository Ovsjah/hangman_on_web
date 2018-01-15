require 'sinatra'
require 'sinatra/reloader' if development?

require './lib/secret_word'
require './lib/hangman'

set :views, "views"
set :public_folder, "static"
set :secret_word => SecretWord.new, :hangman => Hangman.new, :counter => 0

get '/' do
  secret_word = settings.secret_word.secret_word
  underscored_word = settings.secret_word.modify
  hangman = settings.hangman.hangman

  erb :index, :locals => {:secret_word => secret_word, :underscored_word => underscored_word, :hangman => hangman[settings.counter]}
end

post '/' do
  letter = params['letter']
  word = params['word']
  
  hangman = settings.hangman.hangman
  secret_word = settings.secret_word.secret_word
  
  message = validate(letter, word)

  if message.include?("Well done!") || message.include?("Good luck")
    settings.secret_word = SecretWord.new
    settings.counter = 0
    hangman = message.include?("Good luck") ? hangman[6] : hangman[0]
    
    erb :message, :locals => {:message => message, :hangman => hangman}      
  else
    underscored_word = message
    
    erb :index, :locals => {:secret_word => secret_word, :underscored_word => underscored_word, :hangman => hangman[settings.counter]} 
  end
end

def validate(letter=nil, word=nil)
  secret_word = settings.secret_word.secret_word
  
  message =
    if word == secret_word
      "Wow! You've guessed right. Well done!"
    elsif letter && !letter.empty? && secret_word.include?(letter)
      settings.secret_word.modify(letter)
    elsif settings.counter == 5
      "Hanged up, loser. Good luck next time!"
    else
      settings.counter += 1
      settings.secret_word.modify(letter)
    end
end
