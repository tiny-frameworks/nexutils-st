Class {
	#name : 'NexRPCNode',
	#superclass : 'Object',
	#instVars : [
		'server',
		'clients',
		'delegate',
		'dispatcher'
	],
	#category : 'NexUtils-P2P-Core',
	#package : 'NexUtils-P2P',
	#tag : 'Core'
}

{ #category : 'accessing' }
NexRPCNode >> clients [

	^ clients
]

{ #category : 'accessing' }
NexRPCNode >> clients: anObject [

	clients := anObject
]

{ #category : 'public - line' }
NexRPCNode >> connectTo: urlString [
    | client |

    client := NexRPCClient new.
    client connectTo: urlString.

    client requestHandler: [ :request |
        self processIncomingRequest: request session: client session
    ].

    clients at: urlString put: client.

    ^ client
]

{ #category : 'accessing' }
NexRPCNode >> delegate [

	^ delegate
]

{ #category : 'accessing' }
NexRPCNode >> delegate: anObject [

    delegate := anObject.
    dispatcher delegate: anObject.

    server ifNotNil: [
        server delegate: anObject
    ].
]

{ #category : 'initialization' }
NexRPCNode >> initialize [

    super initialize.
	
    dispatcher := NexRPCDispatcher new.
    clients := Dictionary new.
]

{ #category : 'actions' }
NexRPCNode >> processIncomingRequest: json session: session [

    ^ dispatcher processRequest: json session: session
]

{ #category : 'accessing' }
NexRPCNode >> server [

	^ server
]

{ #category : 'accessing' }
NexRPCNode >> server: anObject [

	server := anObject
]

{ #category : 'accessing' }
NexRPCNode >> start [

    server := NexRPCServer new.
    server delegate: delegate.
    server start.
]

{ #category : 'public' }
NexRPCNode >> startOn: aPort [

    server := NexRPCServer new.
    server delegate: delegate.
    server startOn: aPort
]

{ #category : 'accessing' }
NexRPCNode >> stop [

    clients valuesDo: [ :client |
        client close
    ].

    clients removeAll.

    server ifNotNil: [
        server stop.
        server := nil
    ].
]
