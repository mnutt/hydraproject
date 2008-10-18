require File.dirname(__FILE__) + '/../spec_helper'

describe Torrent do
  before do
    @torrent = Factory.create(:torrent)
  end

  it 'should have a param with the name in it' do
    @torrent.to_param.should == "#{@torrent.id}-my-torrent"
  end

  it 'should tally the number of peers' do
    @torrent.num_peers.should == 14
  end

  it 'should not have negative numbers of peers' do
    @torrent.seeders = -5
    @torrent.leechers = -5
    @torrent.ensure_non_negative
    @torrent.seeders.should == 0
    @torrent.leechers.should == 0
  end
end

describe Torrent, "starting a peer" do
  describe "that is a regular seeder" do
    before do
      CACHE.reset
      @torrent = Factory.create(:torrent)
      @peer = Factory.create(:peer, :torrent => @torrent)
      @torrent.peer_started!(@peer, '127.0.0.1')
    end
    
    it 'should increment the seeder count' do
      @torrent.seeders.should == 5
    end
    
    it 'should put the peer in the cache' do
      CACHE.get(@torrent.tkey).should == {@peer.id => '127.0.0.1'}
    end
  end

  describe "that switched IP addresses" do
    before do
      CACHE.reset
      @torrent = Factory.create(:torrent)
      @peer = Factory.create(:peer, :torrent => @torrent)
      @torrent.peer_started!(@peer, '127.0.0.1')
      @torrent.peer_started!(@peer, '127.0.0.2')
    end

    it 'should update the cache with the second peer address' do
      CACHE.get(@torrent.tkey).should == {@peer.id => '127.0.0.2'}
    end
  end
end

describe Torrent, "stopping a peer" do
  before do
    CACHE.reset
    @torrent = Factory.create(:torrent)
    @peer = Factory.create(:peer, :torrent => @torrent)
    @torrent.peer_started!(@peer, '127.0.0.1')
    @torrent.peer_stopped!(@peer, '127.0.0.1')
  end

  it 'should remove the peer from the cache' do
    CACHE.get(@torrent.tkey).should == nil
  end
end
