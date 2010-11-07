# Plans, Thoughts, Half-Baked Ideas, Etc. #

## BE AWARE ##
* Visibility into running process
  * how deep is the work queue?
  * how long do tasks take to get through?
* Operator overrides - submit a task to the queue manually

## TODO NOW ##
* message sending needs to IO.select(nil,[writers],nil, timeout) so it doesn't
  deadlock if all the workers are dead/busy
* retries after respawning workers in the above scenario
* reimplement scheduling using linked list
* cleanup integration between output handling and new expectation system

## TODO ##
* test mode: run individual metrics and exit
* retry logic on failed expectations (i.e. try again every 1m 5 times after a failure)
  probably a second socket to "write back" to the scheduler with status updates
* debug method within monitors, take a block and pp the output when verbosity is on for collection
* Implement/finish "story mode"
* log file load/search tool for ruby formatted logs -- a simple library to do that, plus irb wrapping
* live code reloading
* manpages (ronn)
* start a std lib of metric collectors
* instantiate metrics from data over the wire so I can hit an API on the server and add/remove/update a check on clients

## Maybe ##
* conf.d/ system, load .rb files from it?
* conf.d/ system, provide a shortcut for loading json or yaml files from it (for integration w/ cfg mgrs)
* no-op mode?
 
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
