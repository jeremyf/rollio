require 'dice' # from dice_parser

module Rollio
  class Roller
    def initialize(text)
      @text = text
    end

    def roll!
      Dice.roll(@text)
    end

    def render
      puts "#{@text}\tResult"
    end
  end
  private_constant :Roller
end
