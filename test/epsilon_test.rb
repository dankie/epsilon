require 'test/unit'

require "#{File.dirname(__FILE__)}/../init"

class EpsilonTest < Test::Unit::TestCase
  def test_classes_are_loaded
    assert_nothing_raised do
      ::Epsilon
      ::Epsilon::Api
    end
  end
end
