//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Binary Parsing open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import BinaryParsing
import BinarySerialization
import Testing

// MARK: - Test helper

/// Drives a serialization state machine to completion using output spans
/// of the given capacity. Returns all serialized bytes.
@available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
func serializeToBytes<T: SerializableToBytes>(
    _ value: borrowing T,
    outputSpanCapacity: Int = 256
) throws -> [UInt8] {
    var state = try T.startSerialization(of: value)
    var result: [UInt8] = []
    while true {
        var done = false
        let chunk = Array<UInt8>(capacity: outputSpanCapacity) { output in
            done = T.serialize(state: &state, into: &output)
        }
        result.append(contentsOf: chunk)
        if done { break }
    }
    return result
}

// MARK: - Tests

@Suite
struct UInt8SerializationTests {
    @Test
    @available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
    func serializeSingleByte() throws {
        let bytes = try serializeToBytes(UInt8(0x42))
        #expect(bytes == [0x42])
    }

    @Test
    @available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
    func serializeZero() throws {
        let bytes = try serializeToBytes(UInt8(0x00))
        #expect(bytes == [0x00])
    }

    @Test
    @available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
    func serializeMax() throws {
        let bytes = try serializeToBytes(UInt8(0xFF))
        #expect(bytes == [0xFF])
    }

    @Test
    @available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
    func serializeOneByteAtATime() throws {
        let bytes = try serializeToBytes(UInt8(0xAB), outputSpanCapacity: 1)
        #expect(bytes == [0xAB])
    }
}

@Suite
struct Int8SerializationTests {
    @Test
    @available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
    func serializePositive() throws {
        let bytes = try serializeToBytes(Int8(127))
        #expect(bytes == [0x7F])
    }

    @Test
    @available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
    func serializeNegative() throws {
        let bytes = try serializeToBytes(Int8(-1))
        #expect(bytes == [0xFF])
    }
}

@Suite
struct UInt16SerializationTests {
    @Test
    @available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
    func serializeBigEndian() throws {
        let bytes = try serializeToBytes(UInt16(0x0102))
        #expect(bytes == [0x01, 0x02])
    }

    @Test
    @available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
    func serializeLittleEndian() throws {
        var state = UInt16.startSerialization(of: 0x0102, endianness: .little)
        let bytes = Array<UInt8>(capacity: 2) { output in
            UInt16.serialize(state: &state, into: &output)
        }
        #expect(bytes == [0x02, 0x01])
    }

    @Test
    @available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
    func serializeOneByteAtATime() throws {
        let bytes = try serializeToBytes(UInt16(0xABCD), outputSpanCapacity: 1)
        #expect(bytes == [0xAB, 0xCD])
    }
}

@Suite
struct UInt32SerializationTests {
    @Test
    @available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
    func serializeBigEndian() throws {
        let bytes = try serializeToBytes(UInt32(0x12345678))
        #expect(bytes == [0x12, 0x34, 0x56, 0x78])
    }

    @Test
    @available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
    func serializeLittleEndian() throws {
        var state = UInt32.startSerialization(of: 0x12345678, endianness: .little)
        let bytes = Array<UInt8>(capacity: 4) { output in
            UInt32.serialize(state: &state, into: &output)
        }
        #expect(bytes == [0x78, 0x56, 0x34, 0x12])
    }

    @Test
    @available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
    func serializeOneByteAtATime() throws {
        let bytes = try serializeToBytes(UInt32(0x12345678), outputSpanCapacity: 1)
        #expect(bytes == [0x12, 0x34, 0x56, 0x78])
    }

    @Test
    @available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
    func serializeTwoBytesAtATime() throws {
        let bytes = try serializeToBytes(UInt32(0xDEADBEEF), outputSpanCapacity: 2)
        #expect(bytes == [0xDE, 0xAD, 0xBE, 0xEF])
    }

    @Test
    @available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
    func serializeZero() throws {
        let bytes = try serializeToBytes(UInt32(0))
        #expect(bytes == [0x00, 0x00, 0x00, 0x00])
    }
}

@Suite
struct UInt64SerializationTests {
    @Test
    @available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
    func serializeBigEndian() throws {
        let bytes = try serializeToBytes(UInt64(0x0102030405060708))
        #expect(bytes == [0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08])
    }

    @Test
    @available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
    func serializeOneByteAtATime() throws {
        let bytes = try serializeToBytes(
            UInt64(0xDEADBEEFCAFEBABE),
            outputSpanCapacity: 1
        )
        #expect(bytes == [0xDE, 0xAD, 0xBE, 0xEF, 0xCA, 0xFE, 0xBA, 0xBE])
    }
}

@Suite
struct SignedIntegerSerializationTests {
    @Test
    @available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
    func serializeInt16() throws {
        let bytes = try serializeToBytes(Int16(-1))
        #expect(bytes == [0xFF, 0xFF])
    }

    @Test
    @available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
    func serializeInt32() throws {
        let bytes = try serializeToBytes(Int32(256))
        #expect(bytes == [0x00, 0x00, 0x01, 0x00])
    }

    @Test
    @available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
    func serializeInt64() throws {
        let bytes = try serializeToBytes(Int64(-1))
        #expect(bytes == [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF])
    }
}

@Suite
struct ByteArraySerializationTests {
    @Test
    @available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
    func serializeEmpty() throws {
        let bytes = try serializeToBytes([UInt8]())
        #expect(bytes.isEmpty)
    }

    @Test
    @available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
    func serializeSingle() throws {
        let bytes = try serializeToBytes([UInt8(0xAA)])
        #expect(bytes == [0xAA])
    }

    @Test
    @available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
    func serializeMultiple() throws {
        let payload: [UInt8] = [0xAA, 0xBB, 0xCC, 0xDD]
        let bytes = try serializeToBytes(payload)
        #expect(bytes == payload)
    }

    @Test
    @available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
    func serializeOneByteAtATime() throws {
        let payload: [UInt8] = [0x01, 0x02, 0x03, 0x04, 0x05]
        let bytes = try serializeToBytes(payload, outputSpanCapacity: 1)
        #expect(bytes == payload)
    }

    @Test
    @available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
    func serializeTwoBytesAtATime() throws {
        let payload: [UInt8] = [0x01, 0x02, 0x03, 0x04, 0x05]
        let bytes = try serializeToBytes(payload, outputSpanCapacity: 2)
        #expect(bytes == payload)
    }
}

@Suite
struct RoundTripTests {
    @Test
    @available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
    func roundTripUInt32() throws {
        let original: UInt32 = 0xDEADBEEF
        let bytes = try serializeToBytes(original)
        let parsed = try bytes.withParserSpan { span in
            try UInt32(parsingBigEndian: &span)
        }
        #expect(parsed == original)
    }

    @Test
    @available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
    func roundTripUInt16() throws {
        let original: UInt16 = 0xCAFE
        let bytes = try serializeToBytes(original)
        let parsed = try bytes.withParserSpan { span in
            try UInt16(parsingBigEndian: &span)
        }
        #expect(parsed == original)
    }

    @Test
    @available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
    func roundTripUInt64() throws {
        let original: UInt64 = 0x0102030405060708
        let bytes = try serializeToBytes(original)
        let parsed = try bytes.withParserSpan { span in
            try UInt64(parsingBigEndian: &span)
        }
        #expect(parsed == original)
    }
}

// MARK: - Composition example

@available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
struct LengthPrefixedMessage: SerializableToBytes {
    var payload: [UInt8]

    enum SerializationState {
        case length(
            FixedSizeSerializationState<2>,
            pendingPayload: [UInt8]
        )
        case payload(Array<UInt8>.SerializationState)
    }

    static func startSerialization(
        of value: borrowing LengthPrefixedMessage
    ) throws(SerializationError) -> SerializationState {
        let payload = Array(value.payload)
        guard let length = UInt16(exactly: payload.count) else {
            throw SerializationError(status: .valueTooLarge)
        }
        let lengthState = try UInt16.startSerialization(of: length)
        return .length(lengthState, pendingPayload: payload)
    }

    @discardableResult
    static func serialize(
        state: inout SerializationState,
        into output: inout OutputSpan<UInt8>
    ) -> Bool {
        switch state {
        case .length(var lengthState, let pendingPayload):
            if lengthState.serialize(into: &output) {
                var payloadState = try! [UInt8].startSerialization(
                    of: pendingPayload
                )
                if [UInt8].serialize(state: &payloadState, into: &output) {
                    return true
                }
                state = .payload(payloadState)
                return false
            }
            state = .length(lengthState, pendingPayload: pendingPayload)
            return false
        case .payload(var payloadState):
            let done = [UInt8].serialize(
                state: &payloadState, into: &output
            )
            if !done {
                state = .payload(payloadState)
            }
            return done
        }
    }
}

@Suite
struct CompositionTests {
    @Test
    @available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
    func serializeLengthPrefixedMessage() throws {
        let msg = LengthPrefixedMessage(payload: [0x41, 0x42, 0x43])
        let bytes = try serializeToBytes(msg)
        #expect(bytes == [0x00, 0x03, 0x41, 0x42, 0x43])
    }

    @Test
    @available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
    func serializeLengthPrefixedOneByteAtATime() throws {
        let msg = LengthPrefixedMessage(payload: [0x41, 0x42, 0x43])
        let bytes = try serializeToBytes(msg, outputSpanCapacity: 1)
        #expect(bytes == [0x00, 0x03, 0x41, 0x42, 0x43])
    }

    @Test
    @available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
    func serializeEmptyPayload() throws {
        let msg = LengthPrefixedMessage(payload: [])
        let bytes = try serializeToBytes(msg)
        #expect(bytes == [0x00, 0x00])
    }

    @Test
    @available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
    func serializeLargePayload() throws {
        let payload = [UInt8](repeating: 0xAA, count: 300)
        let msg = LengthPrefixedMessage(payload: payload)
        let bytes = try serializeToBytes(msg)
        #expect(bytes.count == 302)
    }

    @Test
    @available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
    func valueTooLargeThrows() throws {
        let msg = LengthPrefixedMessage(
            payload: [UInt8](repeating: 0xAA, count: Int(UInt16.max) + 1)
        )
        #expect(throws: SerializationError.self) {
            _ = try LengthPrefixedMessage.startSerialization(of: msg)
        }
    }
}
