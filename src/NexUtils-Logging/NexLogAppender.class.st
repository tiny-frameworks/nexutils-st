"
I am the superclass of all appenders
"
Class {
	#name : 'NexLogAppender',
	#superclass : 'Object',
	#instVars : [
		'name',
		'formatter'
	],
	#category : 'NexUtils-Logging-Appenders',
	#package : 'NexUtils-Logging',
	#tag : 'Appenders'
}

{ #category : 'logging' }
NexLogAppender >> clearLog [

	self subclassResponsibility 
]

{ #category : 'accessing' }
NexLogAppender >> formatter [

	^ formatter ifNil: [ formatter := NexDefaultLogFormatter new ]
]

{ #category : 'accessing' }
NexLogAppender >> formatter: aFormatter [

	formatter := aFormatter
]

{ #category : 'initialization' }
NexLogAppender >> initialize [ 

	super initialize.
	
	name := self className 
]

{ #category : 'accessing' }
NexLogAppender >> name [

	^ name
]

{ #category : 'accessing' }
NexLogAppender >> name: anObject [

	name := anObject
]

{ #category : 'actions api' }
NexLogAppender >> record: aMsg [

	self subclassResponsibility 
]

{ #category : 'actions api' }
NexLogAppender >> recordTag: aTag message: aString [
	"Die neue Hauptmethode für Appender. Hier wird formatiert und dann geschrieben."
	| formattedString |
	
	formattedString := self formatter formatMessage: aString tag: aTag.
	self record: formattedString.
]

{ #category : 'actions api' }
NexLogAppender >> recordTag: aTag message: aString payload: aDictionaryOrArray [
	"Die neue Hauptmethode für Appender. Hier wird formatiert und dann geschrieben."
	| formattedString |
	
	formattedString := self formatter formatMessage: aString tag: aTag.
	self record: formattedString.
]
