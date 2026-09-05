"
Copyright 2026 Georg Hagn
SPDX-License-Identifier: Apache-2.0

I am an abstract Delegate Object and implement some base methods for convenience. App-Delegates kann subclass me. 
See: NexRPCAuthTestDelegate
"
Class {
	#name : 'NexRPCBaseDelegate',
	#superclass : 'Object',
	#instVars : [
		'sessionsMonitor',
		'lastReceivedSession'
	],
	#category : 'NexUtils-P2P-App',
	#package : 'NexUtils-P2P',
	#tag : 'App'
}

{ #category : 'initialization' }
NexRPCBaseDelegate >> initialize [

    super initialize.
    sessionsMonitor := Monitor new.
]

{ #category : 'accessing' }
NexRPCBaseDelegate >> lastReceivedSession [

    ^ lastReceivedSession
]

{ #category : 'hook' }
NexRPCBaseDelegate >> onUserLoggedIn: username session: aSession [
    "Hook for subclasses - Standard: do nothing"

    ^ self
]

{ #category : 'rpc - method' }
NexRPCBaseDelegate >> rpcAuthLogin: params session: aSession [
    "JSON-RPC: auth.login"
    | username |
    
    lastReceivedSession := aSession.
    username := params at: 'username' ifAbsent: [ 
        NexRPCError new
            code: NexRPCConstants invalidParams;
            messageText: 'Missing parameter: username';
            signal.
    ].

    "Session Update"
    aSession user: username.
    aSession isAuthenticated: true.
    
    "Hook for subclassec (e.g. Globale User List)"
    sessionsMonitor critical: [ self onUserLoggedIn: username session: aSession ].
    
    ^ Dictionary new
        at: 'status' put: 'logged_in';
        at: 'user' put: username;
        yourself
]

{ #category : 'subclassing' }
NexRPCBaseDelegate >> rpcMethodNotImplemented: methodName params: params session: aSession [

    self subclassResponsibility
]

{ #category : 'rpc - method' }
NexRPCBaseDelegate >> rpcSystemEcho: params session: aSession [
    "JSON-RPC: system.echo"

    lastReceivedSession := aSession.
    ^ params
]

{ #category : 'rpc - method' }
NexRPCBaseDelegate >> rpcSystemPing: params session: aSession [
    "JSON-RPC: system.ping"

    lastReceivedSession := aSession.
    ^ 'pong'
]
