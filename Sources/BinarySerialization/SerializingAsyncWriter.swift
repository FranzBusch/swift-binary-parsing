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

#if UnstableAsyncStreaming && compiler(>=6.4)
public import _AsyncStreaming
import BinaryParsing
public import ContainersPreview

/// Transforms a typed value writer into a byte-oriented writer by
/// serializing values conforming to ``SerializableToBytes``.
///
/// Wraps a downstream `AsyncWriter<UInt8>` and exposes a
/// `CallerAsyncWriter<Value>` interface. When values are written,
/// each one is serialized directly into the downstream writer's
/// output span with no intermediate copy.
///
/// Composes naturally in a protocol stack:
/// ```
/// CallerAsyncWriter<TLSRecord> → SerializingAsyncWriter → AsyncWriter<UInt8>
/// ```
@available(macOS 26.2, iOS 26.2, watchOS 26.2, tvOS 26.2, visionOS 26.2, *)
public struct SerializingAsyncWriter<
    Downstream: AsyncWriter & ~Copyable & ~Escapable,
    Value: SerializableToBytes & Sendable
>: ~Copyable, ~Escapable, CallerAsyncWriter
where Downstream.WriteElement == UInt8 {
    public typealias WriteElement = Value
    public typealias WriteFailure = any Error

    private var downstream: Downstream

    /// Creates a serializing writer that writes to the given downstream
    /// byte writer.
    ///
    /// - Parameter downstream: The byte-oriented writer to serialize into.
    @_lifetime(copy downstream)
    public init(downstream: consuming Downstream) {
        self.downstream = downstream
    }

    /// Serializes each value in the span and writes the resulting bytes
    /// to the downstream writer.
    ///
    /// - Parameter span: The values to serialize and write.
    public mutating func write(
        span: borrowing InputSpan<Value>
    ) async throws(any Error) {
        for i in 0..<span.count {
            var state = try Value.startSerialization(of: span[i])
            while true {
                let done = try await downstream.write {
                    (output: inout OutputSpan<UInt8>) in
                    Value.serialize(state: &state, into: &output)
                }
                if done { break }
            }
        }
    }
}
#endif
