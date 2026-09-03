"
Copyright 2026 Georg Hagn
SPDX-License-Identifier: Apache-2.0

I handle RPC 2.0 Error Codes. I have only class methods
"
Class {
	#name : 'NexRPCConstants',
	#superclass : 'Object',
	#classInstVars : [
		'ParseError',
		'InvalidRequest',
		'MethodNotFound',
		'InvalidParams',
		'InternalError'
	],
	#category : 'NexUtils-P2P-Core',
	#package : 'NexUtils-P2P',
	#tag : 'Core'
}

{ #category : 'class initialization' }
NexRPCConstants class >> internalError [

    ^ InternalError ifNil: [ 
        InternalError := NexRPCErrorDef code: -32603 message: 'Internal error' 
    ].
]

{ #category : 'class initialization' }
NexRPCConstants class >> invalidParams [

    ^ InvalidParams ifNil: [ 
        InvalidParams := NexRPCErrorDef code: -32602 message: 'Invalid params' 
    ].
]

{ #category : 'class initialization' }
NexRPCConstants class >> invalidRequest [

    ^ InvalidRequest ifNil: [ 
        InvalidRequest := NexRPCErrorDef code: -32600 message: 'Invalid Request' 
    ].
]

{ #category : 'class initialization' }
NexRPCConstants class >> methodNotFound [

    ^ MethodNotFound ifNil: [ 
        MethodNotFound := NexRPCErrorDef code: -32601 message: 'Method not found' 
    ].
]

{ #category : 'parsing' }
NexRPCConstants class >> parseError [

    "Lazy Initialization: Wenn nil, erzeuge neu."
    ^ ParseError ifNil: [ 
        ParseError := NexRPCErrorDef code: -32700 message: 'Parse error' 
    ].
]

{ #category : 'initialization' }
NexRPCConstants class >> reset [

    ParseError := nil.
    InvalidRequest := nil.
    MethodNotFound := nil.
    InvalidParams := nil.
    InternalError := nil.
]
