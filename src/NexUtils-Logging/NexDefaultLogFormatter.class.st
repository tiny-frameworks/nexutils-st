"
I format log records into human-readable plain text strings.

I format messages into the default layout:
  [LEVEL] Message (key1=value1 key2=value2)

If no payload is provided, the parenthesized payload section is omitted.

"
Class {
	#name : 'NexDefaultLogFormatter',
	#superclass : 'NexLogMessageFormatter',
	#category : 'NexUtils-Logging-Formatters',
	#package : 'NexUtils-Logging',
	#tag : 'Formatters'
}

{ #category : 'formatting' }
NexDefaultLogFormatter >> formatMessage: msg tag: tagString [

	"Standardformat: [TAG] message (ohne Timestamp; Timestamp kann hier ergänzt werden)"
	^ '[' , tagString , '] ' , msg
]

{ #category : 'formatting' }
NexDefaultLogFormatter >> formatMessage: msg tag: tagString payload: aPayload [
	| stream payloadDict |
	
	payloadDict := self payloadAsDictionary: aPayload.
	
	stream := String new writeStream.
	stream 
		nextPut: $[;
		nextPutAll: tagString;
		nextPutAll: '] ';
		nextPutAll: msg.

	payloadDict ifNotEmpty: [
		stream nextPutAll: ' ('.
		payloadDict keysAndValuesDo: [ :key :val |
			stream 
				nextPutAll: key asString;
				nextPut: $=;
				print: val;
				nextPutAll: ' ' ].
		"Letztes Leerzeichen entfernen und Klammer schließen"
		stream position: stream position - 1.
		stream nextPut: $) ].

	^ stream contents
]
