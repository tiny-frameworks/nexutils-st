Class {
	#name : 'NexFileAppenderTest',
	#superclass : 'TestCase',
	#instVars : [
		'testFile',
		'appender'
	],
	#category : 'NexUtils-Logging-Tests-Appenders',
	#package : 'NexUtils-Logging-Tests',
	#tag : 'Appenders'
}

{ #category : 'running' }
NexFileAppenderTest >> setUp [

	super setUp.

	testFile := (FileSystem disk workingDirectory / ('nexlogger-test-' , 999999 atRandom printString , '.log')) asFileReference.
	appender := NexFileAppender newOn: testFile.
]

{ #category : 'running' }
NexFileAppenderTest >> tearDown [

	appender lockFile releaseLock.
	testFile ensureDelete.
	
	super tearDown
]

{ #category : 'tests' }
NexFileAppenderTest >> testAppenderWritesWithLocking [

	appender useLocking: true.
	appender recordTag: 'INFO' message: 'Locked Test' payload: nil.
	
	self assert: testFile exists.
	self assert: (testFile contents includesSubstring: 'Locked Test').
	self deny: appender lockFile isLocked "Lock muss nach dem Schreiben gelöscht sein"
]

{ #category : 'tests' }
NexFileAppenderTest >> testFileCreationAndWriting [

	self deny: testFile exists.
	
	"Wir simulieren den Aufruf vom Logger (RecordTag -> Record)"
	appender recordTag: 'TEST' message: 'Hallo Datei'.
	
	self assert: testFile exists.
	self assert: (testFile contents includesSubstring: 'Hallo Datei').
	self assert: (testFile contents includesSubstring: '[TEST]').
]
