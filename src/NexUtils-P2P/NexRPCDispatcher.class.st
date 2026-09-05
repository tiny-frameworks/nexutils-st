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

{ #category : 'actions' }
NexRPCDispatcher >> processRequest: json session: session [
    | method params id selector result |

    (json isDictionary and: [ json includesKey: 'method' ]) ifFalse: [
        ^ NexRPCProtocol
            createError: NexRPCConstants invalidRequest
            data: json
            id: nil
    ].

    method := json at: 'method'.
    params := json at: 'params' ifAbsent: [ Dictionary new ].
    id := json at: 'id' ifAbsent: [ nil ].

    "selector := ('rpc', method capitalized, ':session:') asSymbol."
    selector := self rpcSelectorFor: method.
    (delegate respondsTo: selector) ifFalse: [
        id ifNil: [ ^ nil ].
        ^ NexRPCProtocol
            createError: NexRPCConstants methodNotFound
            data: method
            id: id
    ].

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
    ].
]

{ #category : 'helper' }
NexRPCDispatcher >> rpcSelectorFor: method [
    | parts selector |

    parts := method findTokens: '.'.
    selector := parts inject: 'rpc' into: [ :result :part |
        result , part capitalized ].
    ^ (selector , ':session:') asSymbol
]
