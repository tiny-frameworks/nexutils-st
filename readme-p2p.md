## NexUtils-P2P
<sup>the *NexUtils-P2P package*, part of **TSF-nexutils**, member of the **tiny-frameworks** family</sup>

---

***A lightweight JSON-RPC 2.0 over WebSocket framework for [Pharo Smalltalk](https://pharo.org/).***

`NexUtils-P2P` provides the building blocks for communicating Smalltalk nodes over WebSockets. A node can
act as both **client and server**, allowing bidirectional request/response communication between peers.

## Features

* JSON-RPC 2.0 requests, responses and notifications
* WebSocket transport using `ZnWebSocket`
* Bidirectional communication between nodes
* Synchronous request/response API
* Batch requests
* Request timeouts
* Session-based request tracking
* Delegate-based RPC dispatch
* Concurrent connections
* Lightweight P2P node abstraction

## Architecture

The framework is built around a small set of cooperating classes:

```text
                  NexRPCNode
                    |    |
          +---------+    +--------+
          |                       | 
      NexRPCServer           NexRPCClient
          |                       |
          +---- NexRPCSession ----+
                     |
               NexRPCDispatcher
                     |
                  Delegate
```

### NexRPCNode

`NexRPCNode` is the main P2P abstraction. A `NexRPCNode` can:

* start a WebSocket server
* connect to other nodes
* manage outgoing clients
* provide a common RPC delegate

### NexRPCClient

`NexRPCClient` handles an outgoing WebSocket connection.

Typical usage:

```smalltalk
client := NexRPCClient new.
client connectTo: 'ws://localhost:40001/ws'.

result := client
    sendSynchronous: 'system.echo'
    params: {'text' -> 'Hello P2P'} asDictionary.
```

### NexRPCServer

`NexRPCServer` accepts incoming WebSocket connections and creates a `NexSession` for each connection.

### NexRPCSession

`NexRPCSession` represents one active connection. The session owns the state required for request/response handling, including:

* request IDs
* pending requests
* response synchronization
* request timeouts
* the underlying WebSocket

### NexRPCDispatcher

`NexRPCDispatcher` Maps incoming JSON-RPC requests to methods on the configured delegate.

For example:

```text
system.echo
  ↓
rpcSystemEcho:session:
```

The delegate therefore provides the application-specific RPC methods. (see also [why dotted-methods](dotted-methods.md))

---

## NexRPCDelegate

A delegate implements RPC methods following the `rpc...:session:` convention. See `NexRPCTestDelegate`.

Example:

```smalltalk
rpcEcho: params session: session

    ^ params
```

The session is available to the delegate when an RPC needs access to the underlying connection.

---

## Batch Requests

Multiple requests can be sent as a batch:

```smalltalk
batch := OrderedCollection new.
batch add: 'echo' -> {'id' -> 1} asDictionary.
batch add: 'echo' -> {'id' -> 2} asDictionary.

results := client sendBatch: batch.
```
---

## Notifications

JSON-RPC notifications can be sent without waiting for a response.

```smalltalk
client
    sendNotification: 'event'
    params: {'value' -> 42} asDictionary.
```
---

## Status

NexUtils-P2P is currently under active development.

The current implementation is functional and covered by integration tests, including:

* request/response
* bidirectional communication
* batch requests
* notifications
* request timeouts
* multiple node connections

The API may still evolve.

---

## Requirements

* [Pharo Smalltalk](https://pharo.org/)
* WebSocket support via Pharo's Zinc networking framework
* NeoJSON

---

## License
See the [NexUtils repository](readme.md) for organizational information, licensing, contribution and security policies.

---

