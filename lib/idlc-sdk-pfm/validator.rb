module Pfm
  module Validator
    # This is here to hold attr_accessor data for Validator context variables
    class Context
      def self.add_attr(name)
        @attributes ||= []

        unless @attributes.include?(name)
          @attributes << name
          attr_accessor(name)
        end
      end

      def self.reset
        return if @attributes.nil?

        @attributes.each do |attr|
          remove_method(attr)
        end

        @attributes = nil
      end
    end

    def self.reset
      @context = nil
    end

    def self.context
      @context ||= Context.new
    end

    def self.add_attr_to_context(name, value = nil)
      sym_name = name.to_sym
      Pfm::Validator::Context.add_attr(sym_name)
      Pfm::Validator::TemplateHelper.delegate_to_app_context(sym_name)
      context.public_send("#{sym_name}=", value)
    end

    module TemplateHelper
      def self.delegate_to_app_context(name)
        define_method(name) do
          Pfm::Validator.context.public_send(name)
        end
      end

      def year
        Time.now.year
      end
    end
  end
end
