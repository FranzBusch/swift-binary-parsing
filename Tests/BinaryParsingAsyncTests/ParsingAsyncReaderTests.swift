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
import _AsyncStreaming
import BinaryParsing
import BinaryParsingAsync
import BasicContainers
import ContainersPreview
import Testing

// MARK: - Test parsable types

struct TestUInt32Value: ExpressibleByParsing, Sendable, Equatable {
    let value: UInt32

    init(_ value: UInt32) { self.value = value }

    init(parsing input: inout ParserSpan) throws(ParsingError) {
        self.value = try UInt32(parsingBigEndian: &input)
    }
}

struct LengthPrefixedMessage: ExpressibleByParsing, Sendable, Equatable {
    let payload: [UInt8]

    init(_ payload: [UInt8]) { self.payload = payload }

    init(parsing input: inout ParserSpan) throws(ParsingError) {
        let length = try UInt16(parsingBigEndian: &input)
        var payloadSpan = try input.sliceSpan(byteCount: Int(length))
        self.payload = try Array(parsing: &payloadSpan, byteCount: Int(length))
    }
}

// MARK: - Mock AsyncReader

struct MockByteReader: AsyncReader, ~Copyable {
    typealias ReadElement = UInt8
    typealias ReadFailure = any Error

    private var chunks: [[UInt8]]
    private var nextChunkIndex: Int

    init(chunks: [[UInt8]]) {
        self.chunks = chunks
        self.nextChunkIndex = 0
    }

    mutating func read<Return, Failure: Error>(
        maximumCount: Int,
        body: (consuming InputSpan<UInt8>) async throws(Failure) -> Return
    ) async throws(EitherError<any Error, Failure>) -> Return {
        if nextChunkIndex >= chunks.count {
            do {
                return try await body(InputSpan<UInt8>())
            } catch {
                throw .second(error)
            }
        }

        let chunk = chunks[nextChunkIndex]
        nextChunkIndex += 1

        var buffer = UniqueArray<UInt8>()
        for byte in chunk {
            buffer.append(byte)
        }
        let inputSpan = buffer._consumeAll()
        do {
            return try await body(consume inputSpan)
        } catch {
            throw .second(error)
        }
    }
}

// MARK: - Tests

@Suite
struct ParsingAsyncReaderTests {
    @Test
    @available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
    func parseSingleValueFromSingleChunk() async throws {
        let upstream = MockByteReader(chunks: [
            [0x00, 0x00, 0x00, 0x2A],
        ])
        var reader = ParsingAsyncReader<MockByteReader, TestUInt32Value>(
            upstream: upstream
        )
        let result = try await reader.read { span in
            let count = span.count
            #expect(count == 1)
            return span[0]
        }
        #expect(result == TestUInt32Value(42))
    }

    @Test
    @available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
    func parseValueSplitAcrossTwoChunks() async throws {
        let upstream = MockByteReader(chunks: [
            [0x00, 0x00],
            [0x00, 0x01],
        ])
        var reader = ParsingAsyncReader<MockByteReader, TestUInt32Value>(
            upstream: upstream
        )
        let result = try await reader.read { span in
            let count = span.count
            #expect(count == 1)
            return span[0]
        }
        #expect(result == TestUInt32Value(1))
    }

    @Test
    @available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
    func parseValueSplitByteByByte() async throws {
        let upstream = MockByteReader(chunks: [
            [0x00], [0x00], [0x01], [0x00],
        ])
        var reader = ParsingAsyncReader<MockByteReader, TestUInt32Value>(
            upstream: upstream
        )
        let result = try await reader.read { span in
            return span[0]
        }
        #expect(result == TestUInt32Value(256))
    }

    @Test
    @available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
    func parseMultipleValuesFromOneChunk() async throws {
        let upstream = MockByteReader(chunks: [
            [0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x02],
        ])
        var reader = ParsingAsyncReader<MockByteReader, TestUInt32Value>(
            upstream: upstream
        )

        let (first, second) = try await reader.read { span in
            let count = span.count
            #expect(count == 2)
            return (span[0], span[1])
        }
        #expect(first == TestUInt32Value(1))
        #expect(second == TestUInt32Value(2))
    }

    @Test
    @available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
    func parseEOFOnEmptyStream() async throws {
        let upstream = MockByteReader(chunks: [])
        var reader = ParsingAsyncReader<MockByteReader, TestUInt32Value>(
            upstream: upstream
        )

        let result = try await reader.read { span in
            let isEmpty = span.isEmpty
            #expect(isEmpty)
            return Optional<TestUInt32Value>.none
        }
        #expect(result == nil)
    }

    @Test
    @available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
    func parseLengthPrefixedMessage() async throws {
        let upstream = MockByteReader(chunks: [
            [0x00, 0x03, 0x41, 0x42, 0x43],
        ])
        var reader = ParsingAsyncReader<MockByteReader, LengthPrefixedMessage>(
            upstream: upstream
        )

        let result = try await reader.read { span in span[0] }
        #expect(result == LengthPrefixedMessage([0x41, 0x42, 0x43]))
    }

    @Test
    @available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
    func parseLengthPrefixedMessageSplitAtEveryByte() async throws {
        let fullMessage: [UInt8] = [0x00, 0x03, 0x41, 0x42, 0x43]
        for splitPoint in 1..<fullMessage.count {
            let chunk1 = Array(fullMessage[0..<splitPoint])
            let chunk2 = Array(fullMessage[splitPoint...])
            let upstream = MockByteReader(chunks: [chunk1, chunk2])
            var reader = ParsingAsyncReader<
                MockByteReader, LengthPrefixedMessage
            >(upstream: upstream)

            let result = try await reader.read { span in span[0] }
            #expect(
                result == LengthPrefixedMessage([0x41, 0x42, 0x43]),
                "Failed at split point \(splitPoint)"
            )
        }
    }

    @Test
    @available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
    func parseMultipleMessagesAcrossChunks() async throws {
        let upstream = MockByteReader(chunks: [
            [0x00, 0x02, 0xAA],
            [0xBB, 0x00, 0x01, 0xCC],
        ])
        var reader = ParsingAsyncReader<
            MockByteReader, LengthPrefixedMessage
        >(upstream: upstream)

        let (first, second) = try await reader.read { span in
            let count = span.count
            #expect(count == 2)
            return (span[0], span[1])
        }
        #expect(first == LengthPrefixedMessage([0xAA, 0xBB]))
        #expect(second == LengthPrefixedMessage([0xCC]))
    }

    @Test
    @available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
    func truncatedStreamThrowsError() async throws {
        let upstream = MockByteReader(chunks: [
            [0x00, 0x01],
        ])
        var reader = ParsingAsyncReader<MockByteReader, TestUInt32Value>(
            upstream: upstream
        )

        await #expect {
            _ = try await reader.read { span in span[0] }
        } throws: { error in
            guard let eitherError = error as? EitherError<any Error, Never>,
                  case .first(let inner) = eitherError
            else { return false }
            return inner is ParsingAsyncReaderTruncatedStreamError
        }
    }
}
#endif
