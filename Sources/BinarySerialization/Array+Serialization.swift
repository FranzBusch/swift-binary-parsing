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

/// Serialization support for byte arrays.
@available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
extension Array: SerializableToBytes where Element == UInt8 {
    /// Tracks the write offset into the byte array.
    public struct SerializationState: Sendable {
        @usableFromInline
        var bytes: [UInt8]

        @usableFromInline
        var offset: Int

        @inlinable
        init(bytes: [UInt8]) {
            self.bytes = bytes
            self.offset = 0
        }
    }

    @inlinable
    public static func startSerialization(
        of value: borrowing [UInt8]
    ) throws(SerializationError) -> SerializationState {
        SerializationState(bytes: copy value)
    }

    @inlinable
    @discardableResult
    public static func serialize(
        state: inout SerializationState,
        into output: inout OutputSpan<UInt8>
    ) -> Bool {
        while state.offset < state.bytes.count && !output.isFull {
            output.append(state.bytes[state.offset])
            state.offset &+= 1
        }
        return state.offset >= state.bytes.count
    }
}
