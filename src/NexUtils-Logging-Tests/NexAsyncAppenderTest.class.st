Class {
	#name : 'NexAsyncAppenderTest',
	#superclass : 'TestCase',
	#instVars : [
		'asyncAppender',
		'memoryAppender'
	],
	#category : 'NexUtils-Logging-Tests-Appenders',
	#package : 'NexUtils-Logging-Tests',
	#tag : 'Appenders'
}

{ #category : 'running' }
NexAsyncAppenderTest >> setUp [
	super setUp.

	memoryAppender := NexMemoryAppender new.
	asyncAppender := NexAsyncLogAppender decorate: memoryAppender.

]

{ #category : 'running' }
NexAsyncAppenderTest >> tearDown [

	asyncAppender stopWorker.
	
	super tearDown.
]

{ #category : 'tests' }
NexAsyncAppenderTest >> testAsyncLogging [
	
	"1. Nachricht schicken"
	asyncAppender recordTag: 'ASYNC' message: 'Schnell'.
	
	"2. Sofort prüfen - Queue ist wahrscheinlich noch nicht abgearbeitet"
	"Dieser Check ist theoretisch flaky, aber meistens ist der Test schneller als der Worker"
	self assert: memoryAppender logs isEmpty. 
	
	"3. FLUSH aufrufen - Warten bis alles durch ist"
	asyncAppender flush.
	
	"4. Jetzt MUSS es da sein"
	self assert: memoryAppender logs size equals: 1.
	self assert: (memoryAppender logs first includesSubstring: 'Schnell').
]
