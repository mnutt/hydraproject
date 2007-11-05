require File.dirname(__FILE__) + '/../test_helper'
require 'announce_controller'

# Re-raise errors caught by the controller.
class AnnounceController; def rescue_action(e) raise e end; end

class AnnounceControllerTest < Test::Unit::TestCase
  def setup
    @controller = AnnounceController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
