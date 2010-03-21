# Plans, Thoughts, Half-Baked Ideas, Etc. #

## TODO.next ##
* validate monitors attributes (format, presence)
* should monitor names use parens instead of sq. brackets?
  that would make them look more like they do in the source, i.e.,
  df("/") in the source would be df("/") instead of df["/"] like it is now

## TODO.after ##
* is live reload possible?
	implement == on metric collectors
	implement some sort of merge/reload on monitor group using the above

## TODO.sometime ##
* retry logic on failed expectations (i.e. try again every 1m 5 times after a failure)
* look @ nagios and collectd docco for typical check types, start a std lib
of metric collectors
* rest-client inspired HTTP collector (probably use igrigorik's em-http-req though)
* unencumbered integration for BDD-esque "integration" monitoring?
* A no-op mode may be possible by "stubbing" #result...
* state transitions: have a warning state (maybe?) if over threshold, becomes alert if lasts too long;
  recovery from alert->warning->normal
* instantiate metrics from data over the wire so I can hit an API on the server and add/remove/update a check on clients


## STDLIB stuff ##
* load avg
* df
* free mem
* network i/o
* disk i/o

## Random Ideas ##
* command line app to run 1/more checks

## Server Arch ##
The server should have these 3 parts or be 3 separate servers:

1. 	Alert Server: 
   	manages sending notifications via twit, basecamp, email, etc. Should have some sort of
   	DSL for managing what alerts get sent, etc. based on source, time of day,
		whatever
		erlectricity?
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