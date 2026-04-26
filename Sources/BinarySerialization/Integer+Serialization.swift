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

public import BinaryParsing

// MARK: - Single-byte integers

@available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
extension UInt8: SerializableToBytes {
    public typealias SerializationState = FixedSizeSerializationState<1>

    @inlinable
    public static func startSerialization(
        of value: borrowing UInt8
    ) throws(SerializationError) -> SerializationState {
        FixedSizeSerializationState(bytes: InlineArray(repeating: copy value))
    }

    @inlinable
    @discardableResult
    public static func serialize(
        state: inout SerializationState,
        into output: inout OutputSpan<UInt8>
    ) -> Bool {
        state.serialize(into: &output)
    }
}

@available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
extension Int8: SerializableToBytes {
    public typealias SerializationState = FixedSizeSerializationState<1>

    @inlinable
    public static func startSerialization(
        of value: borrowing Int8
    ) throws(SerializationError) -> SerializationState {
        FixedSizeSerializationState(
            bytes: InlineArray(repeating: UInt8(bitPattern: copy value))
        )
    }

    @inlinable
    @discardableResult
    public static func serialize(
        state: inout SerializationState,
        into output: inout OutputSpan<UInt8>
    ) -> Bool {
        state.serialize(into: &output)
    }
}

// MARK: - Multi-byte integers

@available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
extension UInt16: SerializableToBytes {
    public typealias SerializationState = FixedSizeSerializationState<2>

    @inlinable
    public static func startSerialization(
        of value: borrowing UInt16
    ) throws(SerializationError) -> SerializationState {
        startSerialization(of: value, endianness: .big)
    }

    @inlinable
    @discardableResult
    public static func serialize(
        state: inout SerializationState,
        into output: inout OutputSpan<UInt8>
    ) -> Bool {
        state.serialize(into: &output)
    }
}

@available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
extension UInt16 {
    /// Begins serialization with the specified byte order.
    @inlinable
    public static func startSerialization(
        of value: UInt16,
        endianness: Endianness
    ) -> SerializationState {
        let bytes: InlineArray<2, UInt8>
        if endianness.isBigEndian {
            bytes = InlineArray { i in
                UInt8(truncatingIfNeeded: value >> (8 * (1 - i)))
            }
        } else {
            bytes = InlineArray { i in
                UInt8(truncatingIfNeeded: value >> (8 * i))
            }
        }
        return FixedSizeSerializationState(bytes: bytes)
    }
}

@available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
extension Int16: SerializableToBytes {
    public typealias SerializationState = FixedSizeSerializationState<2>

    @inlinable
    public static func startSerialization(
        of value: borrowing Int16
    ) throws(SerializationError) -> SerializationState {
        try UInt16.startSerialization(of: UInt16(bitPattern: value))
    }

    @inlinable
    @discardableResult
    public static func serialize(
        state: inout SerializationState,
        into output: inout OutputSpan<UInt8>
    ) -> Bool {
        state.serialize(into: &output)
    }
}

@available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
extension UInt32: SerializableToBytes {
    public typealias SerializationState = FixedSizeSerializationState<4>

    @inlinable
    public static func startSerialization(
        of value: borrowing UInt32
    ) throws(SerializationError) -> SerializationState {
        startSerialization(of: value, endianness: .big)
    }

    @inlinable
    @discardableResult
    public static func serialize(
        state: inout SerializationState,
        into output: inout OutputSpan<UInt8>
    ) -> Bool {
        state.serialize(into: &output)
    }
}

@available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
extension UInt32 {
    /// Begins serialization with the specified byte order.
    @inlinable
    public static func startSerialization(
        of value: UInt32,
        endianness: Endianness
    ) -> SerializationState {
        let bytes: InlineArray<4, UInt8>
        if endianness.isBigEndian {
            bytes = InlineArray { i in
                UInt8(truncatingIfNeeded: value >> (8 * (3 - i)))
            }
        } else {
            bytes = InlineArray { i in
                UInt8(truncatingIfNeeded: value >> (8 * i))
            }
        }
        return FixedSizeSerializationState(bytes: bytes)
    }
}

@available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
extension Int32: SerializableToBytes {
    public typealias SerializationState = FixedSizeSerializationState<4>

    @inlinable
    public static func startSerialization(
        of value: borrowing Int32
    ) throws(SerializationError) -> SerializationState {
        try UInt32.startSerialization(of: UInt32(bitPattern: value))
    }

    @inlinable
    @discardableResult
    public static func serialize(
        state: inout SerializationState,
        into output: inout OutputSpan<UInt8>
    ) -> Bool {
        state.serialize(into: &output)
    }
}

@available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
extension UInt64: SerializableToBytes {
    public typealias SerializationState = FixedSizeSerializationState<8>

    @inlinable
    public static func startSerialization(
        of value: borrowing UInt64
    ) throws(SerializationError) -> SerializationState {
        startSerialization(of: value, endianness: .big)
    }

    @inlinable
    @discardableResult
    public static func serialize(
        state: inout SerializationState,
        into output: inout OutputSpan<UInt8>
    ) -> Bool {
        state.serialize(into: &output)
    }
}

@available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
extension UInt64 {
    /// Begins serialization with the specified byte order.
    @inlinable
    public static func startSerialization(
        of value: UInt64,
        endianness: Endianness
    ) -> SerializationState {
        let bytes: InlineArray<8, UInt8>
        if endianness.isBigEndian {
            bytes = InlineArray { i in
                UInt8(truncatingIfNeeded: value >> (8 * (7 - i)))
            }
        } else {
            bytes = InlineArray { i in
                UInt8(truncatingIfNeeded: value >> (8 * i))
            }
        }
        return FixedSizeSerializationState(bytes: bytes)
    }
}

@available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
extension Int64: SerializableToBytes {
    public typealias SerializationState = FixedSizeSerializationState<8>

    @inlinable
    public static func startSerialization(
        of value: borrowing Int64
    ) throws(SerializationError) -> SerializationState {
        try UInt64.startSerialization(of: UInt64(bitPattern: value))
    }

    @inlinable
    @discardableResult
    public static func serialize(
        state: inout SerializationState,
        into output: inout OutputSpan<UInt8>
    ) -> Bool {
        state.serialize(into: &output)
    }
}
