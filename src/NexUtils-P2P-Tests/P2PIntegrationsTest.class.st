Class {
	#name : 'P2PIntegrationsTest',
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
P2PIntegrationsTest >> setUp [

    super setUp.
    
    "Server mit unserem Test-Delegate starten"
    port := 40000 + 100 atRandom.
    server := NexRPCServer new.
    server delegate: TsfNexIOTestDelegate new.
    server startOn: port. 
    
    "Client erstellen"
    client := NexRPCClient new.
    "Timeout für Tests etwas aggressiver setzen, falls nötig"
    client requestTimeout: 2.

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
    batch add: 'echo' -> {'id' -> 1} asDictionary.
    batch add: 'echo' -> {'id' -> 2} asDictionary.
    
    results := client sendBatch: batch.
    
    self assert: results size equals: 2.
    self assert: ((results first at: 'result') at: 'id') equals: 1.
    self assert: ((results second at: 'result') at: 'id') equals: 2.
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
    result := client sendSynchronous: 'echo' params: params.
    
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
            client sendSynchronous: 'slow' params: Dictionary new 
        ] raise: NexRPCTimeoutError withExceptionDo: [ :ex | 
            "Hier prüfen wir das Innenleben der Exception"
            self assert: (ex messageText includesSubstring: 'slow').
            
            "Optional: Prüfen ob params leer waren, wie gesendet"
            self assert: ex params isEmpty.
        ].
]
