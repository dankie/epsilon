require 'rubygems'
require 'test/unit'
require 'mocha'

require "#{File.dirname(__FILE__)}/../init"

class EpsilonTest < Test::Unit::TestCase

  def setup
    ::Epsilon::Api.servername = 'EpsilonServer'
    ::Epsilon::Api.username   = 'EpsilonUser'
    ::Epsilon::Api.password   = 'EpsilonSecret'
    ::Epsilon::Api.url        = 'http://rtm.na.epidm.net/weblet/weblet.dll'
  end

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

  # POST
  #def test_post_doec_succeed
  #  puts ::Epsilon::Api.deliver('some@email.com')
  #end

  # URL
  def test_url_fills_uri
    ::Epsilon::Api.url = 'http://github.com/rjung/epsilon'
    assert_equal 'github.com', ::Epsilon::Api.uri.host
    assert_equal '/rjung/epsilon', ::Epsilon::Api.uri.path
  end

  # XML

  def test_xml_does_contain_xml_instruction
    # Need a better way to test this.
    xml = ::Epsilon::Api.send(:xml, 'some@email.com')
    assert /<\?xml/.match(xml), 'XML does not contain XML-Instructions'
  end

  def test_handle_result_raises_when_result_is_not_200_OK
    ::Epsilon::Api.expects(:post).with(anything).returns(Net::HTTPBadRequest.new(nil, 200, 'OK'))
    enable_epsilon do
      assert_raises RuntimeError do
        ::Epsilon::Api.deliver('some@email.com')
      end
    end
  end

  private

  def enable_epsilon(&block)
    enabled_before = ::Epsilon::Api.enabled
    ::Epsilon::Api.enabled = true
    block.call
    ::Epsilon::Api.enabled = enabled_before
  end

end
