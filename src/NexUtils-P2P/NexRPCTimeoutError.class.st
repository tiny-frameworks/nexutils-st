"
Copyright 2026 Georg Hagn
SPDX-License-Identifier: Apache-2.0

I am a subclass of Error. I handle timeout errors
"
Class {
	#name : 'NexRPCTimeoutError',
	#superclass : 'Error',
	#instVars : [
		'method',
		'params'
	],
	#category : 'NexUtils-P2P-Core',
	#package : 'NexUtils-P2P',
	#tag : 'Core'
}

{ #category : 'signalling' }
NexRPCTimeoutError class >> signalForMethod: aMethod params: aDict [

    ^ self new
        method: aMethod params: aDict;
        signal
]

{ #category : 'accessing' }
NexRPCTimeoutError >> messageText [
    "Pharo uses this for debugger-title"

	^ method 
        ifNotNil: [ 'Timeout waiting for request: ', method asString ]
        ifNil: [ super messageText ifNil: ['Unknown Timeout'] ]
]

{ #category : 'error handling' }
NexRPCTimeoutError >> method: aString params: aDictionary [

    method := aString.
    params := aDictionary.
]

{ #category : 'accessing' }
NexRPCTimeoutError >> params [

	^ params
]
