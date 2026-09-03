"
I am a Decorator Appender that provides non-blocking, asynchronous log processing.

I wrap an existing target appender (such as a NexFileAppender) and delegate writing operations to a dedicated background Process via a thread-safe SharedQueue. This prevents I/O latency from stalling high-throughput application threads or P2P message handlers.

Key Responsibilities & Operational Notes:
- Non-blocking logging for performance-critical execution paths.
- Background worker process management.
- Flush & Cleanup: Calling #flush or #stop ensures all queued log entries are written before process termination.

Example:
   | syncAppender asyncAppender |
   syncAppender := NexFileAppender newOn: ''server.log'' asFileReference.
   asyncAppender := NexAsyncLogAppender decorate: syncAppender.
   
   ""Always flush/stop async appenders upon application shutdown""
   asyncAppender flush.
"
Class {
	#name : 'NexAsyncLogAppender',
	#superclass : 'NexLogAppender',
	#instVars : [
		'targetAppender',
		'queue',
		'workerProcess'
	],
	#category : 'NexUtils-Logging-Appenders',
	#package : 'NexUtils-Logging',
	#tag : 'Appenders'
}

{ #category : 'instance creation' }
NexAsyncLogAppender class >> decorate: anAppender [
	"Erzeugt einen Async Wrapper um einen existierenden Appender"
	
	^ self new
		targetAppender: anAppender;
		formatter: anAppender formatter; "Wir übernehmen den Formatter des Originals"
		yourself
]

{ #category : 'logging' }
NexAsyncLogAppender >> clearLog [

	targetAppender clearLog
]

{ #category : 'accessing' }
NexAsyncLogAppender >> flush [
	| doneSemaphore |

	doneSemaphore := Semaphore new.
	
	"Wir schieben den 'Signal'-Block in die Queue.
	 Er reiht sich HINTER alle noch wartenden Log-Einträge ein."
	queue nextPut: [ doneSemaphore signal ].
	
	"Der Main-Thread wartet hier, bis der Worker beim Block angekommen ist."
	doneSemaphore wait.
	
	"Wenn wir hier sind, ist die Queue garantiert leer."
	^ self
]

{ #category : 'initialization' }
NexAsyncLogAppender >> initialize [

	super initialize.
	
	queue := SharedQueue new. 
	self startWorker
]

{ #category : 'actions api' }
NexAsyncLogAppender >> record: aFormattedString [
	"Das ist der 'Hot Path'. Er muss extrem schnell sein.
	 Wir schieben den String nur in die Queue und kehren sofort zurück."
	
	queue nextPut: aFormattedString.
	
]

{ #category : 'private - actions' }
NexAsyncLogAppender >> startWorker [
	"Startet den Hintergrundprozess, der die Queue abarbeitet."
	
	self stopWorker.
	
	workerProcess := [
		[ true ] whileTrue: [
			| entry |
			entry := queue next. "Wartet hier..."
			
			"TRICK: Wir prüfen, ob es ein Block ist (für flush) oder ein String (Log)"
			entry isBlock 
				ifTrue: [ 
					"Es ist ein Befehl (z.B. vom flush), einfach ausführen"
					entry value 
				]
				ifFalse: [ 
					"Es ist ein Log-Eintrag, ab zum Target damit"
					[ targetAppender record: entry ] 
						on: Error 
						do: [ :ex | Transcript show: 'AsyncLog Error: '; show: ex description; cr ]
				].
		]
	] forkAt: Processor userBackgroundPriority named: 'NexLogger Worker'.

]

{ #category : 'private - actions' }
NexAsyncLogAppender >> stopWorker [

	workerProcess ifNotNil: [ 
		"Erst alles wegschreiben..."
		self flush.

		"Dann Prozess beenden"
		workerProcess terminate.
		workerProcess := nil.
	].
]

{ #category : 'accessing' }
NexAsyncLogAppender >> targetAppender: anAppender [

	targetAppender := anAppender.
	
	"Wir übernehmen den Namen des Targets für Debugging-Zwecke"
	name := 'Async -> ', anAppender name.
]
