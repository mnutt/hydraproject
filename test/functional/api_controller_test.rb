require File.dirname(__FILE__) + '/../test_helper'
require 'api_controller'

# Re-raise errors caught by the controller.
class ApiController; def rescue_action(e) raise e end; end

class ApiControllerTest < Test::Unit::TestCase
  def setup
    @controller = ApiController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    @passkey = TRUSTED_SITES.first['passkey']
  end

  def test_auth_failed
    post :time, :passkey => 'invalid'
    assert_response 403
    @req = get_req_hash
    assert @req.is_a?(Hash)
    assert 'auth_failed', @req['auth_required']
    assert @req['reason'] =~ /Authentication failed/
  end
  
  def test_auth_passed
    post :time, :passkey => @passkey
    assert_response :success
    assert @response.boyd =~ /time/
  end
  
  def test_echo_data
    @data = 'here is some data\n right back atcha'
    post :echo_data, :passkey => @passkey, :data => @data
    assert_response :success
    assert_equal @data, @response.body
  end
  
  def test_get_torrents
  end
  
  private 
  
  def get_req_hash
    h = Hash.from_xml(@response.body)
    return h['request']
  end
  
end
