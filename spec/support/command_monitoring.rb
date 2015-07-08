module Mongo
  module CommandMonitoring

    # Represents a specification.
    #
    # @since 2.0.0
    class Spec

      attr_reader :data
      attr_reader :collection_name
      attr_reader :database_name
      attr_reader :tests

      def initialize(file)
        @test = YAML.load(ERB.new(File.new(file).read).result)
        @data = @test['data']
        @collection_name = @test['collection_name']
        @database_name = @test['database_name']
        @tests = @test['tests'].map{ |t| Test.new(t) }
      end
    end

    class Test

      attr_reader :description
      attr_reader :operation
      attr_reader :expectations

      def initialize(test)
        @description = test['description']
        @operation = Operation.new(test['operation'])
        @expectations = test['expectations'].map{ |name, e| Expectation.new(name, e) }
      end
    end

    class Operation

      attr_reader :name
      attr_reader :arguments

      def initialize(operation)
        @name = operation['name']
        @arguments = operation['arguments']
      end

      def execute(collection)
        collection.send(name, arguments['filter']).to_a
      end
    end

    class Expectation

      MAPPINGS = {
        'command_started_event' => :started,
        'command_succeeded_event' => :succeeded,
        'command_failed_event' => :failed,
      }

      def command_name
        @expectation['command_name']
      end

      def database_name
        @expectation['database_name']
      end

      def tested_method
        case @name
        when 'command_started_event' then 'command'
        when 'command_succeeded_event' then 'reply'
        when 'command_failed_event' then 'message'
        end
      end

      def expected_value
        case @name
        when 'command_started_event' then @expectation['command']
        when 'command_succeeded_event' then @expectation['reply']
        when 'command_failed_event' then @expectation['message']
        end
      end

      def initialize(name, expectation)
        @name = name
        @expectation = expectation
      end

      def monitoring_call
        MAPPINGS[@name]
      end
    end
  end
end
