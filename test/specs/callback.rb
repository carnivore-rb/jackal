require 'jackal'

module TestNamespace
  module Worker
    class MyCallback < Jackal::Callback
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
end
