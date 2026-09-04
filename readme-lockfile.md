## NexLockFile
<sup>the *NexLockFile package*, part of **TSF-nexutils**, member of the **tiny-frameworks** family</sup>

---

Cross-process file locking for Pharo Smalltalk applications.
`NexLockFile` provides a simple, robust file-locking mechanism for Pharo Smalltalk. It prevents race conditions and data corruption when multiple OS processes, background threads, or Pharo images need to access shared resources (such as log files, local caches, or SQLite databases).

---

## Features

* File-based coordination between processes
* Configurable acquisition timeout
* Configurable retry delay
* Automatic cleanup of stale lock files
* Records the Pharo VM's OS process ID in the lock file
* Supports both `String` paths and `FileReference` objects
* Convenient `critical:` API, executes a block while the corresponding lock file is held.

### Limitations

`NexLockFile` uses the presence of a lock file to coordinate access between processes.

The current implementation is intended for lightweight process coordination. It does not provide the guarantees of a kernel-level file locking mechanism, and applications requiring strict atomic locking semantics should take this into account.

Stale locks are detected based on the modification time of the lock file. Therefore, the configured stale timeout should be chosen carefully for operations that may legitimately run for longer periods.

---

## Installation

`NexLockFile` is part of the `NexUtils-Core` package suite. You can install it via Metacello in your Pharo Image:

```smalltalk
"Without Test"
Metacello new
    repository: "codeberg.org/tiny-frameworks/nexutils-st/src";
    baseline: 'NexUtils';
    load: 'NexUtils-Core'.

"With Tests included"
Metacello new
    repository: "codeberg.org/tiny-frameworks/nexutils-st/src";
    baseline: 'NexUtils';
    load: 'NexUtils-Core-Tests'.    
```

---

## Quick Start

### Recommended Usage: critical:

The critical: block idiom ensures that the lock is guaranteed to be released after the block completes, even if an unhandled exception occurs inside the block.

```smalltalk
| lock |
lock := NexLockFile on: 'path/to/app.lock' asFileReference.

lock critical: [
    "Critical section: process-safe file access"
    'data.json' asFileReference writeStreamDo: [ :stream |
        stream nextPutAll: '{"status": "active"}'
    ]
].
```

The lock file is created while the block is executing and is removed afterwards, including when the block raises an exception.


### Manual Lock Acquisition

If you need fine-grained control over when the lock is acquired and released:

```smalltalk
| lock |
lock := NexLockFile on: 'app.lock' asFileReference.

(lock acquire) ifTrue: [
    [
        "Perform safe operations"
    ] ensure: [ lock release ].
] ifFalse: [
    self inform: 'Could not acquire lock.'
].
```

---

## Advanced Configuration

### Timeout & Retry Interval

You can specify how long NexLockFile should try to acquire a lock before timing out, as well as the pause duration between retries:

```smalltalk
| lock |
lock := (NexLockFile on: 'data.lock' asFileReference)
    timeout: 5 seconds;
    retryInterval: 100 milliSeconds;
    yourself.

lock critical: [
    "Executed if lock acquired within 5 seconds"
] ifTimedOut: [
    self error: 'Could not acquire lock: Operation timed out.'
].
```

The resulting lock file contains diagnostic information similar to:

```text
locked by Pharo PID: 12345 at 2026-09-04T...
```

The PID is the OS process ID of the Pharo VM.

The default lock acquisition timeout is **5 seconds**.

If the lock cannot be acquired within the configured timeout, an `Error` is signaled.

### Stale Lock Cleanup

If a process holding a lock crashes unexpectedly, a stale .lock file might remain on disk. You can configure a maximum lock age to automatically break stale locks:

```smalltalk
| lock |
lock := (NexLockFile on: 'data.lock' asFileReference)
    staleTimeout: 10 minutes; "Locks older than 10 mins are considered stale and broken"
    yourself.
```

The default stale timeout is **30 seconds**.   
This value can be changed through:

```smalltalk
lock staleTimeoutMilliseconds: 60000.
```
---

### Retry Behaviour

When a lock is already present, `NexLockFile` retries until the lock becomes available or the acquisition timeout is reached.

The default retry delay is **10 milliseconds**.

It can be adjusted with:

```smalltalk
lock retryDelayMilliseconds: 50.
```

## API

### The primary API

| Message                   | Description                                          |
| ------------------------- | ---------------------------------------------------- |
| `NexLockFile on:`         | Create a lock for a file or path                     |
| `NexLockFile on:timeout:` | Create a lock with a custom acquisition timeout      |
| `critical:`               | Execute a block while holding the lock               |
| `obtainLock`              | Explicitly acquire the lock                          |
| `releaseLock`             | Explicitly release the lock                          |
| `isLocked`                | Test whether the lock currently exists               |
| `isStale`                 | Test whether the lock has exceeded the stale timeout |

### Defaults

| Setting                  |    Default |
| ------------------------ | ---------: |
| Lock acquisition timeout |  5 seconds |
| Retry delay              |      10 ms |
| Stale lock timeout       | 30 seconds |

---

## Intended Use

`NexLockFile` is deliberately small and independent.

It can be used by applications, services or other NexUtils components whenever a simple file-based synchronization mechanism between OS processes is sufficient.   
Currently, `NexUtils-Logging` uses `NexLockFile` for process-level synchronization.



## Testing

Unit-Tests for the component are located in the corresponding test package.

---

## License
See the [NexUtils repository](readme.md) for organizational information, licensing, contribution and security policies.

---

