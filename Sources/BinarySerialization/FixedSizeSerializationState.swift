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

/// Tracks serialization progress for types with a compile-time-known
/// byte count.
///
/// Stores the precomputed byte representation in an `InlineArray` and
/// tracks how many bytes have been written. Handles arbitrarily small
/// output spans by writing one byte at a time.
///
/// Use this type as the ``SerializableToBytes/SerializationState``
/// for fixed-size types like integers.
@available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
public struct FixedSizeSerializationState<let byteCount: Int>: Sendable {
    @usableFromInline
    var bytes: InlineArray<byteCount, UInt8>

    @usableFromInline
    var offset: Int

    /// Creates a state from a precomputed byte representation.
    ///
    /// - Parameter bytes: The bytes to write, in order.
    @inlinable
    public init(bytes: InlineArray<byteCount, UInt8>) {
        self.bytes = bytes
        self.offset = 0
    }

    /// Appends remaining bytes into the output span.
    ///
    /// - Parameter output: The output span to write into.
    /// - Returns: `true` when all bytes have been written.
    @inlinable
    @discardableResult
    public mutating func serialize(
        into output: inout OutputSpan<UInt8>
    ) -> Bool {
        while offset < byteCount && !output.isFull {
            output.append(bytes[offset])
            offset &+= 1
        }
        return offset >= byteCount
    }
}
