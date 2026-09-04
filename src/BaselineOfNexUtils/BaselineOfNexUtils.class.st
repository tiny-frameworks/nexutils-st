Class {
	#name : 'BaselineOfNexUtils',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfNexUtils',
	#package : 'BaselineOfNexUtils'
}

{ #category : 'loading' }
BaselineOfNexUtils class >> load [
    Metacello new
        baseline: 'NexUtils';
        repository: 'github://<USER>/<REPOSITORY>';
        onWarning: [ :warning |
            (warning isKindOf: MCMergeOrLoadWarning)
                ifTrue: [ warning load ]
                ifFalse: [ warning resume ] ];
        load


]

{ #category : 'baselines' }
BaselineOfNexUtils >> baseline: spec [
    <baseline>

    spec for: #common do: [

        "External dependencies"
        spec baseline: 'NeoJSON' with: [
            spec repository: 'github://svenvc/NeoJSON/repository' ].

        spec baseline: 'ZincHTTPComponents' with: [
            spec repository: 'github://svenvc/zinc/repository';
        loads: #('WebSocket') ].

        "NexUtils-Core"
        spec package: 'NexUtils-Core'.

        spec package: 'NexUtils-Core-Tests' with: [
            spec requires: #('NexUtils-Core') ].

        "NexUtils-Logging"
        spec package: 'NexUtils-Logging' with: [
            spec requires: #('NexUtils-Core') ].

        spec package: 'NexUtils-Logging-Tests' with: [
            spec requires: #(
                'NexUtils-Core'
                'NexUtils-Logging'
            ) ].

        "NexUtils-P2P"
        spec package: 'NexUtils-P2P' with: [
            spec requires: #(
                'NexUtils-Core'
                'NexUtils-Logging'
                'NeoJSON'
                'ZincHTTPComponents'
            ) ].

        spec package: 'NexUtils-P2P-Tests' with: [
            spec requires: #('NexUtils-P2P') ].
    ].
]
