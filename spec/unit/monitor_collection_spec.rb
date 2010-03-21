require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe MonitorCollection do
  before do
    @collection = MonitorCollection.instance
    @collection.reset!
  end
  
  describe "adding metrics to the collection" do
    before do
      @metric_class = Class.new(Critical::Monitor)
      @metric_class.metric_name = :df
      @metric_class.monitors(:filesystem)
      @metric_class.collects { :no_op_for_testing }
      
      @monitor = @metric_class.new
    end
    
    it "creates a task for each monitor" do
      @collection.push @monitor
      @collection.tasks.should have(1).task
    end

    it "maps monitors into a nested hash" do
      monitor = @monitor
      @collection.Monitor(:unix_boxes) do
        Monitor(:disks) do
          push monitor
        end
      end
      @collection.monitors.should == {:unix_boxes => {:disks => {:monitors => [@monitor]}}}
    end
    
    it "adds monitors to an existing nested hash" do
      monitor = @monitor
      @collection.Monitor(:unix_boxes) do
        Monitor(:disks) do
          push monitor
          push monitor
        end
        Monitor(:network) do
          push monitor
        end
      end
      expected = {:unix_boxes => {:disks => {:monitors => [@monitor, @monitor]}, :network => {:monitors => [@monitor]}}}
      @collection.monitors.should == expected
    end
    
    it "either silently replaces or raises when adding the same monitor twice in a namespace" do
      monitor = @monitor
      @collection.Monitor(:unix_boxes) do
        Monitor(:disks) do
          push monitor
          push monitor
        end
      end
      pending
    end
    
    it "allows monitors to peacefully coexist with sub-namespaces" do
      monitor = @monitor
      @collection.Monitor(:unix_boxes) do
        Monitor(:disks) do
          push monitor
        end
        push monitor
      end
      @collection.monitors.should == {:unix_boxes => {:monitors => [@monitor], :disks => {:monitors => [@monitor]}}}
    end
    
    it "looks up monitors given the monitor's name and namespace" do
      monitor = @monitor
      @collection.Monitor(:unix_boxen) do
        Monitor(:disks) do
          push monitor
        end
      end
      @collection.find(:unix_boxen, :disks, 'df()').should equal(monitor)
      @collection.find('unix_boxen/disks/df()').should equal(monitor)
    end
    
    it "gives nil if the monitor cannot be found" do
      @collection.find('df()').should be_nil
    end
    
    it "splits a namspace string into its elements" do
      @collection.split_namespaces('unix_boxen/disks/df()').should == [:unix_boxen, :disks, 'df()']
      @collection.split_namespaces('unix_boxen/disks/df(/)').should == [:unix_boxen, :disks, 'df(/)']
      @collection.split_namespaces('/unix_boxen/disks/df(/)').should == [:unix_boxen, :disks, 'df(/)']
    end
    
    it "gives the current namespace as a string" do
      namespace_str = nil
      @collection.Monitor(:unix_boxes) do
        Monitor(:disks) do
          namespace_str = current_namespace
        end
      end
      namespace_str.should == "/unix_boxes/disks"
    end
  end
  
end