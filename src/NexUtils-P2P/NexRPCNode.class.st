"
Copyright 2026 Georg Hagn
SPDX-License-Identifier: Apache-2.0

I represent a P2P node in the NexUtils-P2P framework.

I combine the RPC communication endpoint with the application delegate  that
handles incoming RPC requests. * **My intention is to communicate with each 
other as peers; there is no inherent client/server hierarchy between connected nodes** *.

I manage the underlying RPC sessions and provide the common infrastructure 
required for establishing connections and dispatching JSON-RPC requests to its delegate.

Application-specific behavior is implemented by a delegate rather than by subclassing
me itself. This keeps the networking and RPC infrastructure separate from application logic.

See: NexRPCBaseDelegate, NexRPCSession, NexRPCDispatcher

"
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
NexRPCNode >> server: aServer [

	server := aServer 
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
