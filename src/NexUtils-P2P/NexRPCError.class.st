"
Copyright 2026 Georg Hagn
SPDX-License-Identifier: Apache-2.0

I am a aubclass from Error and I process NexRPC errorss
"
Class {
	#name : 'NexRPCError',
	#superclass : 'Error',
	#instVars : [
		'code',
		'data'
	],
	#category : 'NexUtils-P2P-Core',
	#package : 'NexUtils-P2P',
	#tag : 'Core'
}

{ #category : 'accessing' }
NexRPCError >> code [

	^ code
]

{ #category : 'accessing' }
NexRPCError >> code: anObject [

	code := anObject
]

{ #category : 'accessing' }
NexRPCError >> data [

	^ data
]

{ #category : 'accessing' }
NexRPCError >> data: anObject [

	data := anObject
]

{ #category : 'accessing' }
NexRPCError >> messageText [

    ^ 'NexRPCError [', code asString, ']: ', super messageText.
]
