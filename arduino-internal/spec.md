# Arduino Serial Message Specification
## Introduction
NodeFlow uses a serial protocol to communicate with the Arduino. This document describes the protocol.

## Message Format
The message format is as follows:
```
[message type (1 byte)]
[message data]
```

## Message Types
### Arduino to NodeFlow
#### 0x00: Ready
The Arduino is ready to receive a message from NodeFlow. This message is sent when the Arduino is first powered on, and after it has finished processing a message from NodeFlow.

#### 0x01: Error
An error has occurred. The message data is a single byte containing the error code.
Error codes:
* 0x00: Unknown error

#### 0x02: Pin State
The state of a pin has changed. The message data is two bytes, the first containing the pin number and the second containing the pin state.
(This is only sent when SANDBOX mode is enabled.)
```
[0x02]
[pin number]
[pin state]
```
Pin states:
* 0x00: Low
* 0x01: High

#### 0x03: Pin Mode
The mode of a pin has changed. The message data is two bytes, the first containing the pin number and the second containing the pin mode.
(This is only sent when SANDBOX mode is enabled.)
```
[0x03]
[pin number]
[pin mode]
```
Pin modes:
* 0x00: Input
* 0x01: Output

#### 0x04: Analog Pin Value
The value of an analog pin has changed. The message data is two bytes, the first containing the pin number and the second containing the pin value.
(This is only sent when SANDBOX mode is enabled.)
```
[0x04]
[pin number]
[pin value]
```


