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
public import BinaryParsing
public import BasicContainers
public import ContainersPreview

/// An error thrown when the upstream byte stream ends with remaining
/// bytes that cannot form a complete parsed value.
public struct ParsingAsyncReaderTruncatedStreamError: Error {}

/// Transforms a byte-oriented ``AsyncReader`` into a typed ``AsyncReader``
/// by parsing incoming bytes into values conforming to ``ExpressibleByParsing``.
///
/// `ParsingAsyncReader` reads bytes from an upstream `AsyncReader<UInt8>`,
/// accumulates them in an internal buffer, and attempts to parse values
/// using ``ParserSpan``. When a value cannot be parsed due to insufficient
/// data, the reader fetches more bytes from upstream and retries.
///
/// Conforms to ``AsyncReader`` so it composes naturally in a protocol stack:
/// ```
/// AsyncReader<UInt8> → ParsingAsyncReader → AsyncReader<TLSRecord>
/// ```
@available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
public struct ParsingAsyncReader<
    Upstream: AsyncReader & ~Copyable & ~Escapable,
    Value: ExpressibleByParsing & Sendable
>: ~Copyable, ~Escapable, AsyncReader
where Upstream.ReadElement == UInt8, Upstream.FinalElement == Void {
    public typealias ReadElement = Value
    public typealias ReadFailure = any Error
    public typealias Buffer = UniqueArray<Value>
    public typealias FinalElement = Void

    private var upstream: Upstream
    private var byteBuffer: UniqueArray<UInt8>
    private var valueBuffer: UniqueArray<Value>
    private var upstreamFinished: Bool

    /// Creates a parsing reader that transforms bytes from the upstream
    /// byte reader into parsed values.
    ///
    /// - Parameter upstream: The byte-oriented reader to read from.
    @_lifetime(copy upstream)
    public init(upstream: consuming Upstream) {
        self.upstream = upstream
        self.byteBuffer = UniqueArray()
        self.valueBuffer = UniqueArray()
        self.upstreamFinished = false
    }

    /// Reads parsed values from the upstream byte stream and passes them
    /// to the body closure via an `inout UniqueArray<Value>`.
    ///
    /// Accumulates bytes from upstream until at least one value can be
    /// parsed. Passes all parsed values as a buffer to `body`. A non-nil
    /// `finalElement` signals end of stream.
    ///
    /// - Parameter body: A closure that processes the parsed values.
    /// - Returns: The value returned by the body closure.
    /// - Throws: ``ParsingAsyncReaderTruncatedStreamError`` if the stream
    ///   ends with leftover bytes that cannot form a complete value.
    public mutating func read<Return: ~Copyable, Failure: Error>(
        body: (inout UniqueArray<Value>, consuming Void?) async throws(Failure) -> Return
    ) async throws(EitherError<any Error, Failure>) -> Return {
        valueBuffer.removeAll()

        while valueBuffer.isEmpty {
            if !byteBuffer.isEmpty {
                parseAvailableValues()
            }

            if !valueBuffer.isEmpty { break }

            if upstreamFinished {
                if !byteBuffer.isEmpty {
                    throw .first(ParsingAsyncReaderTruncatedStreamError())
                }
                do {
                    return try await body(&valueBuffer, ())
                } catch {
                    throw .second(error)
                }
            }

            do {
                try await readMoreBytes()
            } catch {
                throw .first(error)
            }
        }

        do {
            return try await body(&valueBuffer, nil)
        } catch {
            throw .second(error)
        }
    }
}

@available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
extension ParsingAsyncReader where Upstream: ~Copyable & ~Escapable {
    /// Parses as many complete values as possible from the buffered
    /// bytes. Consumes parsed bytes from the front of the byte buffer.
    /// Stops on insufficient data or a parse error.
    private mutating func parseAvailableValues() {
        while !byteBuffer.isEmpty {
            let result = parseNextValue()

            switch result {
            case .parsed(let value, let consumed):
                valueBuffer.append(value)
                byteBuffer.consume(0..<consumed, consumingWith: { _ in })
            case .insufficientData, .error:
                return
            }
        }
    }

    /// Attempts to parse a single value from the current byte buffer
    /// contents without consuming any bytes.
    private mutating func parseNextValue() -> ParseAttemptResult {
        let rawSpan = byteBuffer.span.bytes
        var parserSpan = ParserSpan(rawSpan)
        let startPosition = parserSpan.startPosition
        do {
            let value = try Value(parsing: &parserSpan)
            let consumed = parserSpan.startPosition - startPosition
            return .parsed(value, consumed: consumed)
        } catch let error as ParsingError
            where error.status == .insufficientData
        {
            return .insufficientData
        } catch {
            return .error(error)
        }
    }

    /// Reads the next chunk of bytes from the upstream reader into the
    /// internal byte buffer. Sets `upstreamFinished` on EOF.
    private mutating func readMoreBytes() async throws {
        try await upstream.read { (buffer, finalElement) in
            if finalElement != nil {
                self.upstreamFinished = true
                return
            }
            var index = buffer.startIndex
            while index < buffer.endIndex {
                let span = buffer.nextSpan(after: &index)
                self.byteBuffer.reserveCapacity(self.byteBuffer.count + span.count)
                for i in 0..<span.count {
                    self.byteBuffer.append(span[i])
                }
            }
        }
    }

    private enum ParseAttemptResult {
        case parsed(Value, consumed: Int)
        case insufficientData
        case error(any Error)
    }
}
#endif
