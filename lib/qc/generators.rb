module QC::Generators
  module Generator
    def after(method_name, *args)
      AfterGenerator.new(self, method_name, args)
    end
  end


  class BlockGenerator
    include Generator

    def initialize(&block)
      @block = block
    end

    def generate
      @block.call
    end
  end


  class StringGenerator
    include Generator

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


  class AfterGenerator
    include Generator

    def initialize(generator, method_name, args)
      @generator = generator
      @method_name = method_name
      @args = args
    end

    def generate
      generator.generate.send(@method_name, *@args)
    end
  end
end