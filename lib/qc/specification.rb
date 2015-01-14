class QC::Specification
  def initialize(spec_class, generators)
    @spec_class = spec_class
    @generators = generators
  end

  def and_with(*generators)
    Specification.new(@spec_class, @generators + generators)
  end

  def it(*args, &block)
    generators = @generators
    @spec_class.it *args do
      example_group_instance = self

      QC.current_config[:iterations].times do
        values = generators.map { |g| g.generate }
        example_group_instance.instance_exec(*values, &block)
      end
    end
  end

  # TODO: Consider defining "it" equivalents for all the other helpers RSpec itself generates
end
