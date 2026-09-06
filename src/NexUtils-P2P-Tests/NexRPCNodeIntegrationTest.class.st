Class {
	#name : 'NexRPCNodeIntegrationTest',
	#superclass : 'TestCase',
	#category : 'NexUtils-P2P-Tests',
	#package : 'NexUtils-P2P-Tests'
}

{ #category : 'tests' }
NexRPCNodeIntegrationTest >> testBidirectionalRequestResponse [
    | nodeA nodeB client session result |

    nodeA := NexRPCNode new.
    nodeB := NexRPCNode new.

    nodeA delegate: NexRPCBaseDelegate new.
    nodeB delegate: NexRPCBaseDelegate new.

    nodeA startOn: 40101.
    nodeB startOn: 40102.

    [
        "A -> B"
        client := nodeA connectTo:
            'ws://localhost:40102/ws'.

        (Delay forMilliseconds: 100) wait.

        result := client
            sendSynchronous: 'system.echo'
            params: {'text' -> 'Hello P2P'} asDictionary.

        self assert: (result at: 'text')
            equals: 'Hello P2P'.

        "B -> A over the same WebSocket connection"
        session := nodeB server sessions anyOne.

        result := session
            sendSynchronous: 'system.echo'
            params: {'text' -> 'Hello back from B'} asDictionary.

        self assert: (result at: 'text')
            equals: 'Hello back from B'.

        "Test disconnect and server-side session cleanup"
        client close.
        (Delay forMilliseconds: 100) wait.
        self assert: nodeB server sessions isEmpty.


     ] ensure: [
        nodeA stop.
        nodeB stop.
    ].
]

{ #category : 'tests' }
NexRPCNodeIntegrationTest >> testDelegateError [
    | nodeA nodeB client |

    nodeA := NexRPCNode new.
    nodeB := NexRPCNode new.

    nodeA delegate: NexRPCAuthTestDelegate new.
    nodeB delegate: NexRPCAuthTestDelegate new.

    nodeA startOn: 40101.
    nodeB startOn: 40102.

    [
        client := nodeA connectTo: 'ws://localhost:40102/ws'.
        self should: [
            client sendSynchronous: 'fail' params: Dictionary new
        ] raise: NexRPCError.
    ] ensure: [
        nodeA stop.
        nodeB stop.
    ].
]

{ #category : 'tests' }
NexRPCNodeIntegrationTest >> testSingleNodeToNode [

    | nodeA nodeB client result |

    nodeA := NexRPCNode new.
    nodeB := NexRPCNode new.

    nodeA delegate: NexRPCBaseDelegate new.
    nodeB delegate: NexRPCBaseDelegate new.

    nodeA startOn: 40101.
    nodeB startOn: 40102.

    [
        client := nodeA connectTo:
            'ws://localhost:40102/ws'.

        result := client
            sendSynchronous: 'system.echo'
            params: {'text' -> 'Hello P2P'} asDictionary.
        self assert: (result at: 'text') equals: 'Hello P2P'.

        "Test disconnect and server-side session cleanup"
        client close.
        (Delay forMilliseconds: 100) wait.
        self assert: nodeB server sessions isEmpty.

    ] ensure: [
        nodeA stop.
        nodeB stop.
    ].
]

{ #category : 'tests' }
NexRPCNodeIntegrationTest >> testUnknownMethod [
    | nodeA nodeB client |

    nodeA := NexRPCNode new.
    nodeB := NexRPCNode new.

    nodeA delegate: NexRPCBaseDelegate new.
    nodeB delegate: NexRPCBaseDelegate new.

    nodeA startOn: 40101.
    nodeB startOn: 40102.

    [
        client := nodeA connectTo: 'ws://localhost:40102/ws'.
        self should: [
            client sendSynchronous: 'test.doesNotExist' params: Dictionary new
        ] raise: NexRPCError.

    ] ensure: [
        nodeA stop.
        nodeB stop.
    ].
]
