require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Scheduler::Task do
  before do
    @time = Time.new
    Time.stub!(:new).and_return(@time)
    @task = Scheduler::Task.new("/cpu/load_avg(15)", 10)
  end
  
  it "uses now as the default scheduled time" do
    @task.next_run.should == @time.to_i
  end
  
  it "takes an interval between executions in the constructor" do
    @task.interval.should == 10
  end
  
  it "reschedules itself for the next execution" do
    @task.succ!
    @task.next_run.should == @time.to_i + 10
  end
  
  it "keeps the qualified name of a monitor to execute" do
    @task.monitor.should == "/cpu/load_avg(15)"
  end
end

describe Scheduler::TaskList do
  before do
    @time = Time.at(1268452029)
    Time.stub!(:new).and_return(@time)
    @list = Scheduler::TaskList.new
  end
  
  it "has a setting for time quantum" do
    Scheduler::TaskList.quantum.should == 5
  end
  
  it "takes a list of tasks in it's initializer" do
    first_task   = Scheduler::Task.new('/cpu/load_avg(15)', 10)
    second_task  = Scheduler::Task.new("/disks/df(/)",10, @time.to_i + 10)
    third_task   = Scheduler::Task.new("/web/get(http://localhost/)",10, @time.to_i + 20)
    list = Scheduler::TaskList.new(first_task, second_task, third_task)
    
    list.tasks.values.flatten.should include(first_task)
    list.tasks.values.flatten.should include(second_task)
    list.tasks.values.flatten.should include(third_task)
  end
  
  it "stores a task as quantized_time=>[task]" do
    task = Scheduler::Task.new('/host/uptime', 10)
    @list.schedule(task)
    @list.tasks.should == {1268452025 => [task]}
  end
  
  it "it runs a task by placing its monitor name on the queue and rescheduling the task" do
    task = Scheduler::Task.new('/cpu/load_avg(5)', 75)
    task.next_run.should == 1268452029
    @list.send :run_task, task
    @list.queue.pop.should == "/cpu/load_avg(5)"
    @list.tasks.should == {1268452100 => [task]}
    task.next_run.should == 1268452104
  end
  
  describe "when tasks have been scheduled" do
    before do
      @first_task   = Scheduler::Task.new('/cpu/load_avg(15)', 10)
      @second_task  = Scheduler::Task.new("/disks/df(/)",10, @time.to_i + 10)
      @third_task   = Scheduler::Task.new("/web/get(http://localhost/)",10, @time.to_i + 20)
      @list.schedule(@first_task)
      @list.schedule(@second_task)
      @list.schedule(@third_task)
    end
    
    it "sleeps until the next scheduled task" do
      @list.should_receive(:sleep).with(0)
      @list.sleep_until_next_run
      @list.tasks.delete(1268452025)
      @list.should_receive(:sleep).with(6)
      @list.sleep_until_next_run
    end

    it "lists all of the time buckets that should be run" do
      @later_time = @time + 15
      Time.stub!(:new).and_return(@later_time)
      @list.send(:task_buckets_to_run).should == [1268452025, 1268452035]
    end
    
    it "runs all of the tasks that are due" do
      @list.queue.length.should == 0
      @later_time = @time + 15
      Time.stub!(:new).and_return(@later_time)
      
      @list.run_tasks
      
      @list.next_run.should == 1268452035
      @list.queue.pop.should == '/cpu/load_avg(15)'
      @list.queue.pop.should == '/disks/df(/)'
    end
  end
  
end