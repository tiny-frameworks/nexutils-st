"
Copyright 2026 Georg Hagn
SPDX-License-Identifier: Apache-2.0


I am the core server for the TsfNexIO JSON-RPC framework.
I manage the WebSocket lifecycle, maintain active client sessions, and route incoming requests to a delegate.

*Responsibilities*
- **Lifecycle:** I start and stop the underlying Zinc HTTP/WebSocket server.
- **Session Management:** I keep track of connected clients in `sessions` and authenticated users in `userRegistry`.
- **Heartbeat:** I run a background process to ping clients and detect timeouts.
- **Dispatching:** I receive raw JSON, parse it, and delegate the logic to my `delegate`.

*Collaborators*
- `ZnWebSocket`: Handles the low-level connection.
- `TsfNexIOSession`: Represents a connected client.
- `TsfNexIOConstants`: Provides protocol constants.

*Public API*
- `startOn: aPort` - Starts the server on the given port.
- `stop` - Stops the server and disconnects all clients.
- `delegate:` - Sets the object responsible for handling actual RPC methods.

*Example*
```
""With defaults""
server := NexServer new.
server delegate: MyChatApp new.
server startOn: 9090.
```

"
Class {
	#name : 'NexRPCServer',
	#superclass : 'Object',
	#instVars : [
		'server',
		'delegate',
		'dispatcher',
		'sessions',
		'sessionsMutex',
		'logger',
		'heartbeatProcess',
		'heartbeatInterval',
		'waitTimeout',
		'port'
	],
	#category : 'NexUtils-P2P-Server',
	#package : 'NexUtils-P2P',
	#tag : 'Server'
}

{ #category : 'defaults' }
NexRPCServer class >> defaultHeartbeatInterval [

    "Server sends a ping every 30 seconds"
    ^ 30
]

{ #category : 'accessing - defaults' }
NexRPCServer class >> defaultPort [

    "Default port if none is specified"
    ^ 9090
]

{ #category : 'defaults' }
NexRPCServer class >> defaultWaitTimeout [

    "If no pong received within 60 seconds, connection is considered dead"
    ^ 60 seconds
]

{ #category : 'instance creation' }
NexRPCServer class >> newWith: anOptionsDict [

	^ (self new)
		port: (anOptionsDict at: #port ifAbsent: self class defaultPort);
		heartbeatInterval: (anOptionsDict at: #heartbeatInterval ifAbsent: self class defaultHeartbeatInterval);
		waitTimeout: (anOptionsDict at: #waitTimeout ifAbsent:  self class defaultWaitTimeout);
		yourself. 
]

{ #category : 'communication' }
NexRPCServer >> broadcastNotification: method params: params [
    "sends a notification to ALL connected clients"
    
    | payload jsonString currentSessions |
    
    "1. build payload via protocol"
    payload := NexRPCProtocol createNotification: method params: params.
    jsonString := NeoJSONWriter toString: payload.
    
    "2. Copy list (thread-safe) so we can immediately release the monitor again."
    currentSessions := sessionsMutex critical: [ sessions copy ].
    
    "3. Send (outside the monitor)"
    currentSessions do: [ :session | 
        (session socket isNotNil and: [ session socket isConnected ])
            ifTrue: [ 
                [ session socket sendMessage: jsonString ] 
                    on: Error do: [ :ex | 
                        "logging, but but continue broadcast"
                        Transcript show: 'Broadcast fail for one client'; cr.
                    ]
            ]
    ].
]

{ #category : 'accessing' }
NexRPCServer >> delegate [

    ^ delegate
]

{ #category : 'accessing' }
NexRPCServer >> delegate: anObject [

    delegate := anObject.
    dispatcher delegate: anObject.

    (delegate respondsTo: #server:) ifTrue: [
        delegate server: self
    ].
]

{ #category : 'actions' }
NexRPCServer >> handleConnection: webSocket [
    | session |

    "1. create session object"
    session := NexRPCSession new.
    session socket: webSocket.
    
    "2. register session (Thread-Safe)"
    sessionsMutex critical: [ 
        sessions add: session 
    ].

    "3. start loop - with Ensure block for cleanup"
    [
        "The loop runs as long as the connection is active."
        [ webSocket isConnected ] whileTrue: [
            [
                "Things will get loud when the test ends. (tearDown)"
                self readAndDispatch: webSocket session: session.
            ] on: ConnectionClosed, PrimitiveFailed do: [ :ex |
                "This is normal: client is gone."
                self logInfo: 'Server: Client disconnected (', ex description, ')'.
                
                "Very important: ^self trminates the method and jumps to ensure:"
                ^ self. 
            ]
        ]
    ] ensure: [ 
        "4. Cleanup: Regardless of why the loop ends (error, close, timeout),
         we remove the session from the list."
        sessionsMutex critical: [ 
            sessions remove: session ifAbsent: [].
           " self unregisterUser: session user."
        ].
        self logInfo: 'Server: Cleanup complete.'.
    ].

]

{ #category : 'accessing' }
NexRPCServer >> heartbeatInterval: anObject [

	heartbeatInterval := anObject
]

{ #category : 'initialization' }
NexRPCServer >> initialize [

	super initialize.

	sessions := Set new.
	sessionsMutex := Monitor new.
	dispatcher := NexRPCDispatcher new.

    "Lade Defaults"
    port := self class defaultPort .
    heartbeatInterval := self class defaultHeartbeatInterval.
    waitTimeout := self class defaultWaitTimeout.
]

{ #category : 'error handling' }
NexRPCServer >> logError: aString [

    logger ifNotNil: [ 
		logger error: '[NexRPCServer] ', aString 
	] ifNil: [ 
		Transcript show: '[NexRPCServer Error] '; show: aString; cr 
	]
]

{ #category : 'accessing' }
NexRPCServer >> logInfo: aString [
    "Do we have a logger? If so, use it. If not, use a transcript.."

	logger ifNotNil: [ 
		logger info: '[NexRPCServer] ', aString 
	] ifNil: [ 
		Transcript show: '[NexRPCServer Info] ' ; show: aString; cr 
	]
]

{ #category : 'accessing' }
NexRPCServer >> logger: aLogger [

	logger := aLogger
]

{ #category : 'accessing' }
NexRPCServer >> port: anObject [

	port := anObject
]

{ #category : 'actions' }
NexRPCServer >> processBatch: batchArray session: session [
    | responses |

    batchArray isEmpty ifTrue: [
        ^ NexRPCProtocol createError: NexRPCConstants invalidRequest data: 'Empty Batch' id: nil
    ].
    responses := OrderedCollection new.
    batchArray do: [ :req |
        | resp |
        resp := self processRequest: req session: session.
        resp ifNotNil: [ responses add: resp ].
    ].
    responses isEmpty ifTrue: [ ^ nil ].
    ^ responses asArray.
]

{ #category : 'private - actions' }
NexRPCServer >> processIncoming: json session: session [

    ^ json isArray
        ifTrue: [ self processBatch: json session: session ]
        ifFalse: [ self processRequest: json session: session ]
]

{ #category : 'actions' }
NexRPCServer >> processRequest: json session: session [

    ^ dispatcher processRequest: json session: session

]

{ #category : 'actions' }
NexRPCServer >> pruneDeadConnections [

	sessionsMutex critical: [
		sessions copy do: [ :session |  "Copy verwenden, um Modifikationen während der Iteration zu vermeiden"
			[
				(session isNotNil and: [ session isConnected ]) ifTrue: [ 
					session socket ping.
				] ifFalse: [
					"Aufräumen, wenn wir merken, dass er tot ist"
					"Triggert das ensure:"
					session socket close.
				]
			] on: Error do: [ :ex |
				 "Heartbeat failure -> session is probably gone"
				self logInfo: 'Heartbeat: Found dead connection. Closing...'.
				session socket close.
			]
		].
	]


]

{ #category : 'actions' }
NexRPCServer >> readAndDispatch: webSocket session: session [

 [ webSocket isConnected ] whileTrue: [
        | message responseObj json |

        message := webSocket readMessage.
        message ifNil: [ ^ self ].

        json := NeoJSONReader fromString: message.

        (json isDictionary and: [
            session handleIncomingResponse: json
        ]) ifFalse: [
            responseObj := self
                processIncoming: json
                session: session
        ].

        responseObj ifNotNil: [
            self sendResponse: responseObj on: webSocket
        ].
    ].
]

{ #category : 'private - actions' }
NexRPCServer >> sendResponse: responseObj on: webSocket [

    (webSocket isNotNil and: [ webSocket isConnected ]) ifTrue: [
        [
            webSocket sendMessage:
                (NeoJSONWriter toString: responseObj)
        ] on: Error do: [ :ex |
            "Ignore. Client is gone."
        ]
    ].
]

{ #category : 'accessing' }
NexRPCServer >> sessions [ 

	^ sessions 
]

{ #category : 'actions' }
NexRPCServer >> startHeartbeat [

	self stopHeartbeat. "Make sure it's not running twice."

	heartbeatProcess := [
		[
			(Delay forSeconds: heartbeatInterval) wait.
			self pruneDeadConnections.
		] repeat.
	] forkAt: Processor systemBackgroundPriority named: 'NexRPCHeartbeat'.
    
	self logInfo: 'Heartbeat started.'.
]

{ #category : 'public' }
NexRPCServer >> startOn: aPort [

    self stop. "Make sure it's not running twice."

    port := aPort.
    server := ZnServer startDefaultOn: port.
    server delegate map: 'ws' to: (ZnWebSocketDelegate handler: [ :ws |
        self handleConnection: ws
    ]).
    self startHeartbeat.

    self logInfo: 'Server started on port ', port asString.
]

{ #category : 'accessing' }
NexRPCServer >> stop [

	self stopHeartbeat .
	server ifNotNil: [ server stop ].
]

{ #category : 'actions' }
NexRPCServer >> stopHeartbeat [

	heartbeatProcess ifNotNil: [ 
		heartbeatProcess terminate. 
		heartbeatProcess := nil.
		self logInfo: 'Heartbeat stopped.'.
	].
]

{ #category : 'accessing' }
NexRPCServer >> waitTimeout: anObject [

	waitTimeout := anObject
]

{ #category : 'actions' }
NexRPCServer >> whisper: aDictionary toUser: username [
    "Sends a message ONLY to a specific user"
    
    | targetSession jsonString |
    
    sessionsMutex critical: [
        "search session of this specific user"
        targetSession := sessions 
            detect: [ :s | s user = username ] 
            ifNone: [ ^ self ]. "User not found -> stop"
    ].

    jsonString := NeoJSONWriter toString: aDictionary.
    
    (targetSession socket isNotNil and: [ targetSession socket isConnected ])
        ifTrue: [ targetSession socket sendMessage: jsonString ]
]

{ #category : 'communication' }
NexRPCServer >> whisperNotification: method params: params toUser: username [
    "Sends a notification ONLY to a specific user"
    | payload jsonString targetSession |
    
    payload := NexRPCProtocol createNotification: method params: params.
    jsonString := NeoJSONWriter toString: payload.
    
    "1. search target-session (Thread-Safe)"
    sessionsMutex critical: [
        targetSession := sessions 
            detect: [ :s | s user = username ] 
            ifNone: [ ^ self ]. "User nicht gefunden -> Abbruch"
    ].

    "2. Send (outside the monitor"
    (targetSession socket isNotNil and: [ targetSession socket isConnected ])
        ifTrue: [ 
            [ targetSession socket sendMessage: jsonString ] on: Error do: []
        ]
]
