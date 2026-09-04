"
Copyright 2026 Georg Hagn
SPDX-License-Identifier: Apache-2.0

I am a cross-process file locking system for applications.

I provide a simple, robust file-locking mechanism and I prevent race conditions and data corruption when multiple OS processes, background threads, or images need to access shared resources (such as log files, local caches, or SQLite databases)

"
Class {
	#name : 'NexLockFile',
	#superclass : 'Object',
	#instVars : [
		'fileReference',
		'timeoutMilliseconds',
		'retryDelayMilliseconds',
		'staleTimeoutMilliseconds'
	],
	#category : 'NexUtils-Core-Core',
	#package : 'NexUtils-Core',
	#tag : 'Core'
}

{ #category : 'instance creation' }
NexLockFile class >> on: aFileReference [

	^ self new
		fileReference: aFileReference;
		yourself
]

{ #category : 'instance creation' }
NexLockFile class >> on: aFileReference timeout: aDuration [

	^ self new
		fileReference: aFileReference;
		timeoutMilliseconds: aDuration asMilliSeconds;
		yourself
]

{ #category : 'writing' }
NexLockFile >> checkAndCleanStaleLock [
	"Falls das Lock verwaist ist, löschen wir es sicherheitshalber"
	
	self isStale ifTrue: [
		[ fileReference ensureDelete ] 
			on: Error 
			do: [ :ex | "Falls ein anderer Prozess das Lock exakt im selben Moment gelöscht hat" ] ]

]

{ #category : 'mutual exclusion' }
NexLockFile >> critical: aBlock [

	"Führt aBlock aus, während die Lock-Datei existiert (mit Timeout/Retry)"
	self obtainLock.
	^ [ aBlock value ] ensure: [ self releaseLock ]
]

{ #category : 'api - processes' }
NexLockFile >> currentProcessId [
	"Liefert die echte OS-Prozess-ID (PID) der Virtual Machine zurück"

	^ LibC uniqueInstance currentProcessId

]

{ #category : 'accessing' }
NexLockFile >> fileReference [

	^ fileReference
]

{ #category : 'accessing' }
NexLockFile >> fileReference: aFileReference [
	"Akzeptiert sowohl String-Pfade als auch FileReference-Objekte"

	fileReference := aFileReference asFileReference.
	fileReference isDirectory ifTrue: [ 
		fileReference := fileReference / 'process.lock' ]
	ifFalse: [ 
		(fileReference extension = 'lock') ifFalse: [ 
			fileReference := (fileReference fullName , '.lock') asFileReference ] ]
	
]

{ #category : 'initialization' }
NexLockFile >> initialize [

	super initialize.
	timeoutMilliseconds := 5000. "Default: 5 Sekunden Timeout"
	retryDelayMilliseconds := 10. "Default: 10ms Pause zwischen Versuchen"
	staleTimeoutMilliseconds := 30000. "Max. Alter eines Locks bevor es gelöscht wird (30s)"
]

{ #category : 'testing' }
NexLockFile >> isLocked [

	^ fileReference exists
]

{ #category : 'testing' }
NexLockFile >> isStale [
	"Prüft, ob die Lock-Datei existiert und älter als das Stale-Timeout ist"
	| modTime |
	
	fileReference exists ifFalse: [ ^ false ].
	
	modTime := fileReference modificationTime.
	^ (DateAndTime now - modTime) asMilliSeconds > staleTimeoutMilliseconds

]

{ #category : 'accessing' }
NexLockFile >> lockFileReference [

	^ fileReference
]

{ #category : 'writing' }
NexLockFile >> obtainLock [
	| startTime delay |
	
	startTime := DateAndTime now.
	delay := Delay forMilliseconds: retryDelayMilliseconds.

	[ self isLocked ] whileTrue: [
		"1. Verwaiste Locks automatisch aufräumen"
		self checkAndCleanStaleLock.
		
		"2. Auf normales Timeout prüfen"
		((DateAndTime now - startTime) asMilliSeconds > timeoutMilliseconds) ifTrue: [ 
			Error signal: ('Could not obtain file lock for {1} within {2} ms' 
				format: { fileReference fullName . timeoutMilliseconds }) ].
				
		delay wait ].

	self writeLockFile

]

{ #category : 'writing' }
NexLockFile >> releaseLock [

	fileReference ensureDelete
]

{ #category : 'accessing' }
NexLockFile >> retryDelayMilliseconds [

	^ retryDelayMilliseconds
]

{ #category : 'accessing' }
NexLockFile >> retryDelayMilliseconds: anInteger [

	retryDelayMilliseconds := anInteger
]

{ #category : 'accessing' }
NexLockFile >> staleTimeoutMilliseconds: anInteger [

	staleTimeoutMilliseconds := anInteger
]

{ #category : 'accessing' }
NexLockFile >> timeoutMilliseconds [

	^ timeoutMilliseconds
]

{ #category : 'accessing' }
NexLockFile >> timeoutMilliseconds: anInteger [

	timeoutMilliseconds := anInteger
]

{ #category : 'writing' }
NexLockFile >> writeLockFile [
[ 
		fileReference writeStreamDo: [ :stream |
			stream 
				nextPutAll: 'locked by Pharo PID: ';
				nextPutAll: self currentProcessId printString;
				nextPutAll: ' at ';
				nextPutAll: DateAndTime now asString ]
	] on: Error do: [ :ex |
		Error signal: 'Failed to write lock file: ', ex description ]
]
