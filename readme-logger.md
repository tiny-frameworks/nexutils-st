## NexUtils-Logging
<sup>the *NexUtils-Logging package*, part of **TSF-nexutils**, member of the **tiny-frameworks** family</sup>

---

`NexUtils-Logging` is a lightweight yet powerful logging library designed for production Pharo Smalltalk applications. It supports structured logging (JSON/Plain text), multi-appender output routing, log levels, and non-blocking asynchronous background execution to preserve UI and worker thread performance.

---

## Features

* **Structured Logging:** Attach key-value payloads (Dictionaries) to log events for machine-readable logging (log/slog, Loki, Elasticsearch, Logstash).
* **Multiple Log Levels:** Standardized levels (`DEBUG`, `INFO`, `WARN`, `ERROR`, `FATAL`).
* **Modular Appenders:** Route logs simultaneously to multiple targets:
  * `NexTranscriptAppender`: Formatted output directly to the Pharo Transcript.
  * `NexFileAppender`: Synchronous or buffered file writing with customizable formatters.
* **Asynchronous Execution (`NexAsyncLogAppender`):** Dispatches log processing to a dedicated background process via a shared concurrent queue, preventing I/O stalls in critical execution paths.
* **Integrated Process Safety:** Works seamlessly with `NexLockFile` for process-safe multi-image file writes.
* **Zero External Dependencies:** Native Pharo Smalltalk implementation (compatible with Pharo 11, 12, 13, and 14).

---

## Installation

Install `NexUtils-Logging` via Metacello:

```smalltalk
"Without Tests"
Metacello new
    repository: "codeberg.org/tiny-frameworks/nexutils-st/src";
    baseline: 'NexUtils';
    load: 'NexUtils-Logging'.

"With Test included"
Metacello new
    repository: "codeberg.org/tiny-frameworks/nexutils-st/src";
    baseline: 'NexUtils';
    load: 'NexUtils-Logging-Test'.    
```

---

## Quick Start

### Basic Setup with Transcript Logging

```smalltalk
| logger transcriptAppender |
logger := NexLogger named: 'AppLogger'.
logger minLevel: NexLogLevel info.

transcriptAppender := NexTranscriptAppender new.
logger addAppender: transcriptAppender.

logger info: 'Application started successfully'.
logger debug: 'This message will be skipped due to minLevel'.
logger error: 'Database connection failed' payload: { #port -> 5432. #host -> 'localhost' } asDictionary.
```

### Non-Blocking Asynchronous File Logging

To avoid blocking UI threads or critical processing loops during disk I/O, wrap any appender inside a NexAsyncLogAppender:

```smalltalk
| logger fileAppender asyncAppender |
logger := NexLogger named: 'ServiceLogger'.

"1. Configure file appender with JSON formatting"
fileAppender := NexFileAppender on: 'logs/service.log' asFileReference.
fileAppender formatter: NexJsonFormatter new.

"2. Wrap in an asynchronous worker appender"
asyncAppender := NexAsyncLogAppender wrapping: fileAppender.
asyncAppender start. "Spawns background process queue worker"

logger addAppender: asyncAppender.

"3. Log events without I/O blocking"
logger info: 'Processing request' payload: { #requestId -> 'REQ-1042' } asDictionary.

"4. Stop worker on application shutdown"
asyncAppender stop.
```

---

## Architecture Overview

                        +-------------------+
                        |     NexLogger     |
                        +---------+---------+
                                  |
                   +--------------+--------------+
                   |                             |
       +-----------v-----------+     +-----------v-----------+
       | NexTranscriptAppender |     |  NexAsyncLogAppender  |
       +-----------------------+     +-----------+-----------+
                                                 | (Async Queue)
                                     +-----------v-----------+
                                     |    NexFileAppender    |
                                     +-----------------------+

---

## Testing

Unit-Tests for the component are located in the corresponding test package.

---

## License
See the [NexUtils repository](readme.md) for organizational information, licensing, contribution and security policies.

---
