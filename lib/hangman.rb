class Hangman
  attr_accessor :hangman
  
  def initialize
    @hangman = [
    %q{
       ;---
          |
          |
          |
     ======
    },
    %q{
       ;---
       o  |
          |
          |
     ======
    },
    %q{
       ;---
       o  | 
       |  |
          |
     ======
    },
    %q{
       ;---
       o  |
      /|  |
          |
     ======    
    },
    %q{
       ;---
       o  |
      /|\ |
          |
     ======
    },
    %q{
       ;---
       o  |
      /|\ |
      /   |
     ======
    },    
    %q{
       ;---
       o  |
      /|\ |
      / \ |
     ======
    }
  ]
  end
end
