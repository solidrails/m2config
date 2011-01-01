require 'rubygems'
require 'test/spec'
require File.expand_path('../../lib/m2config', __FILE__)
require 'm2config/handler'

def setup_all
  $db_path = File.expand_path('../config.sqlite', __FILE__)
  db_structdump_path = File.expand_path('../config.sql', __FILE__)
  File.delete($db_path) if File.exists?($db_path)
  `sqlite3 -init #{db_structdump_path} #{$db_path}`
  $db = SQLite3::Database.new($db_path)
end

setup_all

describe "Handler" do
  setup do
    @db = $db
    @handler = M2::Config::Handler.new($db_path)
    ['directory', 'host', 'mimetype', 'route', 'setting', 'handler', 'log', 'proxy', 'server', 'statistic'].each do |table|
      @db.execute('DELETE FROM %s' % table)
    end
  end
  
  describe "adding/finding a host" do
    it "should create a new host if it doesn't exist yet" do
      host = M2::Host.new(:matching => "*.fittl.com")
      
      @db.get_first_value("SELECT id FROM host WHERE matching = ?", host.matching).should.be.nil
      
      host_id = @handler.find_or_add_host host
      host_id.should.not.be.nil
      @db.get_first_value("SELECT id FROM host WHERE matching = ?", host.matching).to_i.should == host_id
      
      host_id2 = @handler.find_or_add_host host
      host_id2.should == host_id
      host_id2 = @handler.find_or_add_host M2::Host.new(:id => host_id)
      host_id2.should == host_id
    end
    
    it "should set name to matching if it isn't specified" do
      host = M2::Host.new(:matching => "*.fittl.com")
      host_id = @handler.find_or_add_host host
      @db.get_first_value("SELECT name FROM host WHERE id = ?", host_id).should == host.matching
    end
    
    it "should set maintenance to 0 if it isn't specified" do
      host = M2::Host.new(:matching => "*.fittl.com")
      host_id = @handler.find_or_add_host host
      @db.get_first_value("SELECT maintenance FROM host WHERE id = ?", host_id).to_i.should == 0
    end
    
    it "should set server_id to 1 if it isn't specified" do
      host = M2::Host.new(:matching => "*.fittl.com")
      host_id = @handler.find_or_add_host host
      @db.get_first_value("SELECT server_id FROM host WHERE id = ?", host_id).to_i.should == 1
    end
    
    it "should require matching" do
      host = M2::Host.new(:name => '*.fittl.com')
      should.raise(Thrift::ProtocolException) { host_id = @handler.find_or_add_host host }
      @db.get_first_value("SELECT id FROM host WHERE name = ?", host.name).should.be.nil
    end
  end
  
  describe "removing a host" do
    it "should remove the specified host" do
      host_id = @handler.find_or_add_host(M2::Host.new(:matching => "*.fittl.com"))
      @db.get_first_value("SELECT id FROM host WHERE id = ?", host_id).should.not.be.nil
      @handler.remove_host(host_id)
      @db.get_first_value("SELECT id FROM host WHERE id = ?", host_id).should.be.nil
    end
    
    it "should silently ignore an unknown host" do
      host_id = 4242
      @db.get_first_value("SELECT id FROM host WHERE id = ?", host_id).should.be.nil
      should.not.raise { @handler.remove_host(host_id) }
      @db.get_first_value("SELECT id FROM host WHERE id = ?", host_id).should.be.nil
    end
  end
  
  describe "adding/finding a route" do
    setup do
      @host_id = @handler.find_or_add_host(M2::Host.new(:matching => "*.fittl.com"))
    end
    
    it "should create a new route if it doesn't exist yet" do
      route = M2::Route.new(:path => "/test", :host_id => @host_id, :target_id => 42, :target_type => M2::TargetType::HANDLER)
      
      @db.get_first_value("SELECT id FROM route WHERE path = ?", route.path).should.be.nil
      
      route_id = @handler.find_or_add_route route
      route_id.should.not.be.nil
      @db.get_first_value("SELECT path FROM route WHERE id = ?", route_id).should == route.path
      @db.get_first_value("SELECT host_id FROM route WHERE id = ?", route_id).to_i.should == route.host_id
      @db.get_first_value("SELECT target_id FROM route WHERE id = ?", route_id).to_i.should == route.target_id
      @db.get_first_value("SELECT target_type FROM route WHERE id = ?", route_id).to_i.should == route.target_type
      
      route_id2 = @handler.find_or_add_route route
      route_id2.should == route_id
      route_id2 = @handler.find_or_add_route M2::Route.new(:id => route_id)
      route_id2.should == route_id
    end
    
    it "should set reversed to 0 if it isn't specified" do
      route = M2::Route.new(:path => "/test", :host_id => @host_id, :target_id => 42, :target_type => M2::TargetType::HANDLER)
      route_id = @handler.find_or_add_route route
      @db.get_first_value("SELECT reversed FROM route WHERE id = ?", route_id).to_i.should == 0
    end
    
    it "should require path, host_id, target_id and target_type" do
      route = M2::Route.new
      should.raise(Thrift::ProtocolException) { route_id = @handler.find_or_add_route route }
      @db.get_first_value("SELECT id FROM route").should.be.nil
      
      route = M2::Route.new(:path => "/test", :host_id => @host_id, :target_id => 42)
      should.raise(Thrift::ProtocolException) { route_id = @handler.find_or_add_route route }
      @db.get_first_value("SELECT id FROM route").should.be.nil
      
      route = M2::Route.new(:path => "/test", :host_id => @host_id, :target_type => M2::TargetType::HANDLER)
      should.raise(Thrift::ProtocolException) { route_id = @handler.find_or_add_route route }
      @db.get_first_value("SELECT id FROM route").should.be.nil
      
      route = M2::Route.new(:path => "/test", :target_id => 42, :target_type => M2::TargetType::HANDLER)
      should.raise(Thrift::ProtocolException) { route_id = @handler.find_or_add_route route }
      @db.get_first_value("SELECT id FROM route").should.be.nil
      
      route = M2::Route.new(:host_id => @host_id, :target_id => 42, :target_type => M2::TargetType::HANDLER)
      should.raise(Thrift::ProtocolException) { route_id = @handler.find_or_add_route route }
      @db.get_first_value("SELECT id FROM route").should.be.nil
    end
    
    it "should save additional fields" do
      route = M2::Route.new(:path => "/test", :host_id => @host_id, :target_id => 42, :target_type => M2::TargetType::HANDLER,
                            :additional_fields => {:solidrails_container_id => 4242})
      route_id = @handler.find_or_add_route route
      @db.get_first_value("SELECT solidrails_container_id FROM route WHERE id = ?", route_id).to_i.should == route.additional_fields[:solidrails_container_id]
    end
    
    it "should throw error and not create the route if additional field doesn't exist in DB" do
      route = M2::Route.new(:path => "/test", :host_id => @host_id, :target_id => 42, :target_type => M2::TargetType::HANDLER,
                            :additional_fields => {:solidrails_container_id => 4242, :not_exist => true})
      should.raise(SQLite3::SQLException) { route_id = @handler.find_or_add_route route }
      @db.get_first_value("SELECT id FROM route").should.be.nil
    end
  end
  
  describe "removing a route" do
    setup do
      @host_id = @handler.find_or_add_host(M2::Host.new(:matching => "*.fittl.com"))
    end
    
    it "should remove the specified route" do
      route_id = @handler.find_or_add_route M2::Route.new(:path => "/test", :host_id => @host_id, :target_id => 42, :target_type => M2::TargetType::HANDLER)
      @db.get_first_value("SELECT id FROM route WHERE id = ?", route_id).should.not.be.nil
      @handler.remove_route(route_id)
      @db.get_first_value("SELECT id FROM route WHERE id = ?", route_id).should.be.nil
    end
    
    it "should silently ignore an unknown route" do
      route_id = 4242
      @db.get_first_value("SELECT id FROM route WHERE id = ?", route_id).should.be.nil
      should.not.raise { @handler.remove_host(route_id) }
      @db.get_first_value("SELECT id FROM route WHERE id = ?", route_id).should.be.nil
    end
  end
end