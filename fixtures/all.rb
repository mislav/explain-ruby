#!/usr/bin/env ruby
require 'date'

module Kittens
end

class Klass < MegaKlass
  CONSTANT = "value"
  
  include Kittens
  
  def self.create(options)
    new(options)
  end
  
  class << self
    attr_accessor :default_options
  end
  
  attr_accessor :options
  
  def initialize(moo = nil, options = {})
    super
    @options = options
  end
  
  def name=(value)
    @name = value
  end
  
  def forced?
    options[:force]
  end
  
  def destroy!
    # zomg
  end
  
  def take_block(&block)
    block.call(options)
  end
  
  def explicit_return
    return true
  end
  
  __LINE__
  
  __FILE__
  
  $:
  $LOAD_PATH
end

__END__

Extra data
