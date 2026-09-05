"
Copyright 2026 Georg Hagn
SPDX-License-Identifier: Apache-2.0


I am a session object and store user and socket informations
"
Class {
	#name : 'NexRPCSession',
	#superclass : 'Object',
	#instVars : [
		'socket',
		'user',
		'data',
		'creationTime',
		'authenticated',
		'pendingRequests',
		'requestCounter',
		'mutex',
		'requestTimeout'
	],
	#category : 'NexUtils-P2P-Core',
	#package : 'NexUtils-P2P',
	#tag : 'Core'
}

{ #category : 'defaults' }
NexRPCSession class >> defaultRequestTimeout [

    "How long to wait for a synchronous response before raising an error (e.g., 30 seconds)"
    ^ 5 
]

{ #category : 'accessing' }
NexRPCSession >> at: key [

	^ data at: (key asSymbol) ifAbsent: [ nil ].
]

{ #category : 'accessing' }
NexRPCSession >> at: key put: value [

	data at: (key asSymbol) put: value.
]

{ #category : 'actions' }
NexRPCSession >> collectBatchResults: batchIds [

    ^ batchIds collect: [ :id |
        | container semaphore |

        container := pendingRequests
            at: id
            ifAbsent: [ self error: 'ID lost' ].

        semaphore := container first.

        (semaphore waitTimeoutSeconds: requestTimeout) ifTrue: [
            self error: 'Batch Timeout'
        ].

        mutex critical: [
            pendingRequests removeKey: id ifAbsent: []
        ].

        container second
    ]
]

{ #category : 'private - dispatching' }
NexRPCSession >> handleIncomingResponse: json [
    | id |

    id := json at: 'id' ifAbsent: [ ^ false ].

    (self handleResponseId: id)
        ifFalse: [ ^ false ].

    self handleResponse: json id: id.
    ^ true.
]

{ #category : 'actions' }
NexRPCSession >> handleResponse: json id: id [

    mutex critical: [
        (pendingRequests at: id ifAbsent: [ nil ]) ifNotNil: [ :arr |
            arr at: 2 put: json.
            (arr first) signal.
        ]
    ].
]

{ #category : 'private - dispatching' }
NexRPCSession >> handleResponseId: id [

    ^ mutex critical: [
        pendingRequests includesKey: id
    ].
]

{ #category : 'initialization' }
NexRPCSession >> initialize [

    super initialize.

    creationTime := DateAndTime now.
    data := IdentityDictionary new.

    pendingRequests := Dictionary new.
    requestCounter := 0.
    mutex := Mutex new.
    requestTimeout := self class defaultRequestTimeout.


]

{ #category : 'testing' }
NexRPCSession >> isAuthenticated [

	^ authenticated
]

{ #category : 'testing' }
NexRPCSession >> isAuthenticated: aBool [

    authenticated := aBool
]

{ #category : 'testing' }
NexRPCSession >> isConnected [

    ^ socket notNil and: [ socket isConnected ]
]

{ #category : 'accessing' }
NexRPCSession >> mutex [ 

    ^ mutex

]

{ #category : 'accessing' }
NexRPCSession >> pendingRequests [

    ^ pendingRequests.
]

{ #category : 'actions' }
NexRPCSession >> registerRequest: method params: params [
    | id semaphore |

    mutex critical: [
        requestCounter := requestCounter + 1.
        id := requestCounter.
        semaphore := Semaphore new.

        pendingRequests
            at: id
            put: (Array with: semaphore with: nil).
    ].

    ^ NexRPCProtocol
        createRequest: method
        params: params
        id: id
]

{ #category : 'accessing' }
NexRPCSession >> requestCounter [

    ^ requestCounter.
]

{ #category : 'accessing' }
NexRPCSession >> requestTimeout: seconds [

    requestTimeout := seconds
]

{ #category : 'actions' }
NexRPCSession >> sendBatch: requestCollection [
    | batchArray batchIds |

    mutex critical: [
        batchArray := requestCollection collect: [ :assoc |
            self registerRequest: assoc key params: assoc value
        ].
    ].

    batchIds := batchArray collect: [ :json | json at: 'id' ].

    self sendMessage: (NeoJSONWriter toString: batchArray).

    ^ self collectBatchResults: batchIds
]

{ #category : 'protocol' }
NexRPCSession >> sendMessage: aString [

    socket sendMessage: aString
]

{ #category : 'actions' }
NexRPCSession >> sendSynchronous: method params: params [
    | id semaphore reqDict jsonResponse errorDict |

    reqDict := self registerRequest: method params: params.
    id := reqDict at: 'id'.
    semaphore := (pendingRequests at: id) first.

    self sendMessage: (NeoJSONWriter toString: reqDict).
    (semaphore waitTimeoutSeconds: requestTimeout) ifTrue: [
        mutex critical: [
            pendingRequests removeKey: id ifAbsent: []
        ].
        NexRPCTimeoutError
            signalForMethod: method
            params: params
    ].

    jsonResponse := (pendingRequests removeKey: id) second.
    (jsonResponse includesKey: 'error') ifTrue: [
        errorDict := jsonResponse at: 'error'.
        NexRPCError new
            code: (errorDict at: 'code');
            messageText: (errorDict at: 'message');
            signal
    ].

    ^ jsonResponse at: 'result'
]

{ #category : 'accessing' }
NexRPCSession >> socket [

	^ socket.
]

{ #category : 'accessing' }
NexRPCSession >> socket: aWebSocket [

	socket := aWebSocket.
]

{ #category : 'accessing' }
NexRPCSession >> user [

	^ user.
]

{ #category : 'accessing' }
NexRPCSession >> user: aString [

	user := aString
]
