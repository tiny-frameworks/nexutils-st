"
I am a Mock Appender for Tests only
"
Class {
	#name : 'NexMockAppender',
	#superclass : 'Object',
	#instVars : [
		'lastFormattedMessage',
		'formatter'
	],
	#category : 'NexUtils-Logging-Tests-Helpers',
	#package : 'NexUtils-Logging-Tests',
	#tag : 'Helpers'
}

{ #category : 'accessing' }
NexMockAppender >> formatter [

	^ formatter ifNil: [ formatter := NexDefaultLogFormatter new ]
]

{ #category : 'accessing' }
NexMockAppender >> formatter: aFormatter [

	formatter := aFormatter
]

{ #category : 'accessing' }
NexMockAppender >> lastFormattedMessage [

	^ lastFormattedMessage
]

{ #category : 'accessing' }
NexMockAppender >> name [

	^ #mock
]

{ #category : 'actions api' }
NexMockAppender >> recordTag: tagString message: msg payload: aPayload [

	lastFormattedMessage := self formatter 
		formatMessage: msg 
		tag: tagString 
		payload: aPayload
]
