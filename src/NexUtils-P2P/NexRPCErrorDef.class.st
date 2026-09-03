"
Copyright 2026 Georg Hagn
SPDX-License-Identifier: Apache-2.0

I am an ErrorCode Definition Object. I handle RPC 2.0 Errors
"
Class {
	#name : 'NexRPCErrorDef',
	#superclass : 'Object',
	#instVars : [
		'code',
		'message'
	],
	#category : 'NexUtils-P2P-Core',
	#package : 'NexUtils-P2P',
	#tag : 'Core'
}

{ #category : 'class initialization' }
NexRPCErrorDef class >> code: anInteger message: aString [

    ^ self new code: anInteger; message: aString; yourself.
]

{ #category : 'accessing' }
NexRPCErrorDef >> code [

	^ code
]

{ #category : 'accessing' }
NexRPCErrorDef >> code: anObject [

	code := anObject
]

{ #category : 'accessing' }
NexRPCErrorDef >> message [

	^ message
]

{ #category : 'accessing' }
NexRPCErrorDef >> message: anObject [

	message := anObject
]
