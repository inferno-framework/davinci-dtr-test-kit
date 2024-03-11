require_relative 'record_response_route'

module Inferno
  module DSL
    module Runnable
      def record_response_route(method, path, tags, build_response, resumes: ->(_) { true }, &block)
        route_class = Class.new(Inferno::DSL::RecordResponseRoute) do |klass|
          klass.singleton_class.instance_variable_set(:@build_response_block, build_response)
          klass.singleton_class.instance_variable_set(:@test_run_identifier_block, block)
          klass.singleton_class.instance_variable_set(:@tags, Array.wrap(tags))
          klass.singleton_class.instance_variable_set(:@resumes, resumes)
        end

        route(method, path, route_class)
      end
    end
  end
end
