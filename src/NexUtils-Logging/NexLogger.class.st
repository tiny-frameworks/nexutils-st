"
Copyright 2026 Georg Hagn
SPDX-License-Identifier: Apache-2.0

I am the central logger component of the NexUtils-Logging framework. 

I manage a collection of log appenders and control the current log level filtering. I support traditional string logging, lazy evaluation via block closures, and structured logging with payload key-value pairs (slog-style).

Public API and Key Messages:
- info: / warn: / error: / debug: / fatal: - Basic logging methods taking a String or Block.
- info:payload: (and level variants) - Structured logging taking message and payload (Dictionary or Array of Associations).
- level: - Sets the active log level (e.g. #DEBUG, #INFO, #WARN, #ERROR, #FATAL).
- addAppender: / removeAppender: - Configures log outputs.

Example:
   | log |
   log := NexLogger new.
   log info: 'Peer connected' payload: { #peerId -> ''node-42'' }.

"
Class {
	#name : 'NexLogger',
	#superclass : 'Object',
	#instVars : [
		'level',
		'appenders'
	],
	#classInstVars : [
		'defaultLogger'
	],
	#category : 'NexUtils-Logging-Core',
	#package : 'NexUtils-Logging',
	#tag : 'Core'
}

{ #category : 'private - initialization' }
NexLogger class >> debugLevel [

	^ 10.
]

{ #category : 'accessing' }
NexLogger class >> default [

    ^ defaultLogger ifNil: [ 
        defaultLogger := self new 
            addAppender: NexTranscriptAppender new;
				level: #ERROR;
            yourself 
    ]
]

{ #category : 'accessing' }
NexLogger class >> default: aLogger [

    defaultLogger := aLogger
]

{ #category : 'error handling' }
NexLogger class >> error: aStringOrBlock [

    self default error: aStringOrBlock
]

{ #category : 'private - initialization' }
NexLogger class >> errorLevel [

	^ 40.
]

{ #category : 'private - initialization' }
NexLogger class >> fatalLevel [

	^ 50.
]

{ #category : 'accessing - structure variables' }
NexLogger class >> info: aStringOrBlock [

    self default info: aStringOrBlock
]

{ #category : 'private - initialization' }
NexLogger class >> infoLevel [

	^ 20.
]

{ #category : 'instance creation' }
NexLogger class >> new [
	"Erzeugt Logger mit Transcript Appender als Default"
	defaultLogger := nil.
	
	^ super new 
		addAppender: (NexTranscriptAppender new);
		yourself
]

{ #category : 'private - initialization' }
NexLogger class >> warnLevel [

	^ 30.
]

{ #category : 'adding' }
NexLogger >> addAppender: anAppender [

	appenders at: (anAppender name asSymbol) put: anAppender.

]

{ #category : 'accessing' }
NexLogger >> appenders [

	^ appenders
]

{ #category : 'cleanup' }
NexLogger >> clearAppenders [

	appenders removeAll.
	
	^ self
]

{ #category : 'logging' }
NexLogger >> debug: aMsgOrBlock [

	(level <= self class debugLevel) ifTrue: [ 
		self logInternalWithTag: 'DEBUG' message: aMsgOrBlock value payload: nil.
	].

	^ self
]

{ #category : 'logging' }
NexLogger >> debug: aMsgOrBlock payload: aPayload [

	(level <= self class debugLevel) ifTrue: [ 
		self logInternalWithTag: 'DEBUG' message: aMsgOrBlock value payload: aPayload
	].

	^ self
	

]

{ #category : 'error handling' }
NexLogger >> error: aMsgOrBlock [

	(level <= self class errorLevel) ifTrue: [ 
		self logInternalWithTag: 'ERROR' message: aMsgOrBlock value payload: nil.
	].
	^ self
]

{ #category : 'error handling' }
NexLogger >> error: aMsgOrBlock payload: aPayload [

	(level <= self class errorLevel) ifTrue: [ 
		self logInternalWithTag: 'ERROR' message: aMsgOrBlock value payload: aPayload
	].
	^ self
]

{ #category : 'logging' }
NexLogger >> fatal: aMsgOrBlock [

	(level <= self class fatalLevel) ifTrue: [ 
		self logInternalWithTag: 'FATAL' message: aMsgOrBlock value payload: nil.
	].
	^ self
]

{ #category : 'logging' }
NexLogger >> fatal: aMsgOrBlock payload: aPayload [

	(level <= self class fatalLevel) ifTrue: [ 
		self logInternalWithTag: 'FATAL' message: aMsgOrBlock value payload: aPayload
	].
	^ self
]

{ #category : 'formatting' }
NexLogger >> formatMessage: msg tag: tagString [

	"Standardformat: [TAG] message (ohne Timestamp; Timestamp kann hier ergänzt werden)"
	^ '[' , tagString , '] ' , msg
]

{ #category : 'initialization' }
NexLogger >> formatter: aFormatter [
	"Helper: Setzt den Formatter für ALLE aktuellen Appender (Convenience)"
	
	appenders do: [ :each | each formatter: aFormatter ].

]

{ #category : 'running' }
NexLogger >> handleError: aString [
	"handle single message - override oder setze target via block"
	"Default: schreibe in Transcript (oder delegiere an inner-appender)"

	Transcript show: aString; cr. 

]

{ #category : 'logging' }
NexLogger >> info: aMsgOrBlock [
	"Logs an INFO level message accompanied by structured payload data.
	
	aMsgOrBlock - A String or a zero-argument Block returning a String (lazy evaluation).
	aPayload    - A Dictionary or an Array of Associations (e.g. { #key -> 'val' }).
	
	Example:
	  logger info: 'Request processed' payload: { #durationMs -> 15 . #status -> 200 }"
	
	(level <= self class infoLevel) ifTrue: [ 
		self logInternalWithTag: 'INFO' message: aMsgOrBlock value payload: nil.
	].
	^ self
]

{ #category : 'logging' }
NexLogger >> info: aMsgOrBlock payload: aPayload [

	(level <= self class infoLevel) ifTrue: [ 
		self logInternalWithTag: 'INFO' message: aMsgOrBlock value payload: aPayload 
	].
	
	^ self
]

{ #category : 'initialization' }
NexLogger >> initialize [

	super initialize.
	
	level := self class infoLevel.
	appenders := IdentityDictionary new.

	^ self

]

{ #category : 'accessing' }
NexLogger >> level: aLevelSymbol [
	"aLevelSymbol kann sein: [ #DEBUG | #INFO | #WARN | #ERROR | #FATAL ]"
	| selector val |
	
	selector := (aLevelSymbol asString asLowercase , 'Level') asSymbol.
	[ 
		val := (self class perform: selector). 
		level := val .
	] onErrorDo: [ 
		self handleError: MessageNotUnderstood .
	] .

	
]

{ #category : 'private - logging' }
NexLogger >> logInternalWithTag: tagString message: msg [
	"Wir delegieren jetzt die Rohdaten an die Appender,
	 damit jeder Appender selbst entscheiden kann, wie er formatiert."
	
	appenders valuesDo: [:each |
		[ each recordTag: tagString message: msg ] 
			on: Error 
			do: [:ex | self handleError: 'Appender Error: ', ex description ]
	].
]

{ #category : 'logging' }
NexLogger >> logInternalWithTag: tagString message: msg payload: aDictionaryOrArray [
	"Private - Delegates raw log data to all registered appenders. 
	Catches and handles errors thrown by individual appenders to protect the main execution path."
	
	appenders valuesDo: [ :each |
		[ each recordTag: tagString message: msg payload: aDictionaryOrArray ] 
			on: Error 
			do: [ :ex | self handleError: 'Appender Error: ', ex description ] ]
]

{ #category : 'removing' }
NexLogger >> removeAppender: anAppender [  

	appenders removeKey: (anAppender name asSymbol) ifAbsent: [] .

	^ self
]

{ #category : 'logging' }
NexLogger >> warn: aMsgOrBlock [
	
	(level <= self class warnLevel) ifTrue: [ 
		self logInternalWithTag: 'WARN' message: aMsgOrBlock value payload: nil.
	].
	^ self
]

{ #category : 'logging' }
NexLogger >> warn: aMsgOrBlock payload: aPayload [
	
	(level <= self class warnLevel) ifTrue: [ 
		self logInternalWithTag: 'WARN' message: aMsgOrBlock value payload: aPayload
	].
	^ self
]
