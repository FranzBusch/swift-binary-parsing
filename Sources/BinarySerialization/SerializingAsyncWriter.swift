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
public import AsyncStreaming
import BinaryParsing
public import ContainersPreview
import BasicContainers

/// Transforms a typed value writer into a byte-oriented writer by
/// serializing values conforming to ``SerializableToBytes``.
///
/// Wraps a downstream `AsyncWriter<UInt8>` and exposes a
/// `CallerAsyncWriter<Value>` interface. When values are written,
/// each one is serialized into a local byte buffer and then handed
/// to the downstream writer.
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
where Downstream.WriteElement == UInt8, Downstream.FinalElement == Void {
    public typealias WriteElement = Value
    public typealias WriteFailure = any Error
    public typealias FinalElement = Void

    private var downstream: Downstream

    /// Creates a serializing writer that writes to the given downstream
    /// byte writer.
    ///
    /// - Parameter downstream: The byte-oriented writer to serialize into.
    @_lifetime(copy downstream)
    public init(downstream: consuming Downstream) {
        self.downstream = downstream
    }

    /// Serializes each value in the buffer and writes the resulting bytes
    /// to the downstream writer.
    ///
    /// - Parameter buffer: The values to serialize and write.
    public mutating func write<Buffer: RangeReplaceableContainer<Value> & ~Copyable>(
        buffer: inout Buffer
    ) async throws(any Error) {
        try await drain(buffer: &buffer)
    }

    /// Serializes any remaining values and signals end-of-stream to the
    /// downstream writer.
    public consuming func finish<Buffer: RangeReplaceableContainer<Value> & ~Copyable>(
        buffer: inout Buffer,
        finalElement: consuming Void
    ) async throws(any Error) {
        try await drain(buffer: &buffer)
        try await self.downstream.finish(finalElement: ())
    }

    private mutating func drain<Buffer: RangeReplaceableContainer<Value> & ~Copyable>(
        buffer: inout Buffer
    ) async throws {
        var bytes = UniqueArray<UInt8>()
        var index = buffer.startIndex
        while index < buffer.endIndex {
            let span = buffer.nextSpan(after: &index)
            for i in 0..<span.count {
                var state = try Value.startSerialization(of: span[i])
                var done = false
                while !done {
                    bytes.append(addingCount: 4096) { (output: inout OutputSpan<UInt8>) in
                        done = Value.serialize(state: &state, into: &output)
                    }
                }
            }
        }
        buffer.removeAll()

        if bytes.count > 0 {
            let count = bytes.count
            try await downstream.write { downstreamBuffer in
                for i in 0..<count {
                    downstreamBuffer.append(bytes[i])
                }
            }
        }
    }
}
#endif
