Class {
	#name : 'NexRPCAuthTestDelegate',
	#superclass : 'NexRPCBaseDelegate',
	#category : 'NexUtils-P2P-Tests',
	#package : 'NexUtils-P2P-Tests'
}

{ #category : 'subclassing' }
NexRPCAuthTestDelegate >> rpcMethodNotImplemented: methodName params: params session: aSession [
    "Minimal-Implementierung for Test"

    NexRPCError new
        code: NexRPCConstants methodNotFound;
        messageText: 'Not found';
        signal.
]

{ #category : 'rpc - method' }
NexRPCAuthTestDelegate >> rpcTestSlow: params session: aSession [
    "korresponding to JSON method: 'test.slow'"
    
    (Delay forSeconds: 3) wait.
    ^ 'done'

]
