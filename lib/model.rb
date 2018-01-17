require 'data_mapper'  # object-relational mapper (maps object to database)
require 'dm-sqlite-adapter'  # allows DataMapper to communicate to the Database
require 'bcrypt'  # password hashing function

DataMapper.setup(:default, "sqlite://#{Dir.pwd}/db.sqlite")  # specifying my database connection


class User
  include DataMapper::Resource
  
  # Creating properties in object for the Database
  property :id, Serial, :key => true
  property :username, String, :length => 3..50
  property :password, BCryptHash   # property stores hashed password with bcrypt
  property :secret_word, String, :length => 5..12 # property stores secret word in the object
  property :found_letters, String
  property :counter, Integer
  property :win, Integer, :default => 0
  property :lose, Integer, :default => 0
  
  
  def authenticate(attempted_password)
    if self.password == attempted_password
      true
    else
      false
    end
  end
end


DataMapper.finalize  # finalizating model after declaring this checks the model for validity and initializes all properties associated with relationships
DataMapper.auto_upgrade!  # creating new tables and adds columns to existing tables. It doesn't change any existing columns and doesn't drop any columns
# @user is a resource an instance of a model. @user = User.new(:username => "admin", :password => "test") then we should save it @user.save
