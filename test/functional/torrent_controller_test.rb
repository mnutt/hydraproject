require File.dirname(__FILE__) + '/../test_helper'
require 'torrent_controller'

# Re-raise errors caught by the controller.
class TorrentController; def rescue_action(e) raise e end; end

class TorrentControllerTest < Test::Unit::TestCase
  def setup
    @controller = TorrentController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
