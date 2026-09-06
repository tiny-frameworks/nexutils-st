"
Copyright 2026 Georg Hagn
SPDX-License-Identifier: Apache-2.0

I dispatch incoming JSON-RPC requests to an application delegate.

The dispatcher translates JSON-RPC method names into the corresponding
Smalltalk message selectors and invokes them on the delegate, passing
the request parameters and the current session.

For example:
```
system.ping  ->  #rpcSystemPing:session:   
auth.login   ->  #rpcAuthLogin:session:
```
If no corresponding delegate method is available, the dispatcher
delegates handling to #rpcMethodNotImplemented:params:session: .

** *The dispatcher is responsible for RPC method resolution and invocation,
but does not contain application-specific behavior* **.

See: NexRPCBaseDelegate, NexRPCSession, NexRPCNode

"
Class {
	#name : 'NexRPCDispatcher',
	#superclass : 'Object',
	#instVars : [
		'delegate'
	],
	#category : 'NexUtils-P2P-Core',
	#package : 'NexUtils-P2P',
	#tag : 'Core'
}

{ #category : 'accessing' }
NexRPCDispatcher >> delegate: anObject [

  delegate := anObject
]

{ #category : 'helper' }
NexRPCDispatcher >> invalidRequestResponseFor: json [

    ^ NexRPCProtocol
        createError: NexRPCConstants invalidRequest
        data: json
        id: nil
]

{ #category : 'testing' }
NexRPCDispatcher >> isValidRequest: json [

    ^ json isDictionary and: [
        json includesKey: 'method'
    ]
]

{ #category : 'helper' }
NexRPCDispatcher >> methodNotFoundResponseFor: method id: id [

    id ifNil: [ ^ nil ].

    ^ NexRPCProtocol
        createError: NexRPCConstants methodNotFound
        data: method
        id: id
]

{ #category : 'helper' }
NexRPCDispatcher >> perform: selector params: params id: id session: session [
    | result |

    [
        result := delegate
            perform: selector
            with: params
            with: session.

        id ifNil: [ ^ nil ].

        ^ NexRPCProtocol
            createResponse: result
            id: id

    ] on: Error do: [ :ex |
        id ifNil: [ ^ nil ].

        ^ NexRPCProtocol
            createError: NexRPCConstants internalError
            message: ex messageText
            data: nil
            id: id
    ]
]

{ #category : 'actions' }
NexRPCDispatcher >> processRequest: json session: session [
    | method params id selector |

    (self isValidRequest: json) ifFalse: [
        ^ self invalidRequestResponseFor: json
    ].

    method := json at: 'method'.
    params := json at: 'params' ifAbsent: [ Dictionary new ].
    id := json at: 'id' ifAbsent: [ nil ].
    selector := self rpcSelectorFor: method.

    (delegate respondsTo: selector) ifFalse: [
        ^ self methodNotFoundResponseFor: method id: id
    ].

    ^ self
        perform: selector
        params: params
        id: id
        session: session

]

{ #category : 'helper' }
NexRPCDispatcher >> rpcSelectorFor: method [
    | parts selector |

    parts := method findTokens: '.'.
    selector := parts inject: 'rpc' into: [ :result :part |
        result , part capitalized ].
    ^ (selector , ':session:') asSymbol

]
