"
Copyright 2026 Georg Hagn
SPDX-License-Identifier: Apache-2.0

I define the Json RPC Messages . I have only class methods
"
Class {
	#name : 'NexRPCProtocol',
	#superclass : 'Object',
	#category : 'NexUtils-P2P-Core',
	#package : 'NexUtils-P2P',
	#tag : 'Core'
}

{ #category : 'error handling' }
NexRPCProtocol class >> createError: errorDef data: data id: id [

	^ self createError: errorDef message: nil data: data id: id.
]

{ #category : 'class initialization' }
NexRPCProtocol class >> createError: errorDefOrCode message: msgStringOrNil data: data id: id [
    | code message errorDict |

    (errorDefOrCode isKindOf: NexRPCErrorDef)
        ifTrue: [ 
            code := errorDefOrCode code.
            message := msgStringOrNil ifNil: [ errorDefOrCode message ].
        ]
        ifFalse: [ 
            code := errorDefOrCode.
            message := msgStringOrNil.
        ].

    errorDict := { 'code' -> code. 'message' -> message } asDictionary.
    data ifNotNil: [ errorDict at: 'data' put: data ].
    
    ^ {
        'jsonrpc' -> self rpcVersion.
        'error' -> errorDict.
        'id' -> id
    } asDictionary.

]

{ #category : 'class initialization' }
NexRPCProtocol class >> createNotification: method params: params [

    ^ {
        'jsonrpc' -> self rpcVersion.
        'method' -> method.
        'params' -> params.
    } asDictionary.
]

{ #category : 'class initialization' }
NexRPCProtocol class >> createRequest: method params: params id: id [

    ^ {
        'jsonrpc' -> self rpcVersion.
        'method' -> method.
        'params' -> params.
        'id' -> id
    } asDictionary.
]

{ #category : 'class initialization' }
NexRPCProtocol class >> createResponse: result id: id [

    ^ {
        'jsonrpc' -> self rpcVersion.
        'result' -> result.
        'id' -> id
    } asDictionary.
]

{ #category : 'defaults' }
NexRPCProtocol class >> rpcVersion [ 

	^ '2.0'
]
