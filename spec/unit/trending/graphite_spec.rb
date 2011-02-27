require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require 'critical/trending/graphite'

describe Trending::Graphite::Connection do
  describe "creating a connection" do
    before do
      @tcp_socket_class = mock("TCPSocket-mocked")
    end

    it "creates a TCP connection to graphite at the host and port specified" do
      @tcp_socket_class.should_receive(:new).with('localhost', 2003).and_return(:a_scalable_socket_lol)
      @connection = Trending::Graphite::Connection.new('localhost', 2003, @tcp_socket_class)
      @connection.socket.should == :a_scalable_socket_lol
    end

    it "logs an error when the connection is refused" do
      @tcp_socket_class.should_receive(:new).with('localhost', 2003).and_raise(Errno::ECONNREFUSED)
      @connection = Trending::Graphite::Connection.new('localhost', 2003, @tcp_socket_class)
      logger = mock("logger")
      logger.stub!(:debug)
      @connection.stub!(:log).and_return(logger)
      logger.should_receive(:error)
      @connection.socket
    end

    it "logs an error when the connection times out" do
      @tcp_socket_class.should_receive(:new).with('localhost', 2003).and_raise(Errno::ETIMEDOUT)
      @connection = Trending::Graphite::Connection.new('localhost', 2003, @tcp_socket_class)
      logger = mock("logger")
      logger.stub!(:debug)
      @connection.stub!(:log).and_return(logger)
      logger.should_receive(:error)
      @connection.socket
    end

    it "logs an error when the hostname is not resolvable" do
      @tcp_socket_class.should_receive(:new).with('localhost', 2003).and_raise(SocketError.new("getaddrinfo: nodename nor servname provided, or not known"))
      @connection = Trending::Graphite::Connection.new('localhost', 2003, @tcp_socket_class)
      logger = mock("logger")
      logger.stub!(:debug)
      @connection.stub!(:log).and_return(logger)
      # once for generic err msg, once with suggestion about hostname stuff.
      logger.should_receive(:error).twice
      @connection.socket
    end

    describe "once a connection is establised" do
      before do
        @socket = StringIO.new
        @tcp_socket_class.stub!(:new).and_return(@socket)
        @connection = Trending::Graphite::Connection.new('localhost', 2003, @tcp_socket_class)
      end

      it "writes data to the socket in graphite's format" do
        @connection.stub!(:timestamp).and_return(1298765441)
        @connection.write('/', 25, :namespace => [:system, "www5", :disk_utilization, :percentage])
        @socket.string.should == "system.www5.disk_utilization.percentage./ 25 1298765441\n"
      end

    end

  end

end