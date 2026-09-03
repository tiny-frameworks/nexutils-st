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

    nodeA delegate: TsfNexIOTestDelegate new.
    nodeB delegate: TsfNexIOTestDelegate new.

    nodeA startOn: 40101.
    nodeB startOn: 40102.

    [
        "A -> B"
        client := nodeA connectTo:
            'ws://localhost:40102/ws'.

        (Delay forMilliseconds: 100) wait.

        result := client
            sendSynchronous: 'echo'
            params: {'text' -> 'Hello P2P'} asDictionary.

        self assert: (result at: 'text')
            equals: 'Hello P2P'.

        "B -> A over the same WebSocket connection"
        session := nodeB server sessions anyOne.

        result := session
            sendSynchronous: 'echo'
            params: {'text' -> 'Hello back from B'} asDictionary.

        self assert: (result at: 'text')
            equals: 'Hello back from B'.

    ] ensure: [
        nodeA stop.
        nodeB stop.
    ].
]

{ #category : 'tests' }
NexRPCNodeIntegrationTest >> testNodeToNode [
| nodeA nodeB client result session |

    nodeA := NexRPCNode new.
    nodeB := NexRPCNode new.

    nodeA delegate: TsfNexIOTestDelegate new.
    nodeB delegate: TsfNexIOTestDelegate new.

    nodeA startOn: 40101.
    nodeB startOn: 40102.

    [
        "A -> B"
        client := nodeA connectTo:
            'ws://localhost:40102/ws'.

        (Delay forMilliseconds: 100) wait.

        self assert: nodeB server sessions size equals: 1.

        result := client
            sendSynchronous: 'echo'
            params: {'text' -> 'Hello P2P'} asDictionary.

        self assert: (result at: 'text') equals: 'Hello P2P'.

        "B -> A using the existing connection"
        session := nodeB server sessions anyOne.

        result := session
            sendSynchronous: 'echo'
            params: {'text' -> 'Hello back from B'} asDictionary.

        self assert: (result at: 'text') equals: 'Hello back from B'.

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

    nodeA delegate: TsfNexIOTestDelegate new.
    nodeB delegate: TsfNexIOTestDelegate new.

    nodeA startOn: 40101.
    nodeB startOn: 40102.

    [
        client := nodeA connectTo:
            'ws://localhost:40102/ws'.

        result := client
            sendSynchronous: 'echo'
            params: {'text' -> 'Hello P2P'} asDictionary.

        self assert: (result at: 'text') equals: 'Hello P2P'.

    ] ensure: [
        nodeA stop.
        nodeB stop.
    ].
]
