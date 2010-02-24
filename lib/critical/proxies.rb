module Critical
  module Proxies
    class ProxyBase
      instance_methods.each { |m| undef_method m unless m.to_s =~ /^(__|respond_to)/ }
    end
    
    class MetricReportProxy < ProxyBase
      include Expectations::Expectable
      
      attr_reader :target, :owner

      def initialize(target, owner)
        target = target.target if target.respond_to?(:target) #don't make a proxy sandwich
        @target, @owner = target, owner
      end
      
      def proxied?
        true
      end

      def report
        @owner.report
      end
      
      alias :proxy_respond_to? :respond_to?
      def respond_to?(method_name, include_private=false)
        @target.respond_to?(method_name, include_private) || self.proxy_respond_to?(method_name, include_private)
      end

      def method_missing(method_name, *args, &block)
        target.send(method_name, *args, &block)
      end
      
      def send(method_name, *args, &block)
        @target.send(method_name, *args, &block)
      end
      
    end
    
  end
  
end