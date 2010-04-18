module Critical
  module DSL
    module StoryMonitorDSL
      
      def Story(title, &block)
        story = StoryMonitor.new(title, &block)
        story.fqn = current_namespace + '/' + story.to_s
        push story
        story
      end
      
    end
  end
end