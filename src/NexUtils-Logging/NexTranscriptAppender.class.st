"
I am an Appender that writes formatted log messages directly to the Smalltalk System Transcript.

I am ideal for interactive development, debugging, and immediate visual feedback within the image environment.

Public API and Key Messages:
- recordTag:message:payload: - Formats and writes a single log record to the Transcript followed by a carriage return.
- formatter: - Sets a custom log formatter (defaults to NexDefaultLogFormatter if unassigned).

Example:
   | appender |
   appender := NexTranscriptAppender new.
   appender recordTag: ''INFO'' message: ''Ready'' payload: nil.
"
Class {
	#name : 'NexTranscriptAppender',
	#superclass : 'NexLogAppender',
	#category : 'NexUtils-Logging-Appenders',
	#package : 'NexUtils-Logging',
	#tag : 'Appenders'
}

{ #category : 'logging' }
NexTranscriptAppender >> clearLog [

	
]

{ #category : 'actions api' }
NexTranscriptAppender >> record: aRecord [

	Transcript show: aRecord; cr; flush.
]
