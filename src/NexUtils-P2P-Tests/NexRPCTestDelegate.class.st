Class {
	#name : 'NexRPCTestDelegate',
	#superclass : 'Object',
	#instVars : [
		'lastReceivedSession'
	],
	#category : 'NexUtils-P2P-Tests',
	#package : 'NexUtils-P2P-Tests'
}

{ #category : 'accessing' }
NexRPCTestDelegate >> lastReceivedSession [

    ^ lastReceivedSession
]

{ #category : 'rpc - test' }
NexRPCTestDelegate >> rpcEcho: params session: aSession [
    "korresponding to JSON method: 'echo'"
    
    lastReceivedSession := aSession.
    ^ params
]

{ #category : 'rpc - test' }
NexRPCTestDelegate >> rpcErrorTrigger: params session: aSession [
    "korrespondiert to JSON method: 'errorTrigger'"
    
    "Simulates a Business-Logic error"
    Error signal: 'Simulated Crash'
]

{ #category : 'rpc - test' }
NexRPCTestDelegate >> rpcSlow: params session: aSession [
    "korresponding to JSON method: 'slow'"
    
    (Delay forSeconds: 3) wait.
    ^ 'done'
]
