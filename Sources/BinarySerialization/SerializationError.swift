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

/// An error produced when validating a value for serialization.
public struct SerializationError: Error, Sendable {
    /// The different kinds of serialization errors.
    public struct Status: Equatable, Sendable {
        enum RawValue {
            case valueTooLarge
            case invalidValue
        }

        var rawValue: RawValue

        /// The value exceeds the maximum size representable in the
        /// wire format.
        public static var valueTooLarge: Self {
            .init(rawValue: .valueTooLarge)
        }

        /// The value is invalid for serialization.
        public static var invalidValue: Self {
            .init(rawValue: .invalidValue)
        }
    }

    /// The kind of serialization error.
    public var status: Status

    public init(status: Status) {
        self.status = status
    }
}

#if !$Embedded
extension SerializationError: CustomStringConvertible {
    public var description: String {
        switch status.rawValue {
        case .valueTooLarge:
            "value too large for wire format"
        case .invalidValue:
            "invalid value for serialization"
        }
    }
}
#endif
