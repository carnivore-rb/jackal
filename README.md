# Jackal

Run your carnivores.

## Configuration

```json
{
  "jackal": {
    "require": [
      "carnivore-http",
      "fubar-helloer"
    ]
  },
  "fubar": {
    "helloer": {
      "sources": {
        "input": {
          ...
        },
        "output": {
          ...
        },
        "error": {
          ...
        }
      },
      "callbacks": [
        "Fubar::Helloer::SayHello"
      ],
      "config": {
        "output_prefix": "Received message: "
      }
    }
  }
}
```

* `jackal` provides subsystem configuration
  * `require` libraries to load at startup
* `fubar` configuration of components (snake cased top level module)
  * `helloer` configuration of specific component (snake cased second level module)
    * `sources` configuration for carnivore sources
    * `callbacks` callback class names to initialize and attach to input source
    * `config` configuration hash used by callbacks

## Jackal Callbacks

Jackal callbacks are subclassed Carnivore callbacks adding a bit more structure. The
general implementation of a Jackal callback:

```ruby
module Fubar
  module Helloer
    class SayHello < Jackal::Callback

      def valid?(message)
        super do |payload|
          payload.get(:data, :helloer, :output)
        end
      end

      def execute(message)
        failure_wrap(message) do |payload|
          info config[:output_prefix] + payload.get(:data, :helloer, :output)
          job_completed(:helloer, payload, message)
        end
      end

    end
  end
end
```

## Testing

Jackal provides test helpers building upon the helpers provided by
Carnivore.

### jackal-test

This executable will load minitest and auto run all files matched
by the glob: `test/specs/*.rb`.

## Info

* Repository: https://github.com/carnivore-rb/jackal
* Carnivore: https://github.com/carnivore-rb/carnivore
* IRC: Freenode @ #carnivore