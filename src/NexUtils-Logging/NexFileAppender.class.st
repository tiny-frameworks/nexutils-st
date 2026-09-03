"
I am a File-based Appender that writes formatted log records to a specified file on disk.

I follow an ""Open-Write-Close"" write strategy to ensure data persistence after every log invocation and to allow graceful integration with external log rotation utilities.

Key Features & Responsibilities:
- File Reference handling via Pharo/Squeak FileSystem API.
- Thread-safe or persistent file appending for background tasks.
- Support for plain text and JSON formatters.

Example:
   | appender |
   appender := NexFileAppender newOn: ''app.log'' asFileReference.
   appender formatter: NexJsonLogFormatter new.
"
Class {
	#name : 'NexFileAppender',
	#superclass : 'NexLogAppender',
	#instVars : [
		'fileRef',
		'lockFile',
		'useLocking'
	],
	#category : 'NexUtils-Logging-Appenders',
	#package : 'NexUtils-Logging',
	#tag : 'Appenders'
}

{ #category : 'initialization' }
NexFileAppender class >> defaultFileRef [

	^ FileSystem disk workingDirectory / 'tsfLogger.log'.
]

{ #category : 'instance creation' }
NexFileAppender class >> newOn: aFileRef [

	^ self new 
		fileRef: aFileRef;
		yourself
]

{ #category : 'logging' }
NexFileAppender >> clearLog [

	fileRef ensureDelete
]

{ #category : 'accessing' }
NexFileAppender >> fileRef: aFileRef [

	fileRef := aFileRef asFileReference.
	lockFile := NexLockFile on: aFileRef.
]

{ #category : 'initialization' }
NexFileAppender >> initialize [ 

	super initialize.
	
	"Default: Logdatei im Working Directory"
	fileRef := FileSystem disk workingDirectory / 'tsfLogger.log'.
	
	"Wichtig: Wir setzen hier explizit einen Default Formatter, 
	 damit wir keine Lazy Init im Getter brauchen."
	formatter := NexDefaultLogFormatter new.
	useLocking := false.

]

{ #category : 'accessing' }
NexFileAppender >> lockFile [

	^ lockFile
]

{ #category : 'actions api' }
NexFileAppender >> record: aFormattedString [
	"Hier kommt jetzt der BEREITS FORMATIERTE String an."

	useLocking 
		ifTrue: [ lockFile critical: [ self writeToFile: aFormattedString ] ]
		ifFalse: [ self writeToFile: aFormattedString ]
]

{ #category : 'accessing' }
NexFileAppender >> useLocking [

	^ useLocking
]

{ #category : 'accessing' }
NexFileAppender >> useLocking: aBoolean [

	useLocking := aBoolean
]

{ #category : 'writing' }
NexFileAppender >> writeToFile: aFormattedString [
	"Strategie: Open-Write-Close (für Rotator-Kompatibilität)"
	
	fileRef ensureCreateFile.
	
	fileRef writeStreamDo: [ :stream | 
		stream setToEnd.
		stream nextPutAll: aFormattedString.
		stream cr. 
	]
]
