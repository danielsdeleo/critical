module Critical
  class StoryMonitor
    class Step
      include DSL::MonitorDSL
      attr_reader :title, :monitors, :story

      def initialize(title, story)
        @title, @story, @monitors = title, story, []
      end

      def push(monitor)
        @monitors << monitor
        self
      end
      alias :<< :push

      def story_data
        story.story_data
      end

      def collect(output_handler)
        @monitors.each { |m| m.collect(output_handler) }
      end

    end

    attr_reader :title, :steps

    def initialize(title, &block)
      @title, @steps = title, []
      if block_given?
        block.arity <= 0 ? instance_eval(&block) : yield(self)
      end
    end

    def to_s
      "story(#{title})"
    end

    def collect(output_handler)
      steps.each { |s| s.collect(output_handler) }
    end

    def step(*step_title_fragments)
      @steps << Step.new(step_title_fragments.join(" "), self)
    end

    def given(step_title)
      step("Given", step_title)
    end
    alias :Given :given

    def when(step_title)
      step("When", step_title)
    end
    alias :When :when

    def then(step_title)
      step("Then", step_title)
    end
    alias :Then :then

    def story_data
      @story_data ||= {}
    end

  end
end