module QC
  @configuration = {
    iterations: 10
  }

  def self.configure(**options)
    @configuration.merge!(options)
  end

  def self.with_config(**options)
    # TODO: NOT THREAD SAFE - but that probably doesn't matter for now.
    old_config = @configuration
    @configuration = @configuration.merge(options)
    begin
      yield
    ensure
      @configuration = old_config
    end
  end

  def self.current_config
    @configuration
  end


  module RSpecExtensions
    def with_qc(*generators)
      Specification.new(self, generators)
    end

    def arbitrary
      ArbitraryClass
    end
  end


  RSpec.configure do |c|
    c.extend(RSpecExtensions)
  end
end
