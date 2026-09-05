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
