Class {
	#name : 'NexLoggerTest',
	#superclass : 'TestCase',
	#instVars : [
		'logger',
		'memoryAppender'
	],
	#category : 'NexUtils-Logging-Tests-Core',
	#package : 'NexUtils-Logging-Tests',
	#tag : 'Core'
}

{ #category : 'running' }
NexLoggerTest >> setUp [
	super setUp.

	memoryAppender := NexMemoryAppender new.
	logger := NexLogger new.
	logger clearAppenders. "Standard Transcript entfernen"
	logger addAppender: memoryAppender.

]

{ #category : 'tests' }
NexLoggerTest >> testAppenderManagement [

	self assert: logger appenders size equals: 1.
	logger removeAppender: memoryAppender.
	self assert: logger appenders isEmpty.
]

{ #category : 'tests' }
NexLoggerTest >> testBlockEvaluationPerformance [
	"Prüfen, ob Blöcke NUR ausgeführt werden, wenn das Level passt"
	| wasEvaluated |
	
	wasEvaluated := false.
	
	logger level: #ERROR.
	
	"Info ist unterhalb von Error, Block darf NICHT ausgeführt werden"
	logger info: [ wasEvaluated := true. 'Teure Berechnung' ].
	
	self deny: wasEvaluated description: 'Block wurde ausgeführt, obwohl Level zu niedrig war!'.
	
	"Jetzt testen wir den positiven Fall"
	logger error: [ wasEvaluated := true. 'Fehler' ].
	self assert: wasEvaluated description: 'Block wurde nicht ausgeführt, obwohl Level passte.'
]

{ #category : 'tests' }
NexLoggerTest >> testLogLevelFiltering [
	"Prüfen, ob Level eingehalten werden"
	logger level: #INFO.
	
	logger info: 'Info Message'.
	logger debug: 'Debug Message'. "Sollte ignoriert werden"
	logger error: 'Error Message'.
	
	self assert: memoryAppender logs size equals: 2.
	self assert: (memoryAppender logs first includesSubstring: 'Info Message').
	self assert: (memoryAppender logs last includesSubstring: 'Error Message').

]
