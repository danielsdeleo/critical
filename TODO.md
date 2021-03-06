# TODOs and Maybes #

## TODO NOW ##
* generalize trending code, don't depend on a running graphite.
* finish integration between output handling and new expectation system
* default to a less noisy log format, ruby format was a neat idea but I
  don't like it.
* Steal ShellOut from Chef for running external commands
* message sending needs to IO.select(nil,[writers],nil, timeout) so it doesn't
  deadlock if all the workers are dead/busy
* retries after respawning workers in the above scenario
* optimize scheduler
* run once mode:
  * return code non-zero for failure
  * show the results in a pretty format

## TODO ##
* allow metrics to be defined with less DSLism
  (i.e., class MyMetric < Metric::Base should do the necessary
  bookkeeping)
* Add primitives for common measurement types
  * counters (like for CPU time/percentage) should be easy
  * timers should be easy
* allow plugins and config declare gem deps, automate installing them.
  (probably bundler)
* Option to print the config in summary form for troubleshooting complex
  configs
* CLI client to submit a task to the queue manually
* figure out stable protocol so other programs/libs/langs can submit jobs to the queue
* State Machine
  * does this go in the client at all?
  * if implemented in client, probably need to have monitors return
    result, main loop will need to track the open sockets...
* debug method within monitors, take a block and pp the output when verbosity is on for collection
* Finish "story mode"
* manpages (ronn)

## Maybe ##
* integrate ohai so you can have auto-monitors (e.g., loop over all available disks)
* instantiate metrics from serializable data
* live code reloading
* use kgio instead of the built-ins.
* privilege separation, run some workers as root, others not.

## STDLIB ##
Support story mode by builing primitives for full stack testing where sensible.

* load avg
* network i/o
* disk i/o
* REST (HTTP verbs)
* integration monitoring for web apps
* email reading (e.g., for verification emails)
* DB stats SQL and common NoSQL
* stats from instrumented web/app servers
* log reader?
