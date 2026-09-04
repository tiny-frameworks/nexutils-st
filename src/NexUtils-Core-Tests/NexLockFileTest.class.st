Class {
	#name : 'NexLockFileTest',
	#superclass : 'TestCase',
	#instVars : [
		'testFile',
		'lockFile'
	],
	#category : 'NexUtils-Core-Tests-Core',
	#package : 'NexUtils-Core-Tests',
	#tag : 'Core'
}

{ #category : 'running' }
NexLockFileTest >> setUp [

	super setUp.
	
	"Echte temporäre Datei auf der Festplatte anlegen"
	testFile := (FileSystem disk workingDirectory / ('nexutils-test-' , 999999 atRandom printString , '.log')) asFileReference.
	lockFile := NexLockFile on: testFile.
	

]

{ #category : 'running' }
NexLockFileTest >> tearDown [

	"Rückstandsloses Aufräumen von Test- und Lock-Datei"
	lockFile releaseLock.
	testFile ensureDelete.
	
	super tearDown.
]

{ #category : 'tests' }
NexLockFileTest >> testCriticalExecutesBlockAndDeletesLock [
	| executed |

	executed := false.

	lockFile critical: [
		executed := true.
		self assert: lockFile isLocked ].
		
	self assert: executed.
	self deny: lockFile isLocked

]

{ #category : 'tests' }
NexLockFileTest >> testObtainLockCleansStaleLock [
	| staleLockFile |

	staleLockFile := lockFile lockFileReference.
	
	"1. Verwaistes Lock-File auf der Festplatte anlegen"
	staleLockFile writeStreamDo: [ :stream | 
		stream nextPutAll: 'orphaned lock from crashed process PID: 99999' ].
	
	"2. Stale-Timeout extrem niedrig setzen (1ms) und 10ms warten,"
	"   damit die Datei laut OS modificationTime mathematisch älter als das Timeout ist."
	lockFile staleTimeoutMilliseconds: 1.
	(Delay forMilliseconds: 10) wait.
	
	"3. obtainLock aufrufen - altes File wird als stale erkannt und abgeräumt"
	lockFile obtainLock.
	
	"4. Assertions"
	self assert: lockFile isLocked.
	self assert: (staleLockFile contents includesSubstring: 'PID: ')
	
]

{ #category : 'tests' }
NexLockFileTest >> testTimeoutTriggersError [
	"Erzeuge manuell eine Lock-Datei"

	lockFile lockFileReference writeStreamDo: [ :s | s nextPutAll: 'manual lock' ].
	
	lockFile timeoutMilliseconds: 50.
	
	self should: [ lockFile critical: [ "sollte nicht erreicht werden" ] ] raise: Error
]
