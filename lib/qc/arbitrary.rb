module QC::Arbitrary
  def int(range=1..2**30)
    # Note that giving a range to #int that contains floats will make it behave like #float. Might want to check for
    # that and warn the user that they're doing weird things.
    Generators::BlockGenerator.new do
      Random.rand(range)
    end
  end

  def float(range=1.0..2.0**30)
    range = Range.new(range.begin.to_f, range.end.to_f, range.exclude_end?) if range
    Generators::BlockGenerator.new do
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


class QC::ArbitraryClass
  extend Arbitrary
end