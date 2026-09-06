"
Copyright 2026 Georg Hagn
SPDX-License-Identifier: Apache-2.0

I am a concrete aubclass of the NexRPCBasicDelegate. I implement some methods for testing purpose.

```
rpcTestSlow: params session: aSession 
""Corresponding to JSON method: 'test.slow' I am used for timeout Tests""

rpcMethodNotImplemented: methodName params: params session: aSession 
""Minimal-Implementation for Test. I am a 'shouldBeImplemented' method ""

rpcFail: params session: session
""Test exception. I am used for Exception Tests""
```

See: NexRPCBaseDelegate
"
Class {
	#name : 'NexRPCAuthTestDelegate',
	#superclass : 'NexRPCBaseDelegate',
	#category : 'NexUtils-P2P-Tests',
	#package : 'NexUtils-P2P-Tests'
}

{ #category : 'rpc - method' }
NexRPCAuthTestDelegate >> rpcFail: params session: session [

    self error: 'Test exception'.
]

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
