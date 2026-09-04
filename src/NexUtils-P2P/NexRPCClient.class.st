"
Copyright 2026 Georg Hagn
SPDX-License-Identifier: Apache-2.0


I am the client-side implementation of the TsfNexIO JSON-RPC 2.0 framework.
I handle the connection to the server, serialization of requests, and mapping asynchronous responses back to synchronous calls.

*Responsibilities*
- **Connection Management:** Connect to a WebSocket URL.
- **Protocol:** Implement JSON-RPC 2.0 (Request, Notification, Batch).
- **Concurrency:** Map incoming responses (by ID) to the waiting process using Semaphores.
- **Thread Safety:** Protect pending request storage with a Monitor.

*Collaborators*
- `ZnWebSocket`: Underlying transport.
- `NeoJSON`: Serialization.

*Public API*
- `connectTo: urlString` - Establish connection.
- `sendSynchronous: method params: args` - Sends request and waits for result.
- `sendNotification: method params: args` - Fire and forget.
- `close` - Clean up.

*Internal State*
- `pendingRequests`: A Dictionary mapping Request-IDs to Semaphores.
- `requestMutex`: A Monitor ensuring thread-safe access to `pendingRequests`.

Example:
```
| result params |
params := {'text' -> 'Hello'} asDictionary.
result := client sendSynchronous: 'echo' params: params.
```
"
Class {
	#name : 'NexRPCClient',
	#superclass : 'Object',
	#instVars : [
		'webSocket',
		'notificationHandler',
		'logger',
		'session',
		'requestTimeout',
		'streamTimeOut',
		'requestHandler'
	],
	#category : 'NexUtils-P2P-Client',
	#package : 'NexUtils-P2P',
	#tag : 'Client'
}

{ #category : 'defaults' }
NexRPCClient class >> defaultRequestTimeout [

    "How long to wait for a synchronous response before raising an error (e.g., 30 seconds)"
    ^ 5 
]

{ #category : 'defaults' }
NexRPCClient class >> defaultStreamTimeOut [

	^ 60
]

{ #category : 'accessing' }
NexRPCClient class >> defaultUserAgent [

    ^ 'TsfNexIO-Client/1.0'
]

{ #category : 'instance creation' }
NexRPCClient class >> newWith: anOptionsDict [

    ^ (self new)
	     streamTimeOut: self class defaultStreamTimeOut;
        requestTimeout: self class defaultRequestTimeout;
		yourself. 
]

{ #category : 'initialize-release' }
NexRPCClient >> close [

    webSocket ifNotNil: [ webSocket close ].
]

{ #category : 'public - line' }
NexRPCClient >> connectTo: urlString [

    webSocket := ZnWebSocket to: urlString.
    webSocket stream timeout: streamTimeOut.

    session := NexRPCSession new.
    session requestTimeout: requestTimeout.
    session socket: webSocket.

    [ self listenLoop ]
        forkAt: Processor userBackgroundPriority
        named: 'NexRPCListener'.
]

{ #category : 'private - actions' }
NexRPCClient >> dispatchIncoming: json [
    | id method response |

    method := json at: 'method' ifAbsent: [ nil ].
    id := json at: 'id' ifAbsent: [ nil ].

    method ifNotNil: [
        id ifNil: [
            self handleNotification: json.
            ^ self
        ].

        requestHandler ifNotNil: [
            response := requestHandler value: json.
            response ifNotNil: [
                session sendMessage:
                    (NeoJSONWriter toString: response)
            ].
        ].

        ^ self
    ].

    id ifNotNil: [
        "self handleResponse: json id: id"
        session handleResponse: json id: id
    ].
]

{ #category : 'error handling' }
NexRPCClient >> handleNotification: json [

    notificationHandler ifNotNil: [ notificationHandler value: json ].
]

{ #category : 'actions' }
NexRPCClient >> handleResponse: json id: id [

	Transcript showCr: 'NexClient>>handleResponse: json id: id'.
	session handleResponse: json id: id
]

{ #category : 'initialization' }
NexRPCClient >> initialize [

    super initialize.

    streamTimeOut := self class defaultStreamTimeOut.
    requestTimeout := self class defaultRequestTimeout.
]

{ #category : 'request handling' }
NexRPCClient >> listenLoop [

    "We'll keep running as long as the socket thinks it's connected."
    [ webSocket isConnected ] whileTrue: [
        [
            | message json |
            
            "1. Read"
            message := webSocket readMessage.
            
            "2. MOST IMPORTANT LINE: If message is nil, the server is down."
            "No error, but a quiet end."
            message ifNil: [ 
                self close. 
                ^ self "end process!" 
            ].

            "3. Parsen (Crashes if message is nil, therefore step 2 is important)"
            json := NeoJSONReader fromString: message.
            
            "4. Dispatchen"
            json isArray 
                ifTrue: [ json do: [ :item | self dispatchIncoming: item ] ]
                ifFalse: [ self dispatchIncoming: json ].

        ] on: Error do: [ :ex |
        "IMPORTANT: We catch 'Exception' (everything), not just 'Error'.
         We do NOT log anything to the transcript to avoid race conditions 
         when viewing it. We simply terminate the process."
        ^ self
        ]
    ].

]

{ #category : 'error handling' }
NexRPCClient >> logError: aString [

	logger ifNotNil: [ 
		logger error: '[NexRPCClient] ', aString 
	] ifNil: [ 
		Transcript show: '[NexRPCERROR] '; show: aString; cr.
	]
]

{ #category : 'accessing' }
NexRPCClient >> logInfo: aString [
    "Have we a logger? If yes, use him. If no, Transcript."

	logger ifNotNil: [ 
		logger info: '[NexRPCClient] ', aString 
	] ifNil: [
		Transcript show: '[NexRPCClient] ' ; show: aString; cr.
	]
]

{ #category : 'accessing' }
NexRPCClient >> notificationHandler: aBlock [

    notificationHandler := aBlock.
]

{ #category : 'accessing' }
NexRPCClient >> requestHandler [

    ^ requestHandler
]

{ #category : 'accessing' }
NexRPCClient >> requestHandler: aBlock [

    requestHandler := aBlock
]

{ #category : 'accessing' }
NexRPCClient >> requestTimeout: seconds [

    requestTimeout := seconds.
    session ifNotNil: [
        session requestTimeout: seconds
    ].
]

{ #category : 'actions' }
NexRPCClient >> sendBatch: requestCollection [

    ^ session sendBatch: requestCollection

]

{ #category : 'actions' }
NexRPCClient >> sendSynchronous: method params: params [

    ^ session
        sendSynchronous: method
        params: params
]

{ #category : 'accessing' }
NexRPCClient >> session [ 

    ^ session
]

{ #category : 'accessing' }
NexRPCClient >> session: aSession [

	session := aSession
]

{ #category : 'accessing' }
NexRPCClient >> streamTimeOut: aTimeOut [

	streamTimeOut := aTimeOut 
]
