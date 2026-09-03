"
I am only for testing purposes. Do not use in Production
"
Class {
	#name : 'NexMemoryAppender',
	#superclass : 'NexLogAppender',
	#instVars : [
		'logs'
	],
	#category : 'NexUtils-Logging-Appenders',
	#package : 'NexUtils-Logging',
	#tag : 'Appenders'
}

{ #category : 'logging' }
NexMemoryAppender >> clearLog [


]

{ #category : 'initialization' }
NexMemoryAppender >> initialize [

	super initialize.
	logs := OrderedCollection new.
]

{ #category : 'accessing' }
NexMemoryAppender >> logs [

	^ logs
]

{ #category : 'actions api' }
NexMemoryAppender >> record: aFormattedString [

	logs add: aFormattedString
]
