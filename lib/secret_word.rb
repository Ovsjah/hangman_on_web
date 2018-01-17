class SecretWord
  attr_accessor :found_letters, :secret_word
  
  def initialize
    @found_letters = ''
    @secret_word = create
  end
  
  def create
    arr_of_words = File.readlines("./static/5desk.txt")
    words = arr_of_words.delete_if { |word| !word.strip.size.between?(5, 12) }
    words.sample.strip.downcase
  end
  
  def modify(letter = nil)
    found_letters << letter unless letter.nil?
    not_found_letters = secret_word.delete(found_letters)
    secret_word.gsub(/[#{not_found_letters}]/, '_ ')
  rescue RegexpError
    "All letters are found! Well done!"
  end    
end
