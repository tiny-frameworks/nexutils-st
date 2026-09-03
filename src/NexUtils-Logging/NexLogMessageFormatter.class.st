"
I format the message and payload to an applicable messageformat
"
Class {
	#name : 'NexLogMessageFormatter',
	#superclass : 'Object',
	#category : 'NexUtils-Logging-Formatters',
	#package : 'NexUtils-Logging',
	#tag : 'Formatters'
}

{ #category : 'formatting' }
NexLogMessageFormatter >> formatMessage: msg tag: tagString [

	self subclassResponsibility
]

{ #category : 'formatting' }
NexLogMessageFormatter >> formatMessage: msg tag: tagString payload: aPayload [ 

	^ self subclassResponsibility
]

{ #category : 'formatting' }
NexLogMessageFormatter >> payloadAsDictionary: aPayload [
	"Private - Normalizes various payload input types into a standard Dictionary.
	Handles nil, existing Dictionaries, and Arrays of Associations."
	
	aPayload ifNil: [ ^ Dictionary new ].
	(aPayload isKindOf: Dictionary) ifTrue: [ ^ aPayload ].
	(aPayload isCollection) ifTrue: [ ^ Dictionary newFrom: aPayload ].

	^ Dictionary new at: #data put: aPayload; yourself
]
