Class {
	#name : 'NexRPCAuthTest',
	#superclass : 'TestCase',
	#instVars : [
		'server',
		'client',
		'port'
	],
	#category : 'NexUtils-P2P-Tests',
	#package : 'NexUtils-P2P-Tests'
}

{ #category : 'running' }
NexRPCAuthTest >> setUp [

    super setUp.
       "Server mit unserem Test-Delegate starten"

    port := 40000 + 100 atRandom.
    server := NexRPCServer new.
    server delegate: NexRPCAuthTestDelegate new.
    server startOn: port.
    
    client := NexRPCClient new.
    client requestTimeout: 10.

    (Delay forMilliseconds: 100) wait.
    client connectTo: 'ws://localhost:', port asString , '/ws'.
]

{ #category : 'running' }
NexRPCAuthTest >> tearDown [

    client ifNotNil: [ client close ].
    server ifNotNil: [ server stop ].

    super tearDown.
]

{ #category : 'tests' }
NexRPCAuthTest >> testAuthLogin [
    "Check login-flow and put session-attribute"
    | result params session |
    
    params := {'username' -> 'NexRPCUser'} asDictionary.
    
    "1. Send Login Request"
    result := client sendSynchronous: 'auth.login' params: params.
    
    "2. Check answer"
    self assert: (result at: 'status') equals: 'logged_in'.
    self assert: (result at: 'user') equals: 'NexRPCUser'.

    "3. Check server-states (session), we have only one"
    session := server sessions anyOne.
    self assert: session isAuthenticated.
    self assert: session user equals: 'NexRPCUser'

]

{ #category : 'tests' }
NexRPCAuthTest >> testSystemPing [
    "Checks subclassed system-method"
    | result |

    result := client sendSynchronous: 'system.ping' params: Dictionary new.
    self assert: result equals: 'pong'.
]
