# v0.3.18
* Add support for event generation

# v0.3.16
* Add `app_host` configuration helper method

# v0.3.14
* Add test scaffold generator
* Update carnivore constraint

# v0.3.12
* Set default verbosity to :info
* Support changing spec runner
* Add options scrubbing on startup

# v0.3.10
* Add `:array` to allowed values for configuration type in service registration

# v0.3.8
* Expansion of testing helpers
* Addition of `category` to service registration
* Set error into payload on failure

# v0.3.6
* Fix config library dependency constraints

# v0.3.4
* Scrub environment prior to shelling out
* Add service registration helper
* Extract payload directly if provided via source

# v0.3.2
* Add support for `pre` and `post` formatters

# v0.3.0
* Force source looping on `Callback#completed`
* Move HTTP hook configuration within jackal namespace
* Add support for using `spawn` on a per-process basis
* Link owner callback into formatters

# v0.2.4
* Fix nesting for orphan callback setup
* Add constant and memoization helpers into `Callback`

# v0.2.2
* Automatically forward payloads with no matches
* Fix input sources setup
* Update formatter to allow linking back to owner callback

# v0.2.0
* Add abstract payload formatter
* Provide common helper method to shell out
* Remove custom CLI and integrate bogo-cli

# v0.1.16
* Load HTTP hook directly prior to service start
* Fixes some issues with spec loads

# v0.1.14
* Move orphan handlers into source init arg

# v0.1.12
* Only output source configuration in debug mode
* Catch unprocessed messages and remove from bus

# v0.1.10
* Add flag to control verbosity

# v0.1.8
* Allow extra arguments to be passed through new_payload
* Spec helper updates

# v0.1.6
* Include default source for HTTP endpoints if used and configuration enables

# v0.1.4
* Add HTTP point builder api util
* Fetch payload from message if available
* Add checks for defined error source prior to transmission

# v0.1.2
* Update configuration convention to require toplevel namespace
* Clean up testing helper and setup
* Include basic test for proper setup

# v0.1.0
* Initial commit
