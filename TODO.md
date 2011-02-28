# TODOs and Maybes #

## TODO NOW ##
* fix the relationship between metrics, monitors, and metric\_collection\_instances.
  currently metrics are collected in metric\_collection\_instances, but you can't
  define methods there. not-so-cool workaround is in the cluster metric
* message sending needs to IO.select(nil,[writers],nil, timeout) so it doesn't
  deadlock if all the workers are dead/busy
* retries after respawning workers in the above scenario
* reimplement scheduling (linked list?)
* finish integration between output handling and new expectation system
* integrate ohai so you can have auto-monitors (e.g., loop over all available disks)

## TODO ##
* CLI client to submit a task to the queue manually
* figure out stable protocol so other programs/libs/langs can submit jobs to the queue
* test/run once mode: run individual metrics sequentially in single process and exit
* retry logic on failed expectations (i.e. try again every 1m 5 times after a failure)
  probably a second socket to "write back" to the scheduler with status updates
* debug method within monitors, take a block and pp the output when verbosity is on for collection
* Finish "story mode"
* live code reloading
* manpages (ronn)
* instantiate metrics from serializable data

## Maybe ##
* use kgio instead of the built-ins.
* log file load/search tool for ruby formatted logs -- a simple library to do that, plus irb wrapping
* conf.d/ system, load .rb files from it?
* json or yaml files support (for integration w/ cfg mgrs)
* privilege separation, run some workers as root, others not.
 
## STDLIB ##
Should focus on full stack testing where sensible:

* load avg
# CPU
* df
* free mem
* network i/o
* disk i/o
* REST (HTTP verbs)
* integration monitoring for web apps
* email reading (e.g., for verification emails)
* DB stats SQL and common NoSQL
* stats from instrumented web/app servers
* log reader?
