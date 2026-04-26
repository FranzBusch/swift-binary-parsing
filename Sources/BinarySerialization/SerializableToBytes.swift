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

/// A type that can be serialized into a sequence of bytes.
///
/// Types conforming to `SerializableToBytes` provide an externalized
/// state machine for writing their byte representation into one or more
/// `OutputSpan<UInt8>` buffers.
///
/// Serialization has two phases:
///
/// 1. Call ``startSerialization(of:)`` to validate the value and create
///    a state that tracks serialization progress.
/// 2. Call ``serialize(state:into:)`` repeatedly with output spans
///    until it returns `true`.
///
/// This design supports arbitrarily small output buffers, including
/// single-byte buffers, by externalizing all progress into the state.
///
/// ```swift
/// var state = try UInt32.startSerialization(of: 0x12345678)
/// while !UInt32.serialize(state: &state, into: &outputSpan) {
///     // Flush outputSpan downstream, get a fresh one
/// }
/// ```
public protocol SerializableToBytes {
    /// Tracks serialization progress between calls to
    /// ``serialize(state:into:)``.
    associatedtype SerializationState

    /// Validates the value and prepares a state for incremental
    /// serialization.
    ///
    /// - Parameter value: The value to serialize.
    /// - Returns: A state holding any precomputed byte representation.
    /// - Throws: ``SerializationError`` if the value cannot be
    ///   represented in the wire format.
    static func startSerialization(
        of value: borrowing Self
    ) throws(SerializationError) -> SerializationState

    /// Writes bytes from the serialization state into the output span.
    ///
    /// Appends as many bytes as the output span's free capacity allows.
    /// Call repeatedly until it returns `true`.
    ///
    /// - Parameters:
    ///   - state: The serialization state to resume from.
    ///   - output: The output span to append bytes into.
    /// - Returns: `true` when all bytes have been written.
    @discardableResult
    static func serialize(
        state: inout SerializationState,
        into output: inout OutputSpan<UInt8>
    ) -> Bool
}
