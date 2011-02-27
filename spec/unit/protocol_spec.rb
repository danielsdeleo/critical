require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

# TODO: separate concerns.
# currently:
#   ## IN Critical::Subprocess ##
#       if msg = reader.gets(nil)
#         yield DequeuedTask.new(msg, reader)
#       else
#         # bogus connection -- no data. skip it.
#         log.debug { "connection #{reader.inspect} had no data, skipping it." }
#         reader.flush
#         reader.close
#       end
#       # EAGAIN means another worker grabbed the connection or there isn't one there
#     rescue Errno::EAGAIN
#       nil
#       # ECONNABORTED should be rare, but outside programs may write to the job
#       # queue so we have to be vigilent
#     rescue Errno::ECONNABORTED
#       log.debug { "Connection #{reader.inspect} aborted" }
#       nil
#
#   ## IN Critical::MonitorRunner ##
#     each_message(@ipc) do |task|
#       # async: ack, then execute
#       task.ack
#       run_monitor(task.message.chomp)
#     end
#     
# change to:
#   # Parent/sender-side
#   client = Protocol::Client.new(io_obj)
#   client.publish_task(task_url)
#
#   # worker/child-side
#   client = Protocol::Client.new(io_obj)
#   client.accept_task do |task|
#     task.ack
#     run_monitor(task.monitor_url)
#   end
# 


describe Protocol do
  before do
    @io = StringIO.new
    @client = Protocol::Client.new(@io)
  end

  it "writes a message to an IO object" do
    @client.publish_task('/disks/df(/)')
    @io.string.should == "/disks/df(/)\n.\n"
  end

  it "reads a message from an IO object" do
    @io << "/disks/df(/)\n.\n"
    @io.rewind
    @client.accept_task do |task|
      task.url.should == '/disks/df(/)'
      task.ack
    end
    @io.string.should match(/ACK\n\.\n/)
  end

  it "acks a message" do
    @io << "/disks/df(/)\n.\n"
    @io.rewind
    @client.accept_task do |task|
      task.ack
    end
    @io.string.should match(/ACK\n\.\n\Z/)
  end

  it "rejects bogus messages" do
    @io << "/disks/df(/)\n\n" # no ".\n" at the end
    @io.rewind
    @client.accept_task do |task|
      task.ack
    end
    @io.string.should match(/REJECTED\nBad Format\n.\n\Z/)
  end

end