require File.dirname(__FILE__) + '/../spec_helper'
require 'ostruct'
require 'digest/sha1'

def mock_mi(options={}, mii_options={})
  OpenStruct.new({ :comment => "comment",
                   :url_list => "URL list",
                   :announce => "http://torrent.example.com/announce",
                   :announce_list => [["http://torrent.example.com/announce",
                                       "http://torrent2.example.com/announce"], 
                                      ["http://torrent3.example.com/announce"]],
                   :creation_date => Time.now,
                   :created_by => "user",
                   :info => mock_mii(mii_options) }.merge(options))
end

def mock_mii(options)
  OpenStruct.new({ :name => "file.jpg",
                   :length => 1024,
                   :info_hash => Digest::SHA1.digest("infohash"),
                   :piece_length => 256,
                   :pieces => Digest::SHA1.digest("A"),
                   :files => [OpenStruct.new(:path => "file.jpg".split("/"), :length => 1024)]}.merge(options))
end

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

describe Torrent, "setting metainfo" do
  before do
    @torrent = Factory.create(:torrent)
    @mi = mock_mi
  end

  it "should set the correct filesize" do
    @torrent.set_metainfo!(@mi)
    @torrent.size.should == 1024
  end

  it "should set the correct name" do
    @torrent.set_metainfo!(@mi)
    @torrent.name.should == "My Torrent"
  end

  it "should have the right number of files" do
    @torrent.set_metainfo!(@mi)
    @torrent.torrent_files.count.should == 1
    @torrent.numfiles.should == 1
  end

  it "should set the correct number of pieces" do
    @torrent.set_metainfo!(@mi)
    @torrent.pieces.should == 1
  end

  it "should work with a multi-directory path" do
    @mi.info.files.first.path = ["path", "to", "file.txt"]
    @torrent.set_metainfo!(@mi)
    @torrent.torrent_files.first.filename.should == "path\\to\\file.txt"
  end

  it "should work with just a single file" do
    @mi.info.stub!(:single?).and_return(true)
    @mi.info.length = 16384
    @mi.info.name = "singlemii.txt"
    @torrent.set_metainfo!(@mi)

    @torrent.numfiles.should == 1
    @torrent.torrent_files.first.filename.should == "singlemii.txt"
    @torrent.torrent_files.first.size.should == 16384
  end

  it "should work with multiple files" do
    @mi.info.pieces = [Digest::SHA1.digest("A"), Digest::SHA1.digest("B")].join
    another_file = @mi.info.files.first.clone
    @mi.info.files << another_file
    @torrent.set_metainfo!(@mi)
    
    @torrent.numfiles.should == 2
    @torrent.pieces.should == 2
    @torrent.torrent_files.count.should == 2
    @torrent.size.should == 2048
  end

  it "should use the torrent filename if the name is blank" do
    # should not be here?
    @torrent.name = ""
    @torrent.filename = "my_filename.torrent"
    @torrent.set_metainfo!(@mi)
    @torrent.name.should == "my filename"
  end
end
