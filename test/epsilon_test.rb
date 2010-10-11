require 'rubygems'
require 'test/unit'

require "#{File.dirname(__FILE__)}/../init"

class EpsilonTest < Test::Unit::TestCase
  def test_classes_are_loaded
    assert_nothing_raised do
      ::Epsilon
      ::Epsilon::Api
    end
  end

  # PASSWORD
  def test_can_set_and_retrieve_password
    assert_nothing_raised do
      ::Epsilon::Api.password = 'test.pass.word'
      assert_equal 'test.pass.word', ::Epsilon::Api.password
    end
  end

  # USERNAME
  def test_can_set_and_retrieve_username
    assert_nothing_raised do
      ::Epsilon::Api.username = 'test.user.name'
      assert_equal 'test.user.name', ::Epsilon::Api.username
    end
  end

  # SERVERNAME
  def test_can_set_and_retrieve_servername
    assert_nothing_raised do
      ::Epsilon::Api.servername = 'test.server.name'
      assert_equal 'test.server.name', ::Epsilon::Api.servername
    end
  end

  # CONFIGURATION

  def test_default_configuration_is_hash
    assert ::Epsilon::Api.configuration.is_a?(Hash)
  end

  # CONFIGURATION=

  def test_configuration_takes_an_empty_hash
    assert_nothing_raised do
      ::Epsilon::Api.configuration = {}
    end
  end

  def test_configuration_raises_when_not_setting_a_hash
    assert_raises RuntimeError do
      ::Epsilon::Api.configuration = "String"
    end
  end

  # XML

  def test_xml_does_contain_xml_instruction
    xml = ::Epsilon::Api.xml('some@email.com')
    assert /<\?xml/.match(xml), 'XML does not contain XML-Instructions'
  end

end
