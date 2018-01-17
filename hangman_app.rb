#require 'sinatra'
#require 'sinatra/flash'
#require 'sinatra/reloader' if development?
#require 'warden'
require 'bundler'
Bundler.require

require './lib/secret_word'
require './lib/hangman'
require './lib/model'
  

class HangmanApp < Sinatra::Base
  enable :sessions                          # registers session support
  
  register Sinatra::Flash
  
  set :public_folder, "static"
  set :secret_word => SecretWord.new, :hangman => Hangman.new, :counter => 0

  # Warden setup block
  use Warden::Manager do |config|
    # Tell Warden how to save our User info into a session.
    # Sessions can only take strings, not Ruby code, we'll store
    # the User's `id`
    config.serialize_into_session { |user| user.id }
    # Now tell Warden how to take what we've stored in the session
    # and get a User from that information.
    config.serialize_from_session { |id| User.get(id) }

    config.scope_defaults :default,
      # "strategies" is an array of named methods with which to
      # attempt authentication. We have to define this later.
      strategies: [:password],
      # The action is a route to send the user to when
      # warden.authenticate! returns a false answer. We'll show
      # this route below.
      action: '/unauthenticated'
    # When a user tries to log in and cannot, this specifies the
    # app to send the user to.
    config.failure_app = self
  end

  Warden::Manager.before_failure do |env, opts|
    # Because authentication failure can happen on any request but
    # we handle it only under "post '/auth/unauthenticated'", we need
    # to change request to POST
    env['REQUEST_METHOD'] = 'POST'
    # And we need to do the following to work with Rack::MethodOverride
    env.each do |key, value|
      env[key]['_method'] = 'post' if key == 'rack.request.form_hash'
    end
  end

  # Block for the :password strategy we called above
  Warden::Strategies.add(:password) do
    def valid?    # acts as guard for the strategy it'll be tried if #valid? evaluates to true
      params['user'] && params['user']['username'] && params['user']['password']
    end

    def authenticate!    # the logic for authenticating my request
      user = User.first(username: params['user']['username'])  # a datamapper method that finds first matching record with the name params['user']['username']

      if user.nil?
        throw(:warden, message: "The username you entered does not exist")
      elsif user.authenticate(params['user']['password'])  # we created authenticate method in our model.rb file in User class that accepts an attempted password
        success!(user)
      else
        throw(:warden, message: "The username and password combination")
      end
    end
  end
  
  get '/' do
    user = User.get(session['warden.user.default.key'])  # gets user from our database

    if user
      settings.secret_word.secret_word = user.secret_word unless user.secret_word.nil?
      settings.secret_word.found_letters = user.found_letters unless user.found_letters.nil?
      settings.counter = user.counter unless user.counter.nil?
    end
    
    redirect '/game'
  end
      
  get '/game' do
    user = User.get(session['warden.user.default.key'])
    
    secret_word = settings.secret_word.secret_word
    p secret_word
    underscored_word = settings.secret_word.modify
    hangman = settings.hangman.hangman

    erb :index, :locals => {:user => user, :secret_word => secret_word, :underscored_word => underscored_word, :hangman => hangman[settings.counter]}
  end

  post '/game' do
    user = User.get(session['warden.user.default.key'])

    letter = params['letter']
    word = params['word']
  
    hangman = settings.hangman.hangman
    secret_word = settings.secret_word.secret_word
  
    message = validate(letter, word)

    if message.include?("Well done!") || message.include?("Good luck")
      settings.secret_word = SecretWord.new
      settings.counter = 0
      
      hangman = 
        if message.include?("Good luck")
          unless user.nil?
            user.lose += 1
            user.save
          end
          
          hangman[6]
        else
          unless user.nil?
            user.win += 1
            user.save
          end
          
          hangman[0]
        end
      
      erb :message, :locals => {:message => message, :hangman => hangman} 
    else
      underscored_word = message
    
      erb :index, :locals => {:user => user, :secret_word => secret_word, :underscored_word => underscored_word, :hangman => hangman[settings.counter]} 
    end
  end

  get '/register' do
    erb :register
  end

  post '/register' do
    if params['user']['password'] != params['user']['password_again']
      flash[:error] = "Passwords didn't match"
      redirect '/register'
    elsif params['user']['username'] && params['user']['password'] == ""
      flash[:error] = "Fill out this form to continue!"
      redirect '/register'
    else
      user = User.new(:username => params['user']['username'], :password => params['user']['password'])
      user.dirty?
      user.save
      flash[:success] = "Successfully registered. Log in to continue!"
    end

    redirect '/login'
  end

  get '/login' do
    erb :login
  end

  post '/login' do
    env['warden'].authenticate!  # authentication with Warden
  
    flash[:success] = "Successfully logged in"
  
    if session[:return_to].nil?
      redirect '/'
    else
      redirect session[:return_to]
    end
  end

  get '/logout' do
    user = User.get(session['warden.user.default.key'])
    
    if user
      user.update(:secret_word => settings.secret_word.secret_word, :found_letters => settings.secret_word.found_letters, :counter => settings.counter)

      env['warden'].raw_session.inspect
      env['warden'].logout
    
      flash[:success] = 'Successfully logged out'
    
      redirect '/game'
    else
      redirect '/game'
    end
  end

  post '/unauthenticated' do
    session[:return_to] = env['warden.options'][:attemted_path] if session[:return_to].nil?
    # Set the error and use a fallback if the message is not defined
    flash[:error] = env['warden.options'][:message] || "You must log in"
  
    redirect '/login'
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
        settings.secret_word.modify
      end
  end
end  
