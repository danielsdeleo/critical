require 'thread'

module Critical
  class Scheduler
    class Task
      attr_reader :next_run, :interval, :block
      
      def initialize(interval, next_run=nil, &block)
        @interval, @block = interval, block
        @next_run = next_run || Time.new.to_i
      end
      
      # Reschedules this task for the next time it should run
      def succ!
        @next_run += @interval
      end
    end
    
    class TaskList
      include Loggable
      
      def self.quantum
        5
      end
      
      attr_reader :tasks, :queue
      
      def initialize(*schedule_tasks)
        @queue = Queue.new
        @tasks = Hash.new { |hsh, key| hsh[key] = [] }
        schedule_tasks.flatten.each { |t| schedule(t) }
      end
      
      def run
        log.debug { "starting scheduler loop" }
        loop do
          run_tasks
          sleep_until_next_run
        end
      end
      
      def schedule(task)
        @tasks[quantize(task.next_run)] << task
      end
      
      def sleep_until_next_run
        time_to_sleep = next_run - current_time
        time_to_sleep = 0 if time_to_sleep < 0
        sleep(time_to_sleep)
      end
      
      def run_tasks
        buckets = task_buckets_to_run.map { |bucket| tasks.delete(bucket) }.compact
        buckets.each do |tasks_in_bucket|
          tasks_in_bucket.each do |task|
            run_task(task)
          end
        end
      end
      
      def next_run
        @tasks.keys.sort.first
      end
      
      private
      
      def task_buckets_to_run
        now = current_time
        @tasks.keys.select { |t| t <= now }.sort
      end
      
      def run_task(task)
        queue.push task.block
        task.succ!
        schedule task
      end
      
      def quantum
        self.class.quantum
      end
      
      def quantize(int)
        int - (int % quantum)
      end
      
      def current_time
        Time.new.to_i
      end
    end
    
  end
end