require 'rspec'

module QC
  @configuration = {}


  class Generator
    # Just a block for now - could do more stuff later. Maybe make tests reproducible by sourcing a seed from the global config?
    def initialize(&block)
      @block = block
    end

    def generate
      @block.call
    end
  end


  module Generators
    class StringGenerator
      def initialize(length, chars, initial_chars = nil)
        @length = length
        # TODO: What should the default be?
        @chars = chars || (32..126).map(&:chr).join("") + "\r\n\t"
        @initial_chars = initial_chars
      end

      def generate
        length = Random.rand(@length) if @length.is_a?(Range)
        string = length.times.map { @chars[Random.rand(0...@chars.length)] }.join("")
        string[0] = @initial_chars[Random.rand(0...@initial_chars.length)] if @initial_chars && length > 0
        string
      end
    end
  end


  module Arbitrary
    def int(range=1..2**30)
      # Note that giving a range to #int that contains floats will make it behave like #float. Might want to check for
      # that and warn the user that they're doing weird things.
      Generator.new do
        Random.rand(range)
      end
    end

    def float(range=1.0..2.0**30)
      range = Range.new(range.begin.to_f, range.end.to_f, range.exclude_end?) if range
      Generator.new do
        Random.rand(range)
      end
    end

    def string(length: 1..50, chars: nil)
      Generators::StringGenerator.new(length, chars)
    end

    def identifier(length: 1..30)
      Generators::StringGenerator.new(length, ('A'..'Z').to_a.join + ('a'..'z').to_a.join + ('0'..'9').to_a.join + '_', ('a'..'z').to_a.join + '_')
    end
  end


  class ArbitraryClass
    extend Arbitrary
  end


  class Spec
    def initialize(spec_class, generators)
      @spec_class = spec_class
      @generators = generators
    end

    def it(*args, &block)
      generators = @generators
      @spec_class.it *args do
        # TODO: Make configurable
        5.times do
          values = generators.map { |g| g.generate }
          block.call(*values)
        end
      end
    end
  end


  module RSpecExtensions
    def with_qc(*generators)
      Spec.new(self, generators)
    end

    def arbitrary
      ArbitraryClass
    end
  end


  RSpec.configure do |c|
    c.extend(RSpecExtensions)
  end
end
