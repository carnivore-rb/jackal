require 'jackal'

module TestNamespace
  module Worker
    class MyCallback < Jackal::Callback

      def valid?(*_)
        true
      end

      def execute(*_)
        event!(:test, :testing => true)
      end

    end
  end
end

describe Jackal::Callback do

  before do
    @runner = run_setup(:test)
  end

  after do
    Carnivore::Supervisor.supervisor.terminate
    @runner.terminate
  end

  it 'should run' do
    Carnivore::Supervisor.supervisor[:test_namespace_worker_input].name
    Carnivore::Supervisor.supervisor[:test_namespace_worker_output].name
    ->{ Carnivore::Supervisor.supervisor[:test_namespace_worker_error].name }.must_raise NoMethodError
  end

  it 'should run (double to ensure re-config)' do
    Carnivore::Supervisor.supervisor[:test_namespace_worker_input].name
    Carnivore::Supervisor.supervisor[:test_namespace_worker_output].name
    ->{ Carnivore::Supervisor.supervisor[:test_namespace_worker_error].name }.must_raise NoMethodError
  end

  it 'should process message' do
    Carnivore::Supervisor.supervisor[:test_namespace_worker_input].transmit(
      Jackal::Utils.new_payload(:test, :test_data => :ohai)
    )
    source_wait{ !MessageStore.messages.empty? }
    MessageStore.messages.first[:name].to_s.must_equal 'event'
  end
end
