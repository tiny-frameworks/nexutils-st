Class {
	#name : 'P2PIntegrationsTest',
	#superclass : 'TestCase',
	#instVars : [
		'server',
		'client',
		'port',
		'node1',
		'node2'
	],
	#category : 'NexUtils-P2P-Tests',
	#package : 'NexUtils-P2P-Tests'
}

{ #category : 'running' }
P2PIntegrationsTest >> setUp [

    super setUp.
    
    "Server mit unserem Test-Delegate starten"
    port := 40000 + 100 atRandom.
    server := NexRPCServer new.
    server delegate: NexRPCAuthTestDelegate new.
    server startOn: port. 
    
    "Client erstellen"
    client := NexRPCClient new.
    "Timeout für Tests etwas aggressiver setzen, falls nötig"
    client requestTimeout: 2.

    node1 := NexRPCClient new.
    node1 requestTimeout: 2.
    node2 := NexRPCClient new.
    node2 requestTimeout: 2.

    (Delay forMilliseconds: 100) wait.
]

{ #category : 'running' }
P2PIntegrationsTest >> tearDown [

    client ifNotNil: [ client close ].
    server ifNotNil: [ server stop ].
    super tearDown.
]

{ #category : 'tests' }
P2PIntegrationsTest >> testBatchRequest [
    "Da der Client sendBatch: hat, testen wir das auch"
    | batch results |
    
    client connectTo: 'ws://localhost:', port asString, '/ws'.
    
    batch := OrderedCollection new.
    batch add: 'system.echo' -> {'id' -> 1} asDictionary.
    batch add: 'system.echo' -> {'id' -> 2} asDictionary.
    
    results := client sendBatch: batch.
    
    self assert: results size equals: 2.
    self assert: ((results first at: 'result') at: 'id') equals: 1.
    self assert: ((results second at: 'result') at: 'id') equals: 2.
]

{ #category : 'tests' }
P2PIntegrationsTest >> testBroadcastNotification [
    "Szenario: server sends a notification to ALL clients."
    
    | sem1 sem2 received1 received2  |
    
    sem1 := Semaphore new.
    sem2 := Semaphore new.
    received1 := nil.
    received2 := nil.
    
    "1. We define what happens when clients receive a notification."
    node1 notificationHandler: [ :json | 
        received1 := json.
        sem1 signal. "Signalisiert: client 1 got something"
    ].
    
    node2 notificationHandler: [ :json | 
        received2 := json. 
        sem2 signal. "Signalisiert: client 2 got something"
    ].
    
    "2. Beide Clients verbinden"
    node1 connectTo: 'ws://localhost:', port asString , '/ws'.
    node2 connectTo: 'ws://localhost:', port asString , '/ws'.
    
    "Wait briefly until the handshake is complete on both sides (important for async tests!)."
    (Delay forMilliseconds: 200) wait.
    
    "Check: Are both actually registered on the server?"
    self assert: server sessions size equals: 2.
    
    "3. ACTION: server sends broadcast"
    server broadcastNotification: 'system.alert' params: {'text' -> 'Shutdown imminent'} asDictionary.
    
    "4. wait for receive (max 1 second)"
    (sem1 waitTimeoutSeconds: 1) ifTrue: [ self fail: 'Timeout: Client 1 hat nichts empfangen' ].
    (sem2 waitTimeoutSeconds: 1) ifTrue: [ self fail: 'Timeout: Client 2 hat nichts empfangen' ].
    
    "5. ASSERT: check content"
    self assert: (received1 at: 'method') equals: 'system.alert'.
    self assert: ((received1 at: 'params') at: 'text') equals: 'Shutdown imminent'.
    
    self assert: (received2 at: 'method') equals: 'system.alert'.
    self assert: ((received2 at: 'params') at: 'text') equals: 'Shutdown imminent'.
]

{ #category : 'tests' }
P2PIntegrationsTest >> testClientErrorHandling [
    "Prüft, ob der Client Server-Fehler korrekt in TsfNexIOError umwandelt"
    
    client connectTo: 'ws://localhost:', port asString, '/ws'.
    
    [ client sendSynchronous: 'error' params: Dictionary new ]
        on: NexRPCError 
        do: [ :ex | 
            "Wir erwarten MethodNotFound (-32601)"
            self assert: ex code equals: -32601. 
            ^ self "Test bestanden"
        ].
        
    self fail: 'Should have raised TsfNexIOError'.
]

{ #category : 'tests' }
P2PIntegrationsTest >> testMethodNotFound [
    "Testet den Fall, wenn der Server die Methode nicht kennt"
    
    client connectTo: 'ws://localhost:', port asString , '/ws'.
    
    [ client sendSynchronous: 'unknownMethod' params: Dictionary new ]
        on: NexRPCError
        do: [ :ex |
            "Wir erwarten den Code für MethodNotFound (meist -32601)"
            self assert: ex code equals: NexRPCConstants methodNotFound code.
            ^ self "Erfolg"
        ].
    self fail: 'Sollte NexError werfen'
]

{ #category : 'tests' }
P2PIntegrationsTest >> testSynchronousEcho [
    "Prüft den Happy Path: Request raus, Response rein, Result extrahieren"
    | result params |
    
    client connectTo: 'ws://localhost:', port asString, '/ws'.
    
    params := {'text' -> 'Pharo rocks'} asDictionary.
    
	"Prüfung des Ergebnisses"
    result := client sendSynchronous: 'system.echo' params: params.
    
    "Dein Client gibt direkt (jsonResponse at: 'result') zurück, also prüfen wir das Dictionary"
    self assert: (result at: 'text') equals: 'Pharo rocks'.

	"Prüfung: Wurde die Session im Delegate gesetzt?"
    self assert: (server delegate lastReceivedSession) notNil.
    self assert: (server delegate lastReceivedSession) socket isConnected
]

{ #category : 'tests' }
P2PIntegrationsTest >> testTimeout [
    "Testet, ob der Timeout-Fehler geworfen wird UND ob er die Methode nennt"
    
    client connectTo: 'ws://localhost:', port asString, '/ws'.
    
    "Timeout extrem kurz setzen z.B. 0.5 sekunden"
    client requestTimeout: 1.
    
    self 
        should: [ 
            "Wir rufen 'slow' auf, was im Delegate 2s dauert"
            client sendSynchronous: 'test.slow' params: Dictionary new 
        ] raise: NexRPCTimeoutError withExceptionDo: [ :ex | 
            "Hier prüfen wir das Innenleben der Exception"
            self assert: (ex messageText includesSubstring: 'test.slow').
            
            "Optional: Prüfen ob params leer waren, wie gesendet"
            self assert: ex params isEmpty.
        ].
]
