# Plans, Thoughts, Half-Baked Ideas, Etc. #

## TODO.next ##
Diagnostic / FailureReport class
	- failures from helper methods (like when fields has a bad regexp that doesn't match) go here
	- should have some way for failures to be silent or optional, for example if we get a failure
	  in the fields method but the user has their own code to deal with it, this should be discarded
	  instead of bubbling up an alert.
	- expectation failures go here
	- should be (eventually) to_json-able for when it needs to go over the wire.
Implement Expectations, i.e., result.when_processed.is expected\_to\_be(something)

## TODO.after ##
live reload somehow...
	implement == on metric collectors
	implement some sort of merge/reload on monitor group using the above
a real scheduler. what about ruby cron clones (for examples or use/steal)

## TODO.sometime ##
* retry logic on failed expectations (i.e. try again every 1m 5 times after a failure)
* look @ nagios and collectd docco for typical check types, start a std lib
of metric collectors
* rest-client integration (see above)
* unencumbered integration for BDD-esque "integration" monitoring?

## STDLIB stuff ##
* load avg
* df
* free mem
* network i/o

## Random Ideas ##
* command line app to run 1/more checks
* have some type of warning state for failed expectations
  use a duration setting to escalate past 'warning' to 'failed'

## Server Arch ##
The server needs to have 3 parts or be 3 separate servers:

1. 	Alert Server: 
   	manages sending notifications via twit, email, etc. Should have some sort of
   	DSL for managing what alerts get sent, etc. based on source, time of day,
		whatever
2.	Trend Server: 
		stores data from agents, allows queries of said data via API, shows pretty
		graphs using js to browsers
3.	Agent Mgmt Server:
		keeps track of which checks go to which agents, probably via some mechanism
		similar to how chef decides which cookbooks go to which nodes. May be possible
		to piggy-back on a chef-server via remote file/directory and node attributes,
		if not long term, then at least to get started.
		
## Virtual Nodes ##
Though I seem to have picked the agent-based approach, need to support virtual
nodes ASAP. This is good for things like hitting a webserver from a 
non-localhost IP. Will also allow "agentless" monitoring via SNMP if someone
is crazy enough to implement SNMP checks. Also good for everyone's favorite,
ping-a-server-to-make-sure-it-still-exists