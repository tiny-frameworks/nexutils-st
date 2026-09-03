Class {
	#name : 'NexLoggerPayloadTest',
	#superclass : 'TestCase',
	#instVars : [
		'logger',
		'mockAppender'
	],
	#category : 'NexUtils-Logging-Tests-Core',
	#package : 'NexUtils-Logging-Tests',
	#tag : 'Core'
}

{ #category : 'running' }
NexLoggerPayloadTest >> setUp [

	super setUp.

	mockAppender := NexMockAppender new.
	logger := NexLogger new
		clearAppenders;
		addAppender: mockAppender;
		yourself.
]

{ #category : 'tests' }
NexLoggerPayloadTest >> testDefaultFormatterWithAssociationArrayPayload [

	logger 
		info: 'Peer connected' 
		payload: { #peerId -> 'node-42' . #ip -> '192.168.1.10' }.
	
	self assert: mockAppender lastFormattedMessage equals: '[INFO] Peer connected (peerId=''node-42'' ip=''192.168.1.10'')'

]

{ #category : 'tests' }
NexLoggerPayloadTest >> testDefaultFormatterWithDictionaryPayload [
	| payloadDict |
	
	payloadDict := Dictionary new.
	payloadDict at: #code put: 200.
	
	logger info: 'Response OK' payload: payloadDict.
	
	self assert: mockAppender lastFormattedMessage equals: '[INFO] Response OK (code=200)'

]

{ #category : 'tests' }
NexLoggerPayloadTest >> testDefaultFormatterWithoutPayload [

	logger info: 'System gestartet'.
	self assert: mockAppender lastFormattedMessage equals: '[INFO] System gestartet'

]

{ #category : 'tests' }
NexLoggerPayloadTest >> testJsonFormatterWithPayload [
	| jsonDict |
	
	mockAppender formatter: NexJsonLogFormatter new.
	
	logger 
		info: 'RPC Call' 
		payload: { #method -> 'ping' . #id -> 1 }.
	
	"JSON zurück in Dictionary parsen, um von Keys-Reihenfolge unabhängig zu testen"
	jsonDict := STONJSON fromString: mockAppender lastFormattedMessage.
	
	self assert: (jsonDict at: 'level') equals: 'INFO'.
	self assert: (jsonDict at: 'message') equals: 'RPC Call'.
	self assert: ((jsonDict at: 'payload') at: 'method') equals: 'ping'.
	self assert: ((jsonDict at: 'payload') at: 'id') equals: 1.
	self assert: (jsonDict includesKey: 'unixTS')
]
