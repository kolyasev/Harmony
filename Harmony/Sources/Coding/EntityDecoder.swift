
import Foundation

class EntityDecoder
{
    init(storage: ReadEntityDataStorage) {
        self.storage = storage
    }

    func decode(forIdentifier identifier: BaseEntityIdentifier) throws -> AnyEntityHolder?
    {
        if let entity = self.cache.getEntityHolder(forIdentifier: identifier) {
            return entity
        }

        guard let entityData = self.storage.entityData(withIdentifier: identifier) else {
            return nil
        }

        self.decoder.userInfo[EntityDecoder.decodeOptionsKey] = DecodeOptions(
            identifier: identifier,
            entityDecoder: self
        )
        defer {
            self.decoder.userInfo[EntityDecoder.decodeOptionsKey] = nil
        }

        let box = try self.decoder.decode(EntityDecodingBox.self, from: entityData.data)
        let holder = AnyEntityHolder(entity: box.entity, dependencies: box.dependencies)

        self.cache.addEntityHolder(holder)

        return holder
    }

    struct DecodeOptions
    {
        let identifier: BaseEntityIdentifier
        let entityDecoder: EntityDecoder
    }

    fileprivate static let decodeOptionsKey = CodingUserInfoKey(rawValue: "options")!

    private let storage: ReadEntityDataStorage

    private let decoder = JSONDecoder()

    private let cache = EntityHolderCache()
}

fileprivate class EntityDecodingBox: Decodable
{
    required init(from decoder: Decoder) throws
    {
        guard let options = decoder.userInfo[EntityDecoder.decodeOptionsKey] as? EntityDecoder.DecodeOptions else {
            fatalError("Unexpected decoder.")
        }

        let decoder = RawEntityDecoder(entityDecoder: options.entityDecoder, decoder: decoder)

        self.entity = try options.identifier.type.init(from: decoder)
        self.dependencies = decoder.popDependencies()
    }

    let entity: BaseEntity

    let dependencies: [BaseEntityIdentifier]
}

fileprivate class RawEntityDecoder: Decoder
{
    init(entityDecoder: EntityDecoder, decoder: Decoder) {
        self.entityDecoder = entityDecoder
        self.decoder = decoder
    }

    let entityDecoder: EntityDecoder

    var codingPath: [CodingKey] {
        return self.decoder.codingPath
    }

    var userInfo: [CodingUserInfoKey : Any] {
        return self.decoder.userInfo
    }

    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        return KeyedDecodingContainer(_KeyedDecodingContainer(rawDecoder: self, container: try self.decoder.container(keyedBy: type)))
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        return _UnkeyedDecodingContainer(rawDecoder: self, container: try self.decoder.unkeyedContainer())
    }

    func singleValueContainer() throws -> SingleValueDecodingContainer {
        return _SingleValueDecodingContainer(rawDecoder: self, container: try self.decoder.singleValueContainer())
    }

    func registerDependency(identifiers: [BaseEntityIdentifier]) {
        for identifier in identifiers {
            self.dependencies.insert(identifier)
        }
    }

    func popDependencies() -> [BaseEntityIdentifier] {
        defer { self.dependencies = [] }
        return Array(self.dependencies)
    }

    class _KeyedDecodingContainer<Key: CodingKey>: KeyedDecodingContainerProtocol
    {
        init(rawDecoder: RawEntityDecoder, container: KeyedDecodingContainer<Key>) {
            self.rawDecoder = rawDecoder
            self.container = container
        }

        var codingPath: [CodingKey] { return [] }

        var allKeys: [Key] { return [] }

        func contains(_ key: Key) -> Bool {
            return true
        }

        func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
            if let type = type as? BaseEntity.Type {
                let entity = try decode(type, forKey: key)
                return try cast(entity, to: T.self)
            } else {
                return try self.container.decode(type, forKey: key)
            }
        }

        func decode(_ type: BaseEntity.Type, forKey key: Key) throws -> BaseEntity {
            let stringKey = try self.container.decode(String.self, forKey: key)
            let identifier = BaseEntityIdentifier(type: type, stringKey: stringKey)

            guard let holder = try self.rawDecoder.entityDecoder.decode(forIdentifier: identifier) else {
                throw EntityDecodingError.entityNotFound(identifier)
            }

            self.rawDecoder.registerDependency(identifiers: [identifier])
            self.rawDecoder.registerDependency(identifiers: holder.dependencies)

            return holder.entity
        }

        private func cast<T>(_ value: Any, to type: T.Type) throws -> T {
            guard let result = value as? T else {
                throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: value)
            }

            return result
        }

        func decodeNil(forKey key: Key) throws -> Bool {
            return true
        }

        func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
            return KeyedDecodingContainer(_KeyedDecodingContainer<NestedKey>(rawDecoder: self.rawDecoder, container: try self.container.nestedContainer(keyedBy: type, forKey: key)))
        }

        func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
            return _UnkeyedDecodingContainer(rawDecoder: self.rawDecoder, container: try self.container.nestedUnkeyedContainer(forKey: key))
        }

        func superDecoder() throws -> Decoder {
            return try self.container.superDecoder()
        }

        func superDecoder(forKey key: Key) throws -> Decoder {
            return try self.container.superDecoder(forKey: key)
        }

        private let rawDecoder: RawEntityDecoder

        private let container: KeyedDecodingContainer<Key>
    }

    class _UnkeyedDecodingContainer: UnkeyedDecodingContainer
    {
        init(rawDecoder: RawEntityDecoder, container: UnkeyedDecodingContainer) {
            self.rawDecoder = rawDecoder
            self.container = container
        }

        var codingPath: [CodingKey] {
            return self.container.codingPath
        }

        var count: Int? {
            return self.container.count
        }

        var isAtEnd: Bool {
            return self.container.isAtEnd
        }

        var currentIndex: Int {
            return self.container.currentIndex
        }

        func decodeNil() throws -> Bool {
            return try self.container.decodeNil()
        }

        func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
            if let type = type as? BaseEntity.Type {
                let entity = try decode(type)
                return try cast(entity, to: T.self)
            } else {
                return try self.container.decode(type)
            }
        }

        func decode(_ type: BaseEntity.Type) throws -> BaseEntity {
            let stringKey = try self.container.decode(String.self)
            let identifier = BaseEntityIdentifier(type: type, stringKey: stringKey)

            guard let holder = try self.rawDecoder.entityDecoder.decode(forIdentifier: identifier) else {
                throw EntityDecodingError.entityNotFound(identifier)
            }

            self.rawDecoder.registerDependency(identifiers: [identifier])
            self.rawDecoder.registerDependency(identifiers: holder.dependencies)

            return holder.entity
        }

        private func cast<T>(_ value: Any, to type: T.Type) throws -> T {
            guard let result = value as? T else {
                throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: value)
            }

            return result
        }

        func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
            return KeyedDecodingContainer(_KeyedDecodingContainer(rawDecoder: self.rawDecoder, container: try self.container.nestedContainer(keyedBy: type)))
        }

        func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
            return _UnkeyedDecodingContainer(rawDecoder: self.rawDecoder, container: try self.container.nestedUnkeyedContainer())
        }

        func superDecoder() throws -> Decoder {
            return try self.container.superDecoder()
        }

        private let rawDecoder: RawEntityDecoder

        private var container: UnkeyedDecodingContainer
    }

    class _SingleValueDecodingContainer: SingleValueDecodingContainer
    {
        init(rawDecoder: RawEntityDecoder, container: SingleValueDecodingContainer) {
            self.rawDecoder = rawDecoder
            self.container = container
        }

        var codingPath: [CodingKey] {
            return self.container.codingPath
        }

        func decodeNil() -> Bool {
            return self.container.decodeNil()
        }

        func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
            if let type = type as? BaseEntity.Type {
                let entity = try decode(type)
                return try cast(entity, to: T.self)
            } else {
                return try self.container.decode(type)
            }
        }

        func decode(_ type: BaseEntity.Type) throws -> BaseEntity {
            let stringKey = try self.container.decode(String.self)
            let identifier = BaseEntityIdentifier(type: type, stringKey: stringKey)

            guard let holder = try self.rawDecoder.entityDecoder.decode(forIdentifier: identifier) else {
                throw EntityDecodingError.entityNotFound(identifier)
            }

            self.rawDecoder.registerDependency(identifiers: [identifier])
            self.rawDecoder.registerDependency(identifiers: holder.dependencies)
            
            return holder.entity
        }

        private func cast<T>(_ value: Any, to type: T.Type) throws -> T {
            guard let result = value as? T else {
                throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: value)
            }

            return result
        }

        private let rawDecoder: RawEntityDecoder

        private let container: SingleValueDecodingContainer
    }

    private var dependencies: Set<BaseEntityIdentifier> = []

    private let decoder: Decoder
}

enum EntityDecodingError: Error
{
    case entityNotFound(BaseEntityIdentifier)
}

//===----------------------------------------------------------------------===//
// Error Utilities
//===----------------------------------------------------------------------===//
fileprivate extension DecodingError {
    /// Returns a `.typeMismatch` error describing the expected type.
    ///
    /// - parameter path: The path of `CodingKey`s taken to decode a value of this type.
    /// - parameter expectation: The type expected to be encountered.
    /// - parameter reality: The value that was encountered instead of the expected type.
    /// - returns: A `DecodingError` with the appropriate path and debug description.
    fileprivate static func _typeMismatch(at path: [CodingKey], expectation: Any.Type, reality: Any) -> DecodingError {
        let description = "Expected to decode \(expectation) but found \(_typeDescription(of: reality)) instead."
        return .typeMismatch(expectation, Context(codingPath: path, debugDescription: description))
    }

    /// Returns a description of the type of `value` appropriate for an error message.
    ///
    /// - parameter value: The value whose type to describe.
    /// - returns: A string describing `value`.
    /// - precondition: `value` is one of the types below.
    fileprivate static func _typeDescription(of value: Any) -> String {
        if value is NSNull {
            return "a null value"
        } else if value is NSNumber /* FIXME: If swift-corelibs-foundation isn't updated to use NSNumber, this check will be necessary: || value is Int || value is Double */ {
            return "a number"
        } else if value is String {
            return "a string/data"
        } else if value is [Any] {
            return "an array"
        } else if value is [String : Any] {
            return "a dictionary"
        } else {
            return "\(type(of: value))"
        }
    }
}

