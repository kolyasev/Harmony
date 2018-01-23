
import Foundation

class EntityEncoder
{
    init(storage: WriteEntityDataStorage) {
        self.storage = storage
    }

    func encode(_ entity: BaseEntity) throws
    {
        let box = EntityEncodingBox(entityEncoder: self, entity: entity)
        let data = try encoder.encode(box)

        let entityData = EntityData(identifier: entity.identifier, data: data)
        self.storage.insert(entityData: entityData)
    }

    private let storage: WriteEntityDataStorage

    private let encoder = JSONEncoder()
}

fileprivate class EntityEncodingBox: Encodable
{
    init(entityEncoder: EntityEncoder, entity: BaseEntity)
    {
        self.entityEncoder = entityEncoder
        self.entity = entity
    }

    let entity: BaseEntity

    func encode(to encoder: Encoder) throws
    {
        let encoder = RawEntityEncoder(entityEncoder: self.entityEncoder, encoder: encoder)
        try self.entity.encode(to: encoder)
    }

    private let entityEncoder: EntityEncoder
}

fileprivate class RawEntityEncoder: Encoder
{
    init(entityEncoder: EntityEncoder, encoder: Encoder) {
        self.entityEncoder = entityEncoder
        self.encoder = encoder
    }

    var codingPath: [CodingKey] {
        return self.encoder.codingPath
    }

    var userInfo: [CodingUserInfoKey : Any] {
        return self.encoder.userInfo
    }

    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        return KeyedEncodingContainer(_KeyedEncodingContainer(entityEncoder: self.entityEncoder, container: self.encoder.container(keyedBy: type)))
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        return self.encoder.unkeyedContainer()
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        return _SingleValueEncodingContainer(entityEncoder: self.entityEncoder, container: self.encoder.singleValueContainer())
    }

    class _KeyedEncodingContainer<Key: CodingKey>: KeyedEncodingContainerProtocol
    {
        init(entityEncoder: EntityEncoder, container: KeyedEncodingContainer<Key>) {
            self.entityEncoder = entityEncoder
            self.container = container
        }

        var codingPath: [CodingKey] {
            return self.container.codingPath
        }

        func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
            if let entity = value as? BaseEntity {
                try encode(entity, forKey: key)
            } else {
                try self.container.encode(value, forKey: key)
            }
        }

        func encode(_ entity: BaseEntity, forKey key: Key) throws {
            // Encode entity identifier
            try self.encode(entity.identifier.stringKey, forKey: key)

            // Encode child entity to storage
            try entity.encode(to: self.entityEncoder)
        }

        func encodeNil(forKey key: Key) throws {
            try self.container.encodeNil(forKey: key)
        }

        func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
            return KeyedEncodingContainer(_KeyedEncodingContainer<NestedKey>(entityEncoder: self.entityEncoder, container: self.container.nestedContainer(keyedBy: keyType, forKey: key)))
        }

        func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
            return _UnkeyedEncodingContainer(entityEncoder: self.entityEncoder, container: self.container.nestedUnkeyedContainer(forKey: key))
        }

        func superEncoder() -> Encoder {
            return self.container.superEncoder()
        }

        func superEncoder(forKey key: Key) -> Encoder {
            return self.container.superEncoder(forKey: key)
        }

        private let entityEncoder: EntityEncoder

        private var container: KeyedEncodingContainer<Key>
    }

    class _UnkeyedEncodingContainer: UnkeyedEncodingContainer
    {
        init(entityEncoder: EntityEncoder, container: UnkeyedEncodingContainer) {
            self.entityEncoder = entityEncoder
            self.container = container
        }

        var codingPath: [CodingKey] {
            return self.container.codingPath
        }

        var count: Int {
            return self.container.count
        }

        func encodeNil() throws {
            try self.container.encodeNil()
        }

        func encode<T>(_ value: T) throws where T : Encodable {
            if let entity = value as? BaseEntity {
                try encode(entity)
            } else {
                try self.container.encode(value)
            }
        }

        func encode(_ entity: BaseEntity) throws {
            // Encode entity identifier
            try self.encode(entity.identifier.stringKey)

            // Encode child entity to storage
            try entity.encode(to: self.entityEncoder)
        }

        func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
            return KeyedEncodingContainer(_KeyedEncodingContainer(entityEncoder: self.entityEncoder, container: self.container.nestedContainer(keyedBy: keyType)))
        }

        func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
            return _UnkeyedEncodingContainer(entityEncoder: self.entityEncoder, container: self.container.nestedUnkeyedContainer())
        }

        func superEncoder() -> Encoder {
            return self.container.superEncoder()
        }

        private let entityEncoder: EntityEncoder

        private var container: UnkeyedEncodingContainer
    }

    class _SingleValueEncodingContainer: SingleValueEncodingContainer
    {
        init(entityEncoder: EntityEncoder, container: SingleValueEncodingContainer) {
            self.entityEncoder = entityEncoder
            self.container = container
        }

        var codingPath: [CodingKey] {
            return self.container.codingPath
        }

        func encodeNil() throws {
            try self.container.encodeNil()
        }

        func encode<T>(_ value: T) throws where T : Encodable {
            if let entity = value as? BaseEntity {
                try encode(entity)
            } else {
                try self.container.encode(value)
            }
        }

        func encode(_ entity: BaseEntity) throws {
            // Encode entity identifier
            try self.container.encode(entity.identifier.stringKey)

            // Encode child entity to storage
            try entity.encode(to: self.entityEncoder)
        }

        private let entityEncoder: EntityEncoder

        private var container: SingleValueEncodingContainer
    }

    private let entityEncoder: EntityEncoder

    private let encoder: Encoder
}

fileprivate extension BaseEntity
{
    fileprivate func encode(to encoder: EntityEncoder) throws
    {
        try encoder.encode(self)
    }
}
