"
I format log records into single-line JSON strings suitable for machine processing and structured log collectors.

Output schema:
  {
    ""level"": ""INFO"",
    ""unixTS"": 1787671182,
    ""message"": ""Peer connected"",
    ""payload"": { ""peerId"": ""node-42"" }
  }

I use STONJSON for serialization.

"
Class {
	#name : 'NexJsonLogFormatter',
	#superclass : 'NexLogMessageFormatter',
	#category : 'NexUtils-Logging-Formatters',
	#package : 'NexUtils-Logging',
	#tag : 'Formatters'
}

{ #category : 'formatting' }
NexJsonLogFormatter >> formatMessage: msg tag: tagString [
	| dict |
	
	dict := Dictionary new.
	dict 
		at: 'level' put: tagString;
		at: 'unixTS' put: DateAndTime now asUnixTime ;
		at: 'message' put: msg.
	
	^ STONJSON toString: dict
]

{ #category : 'formatting' }
NexJsonLogFormatter >> formatMessage: msg tag: tagString payload: aPayload [
	| dict payloadDict |
	
	payloadDict := self payloadAsDictionary: aPayload.
	
	dict := Dictionary new.
	dict 
		at: 'level' put: tagString;
		at: 'unixTS' put: DateAndTime now asUnixTime;
		at: 'message' put: msg.

	payloadDict ifNotEmpty: [ 
		dict at: 'payload' put: payloadDict ].

	^ STONJSON toString: dict
]
