# Plans, Thoughts, Half-Baked Ideas, Etc. #

## TODO.next ##
* **FUCKIN IMPORTANT** cleanup integration between output handling and new expectation system
* test mode: run every metric once (sequentially) and exit
* verbosity: be able to turn successful expectations on and off (globally? in text output handler?)
* validate monitors attributes (format, presence)

## TODO.after ##
* debug method within monitors, take a block and pp the output when verbosity is on for collection
* pre-forking shamelessly stolen from unicorn
* unencumbered/cucumber integration *and|or* cheap knock-off
* log file load/search tool for ruby formatted logs -- a simple library to do that, plus irb wrapping

## TODO.sometime ##
* conf.d/ system, load .rb files from it?
* conf.d/ system, provide a shortcut for loading json or yaml files from it (for integration w/ cfg mgrs)
* live reload
* manpages: pandoc/rtfm (ruby)
* retry logic on failed expectations (i.e. try again every 1m 5 times after a failure)
* look @ nagios and collectd docco for typical check types, start a std lib
of metric collectors
* A no-op mode may be possible by "stubbing" #result...
* states and state transitions: i.e., there is a warning and a critical state
* instantiate metrics from data over the wire so I can hit an API on the server and add/remove/update a check on clients
 
## STDLIB stuff ##
Should focus on full stack testing (i.e., send an email and check it to test email server) where sensible:

* load avg
* df
* free mem
* network i/o
* disk i/o
* REST (HTTP verbs)
* full-stack integration monitoring
* email reading (e.g., for verification emails)

## Server Arch ##
The server should have these 3 parts or be 3 separate servers:

1. 	Alert Server: 
   	manages sending notifications via twit, basecamp, email, etc. Should have some sort of
   	DSL for managing what alerts get sent, etc. based on source, time of day, etc.
2.	Trend Server: 
		stores data from agents, allows queries of said data via API, shows pretty
		graphs using js to browsers
3.	Agent Mgmt Server:
		keeps track of which checks go to which agents, probably via some mechanism
		similar to how chef decides which cookbooks go to which nodes. May be possible
		to piggy-back on a chef-server via remote file/directory and node attributes,
		if not long term, then at least to get started.
