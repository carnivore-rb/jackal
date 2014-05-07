require 'jackal'

module TestNamespace
  module Worker
    class MyCallback < Jackal::Callback
    end
  end
end

describe 'Jackal::Callback' do

  before do
    cwd = File.dirname(__FILE__)
    Carnivore::Config.configure(
      :config_path => File.join(cwd, 'config/test.json')
    )
    @runner = Thread.new do
      require 'jackal/loader'
    end
    source_wait(:setup)
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

end
