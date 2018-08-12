
struct AnyBaseEntity: BaseEntity
{
// MARK: - Initialization

    init(_ entity: BaseEntity) {
        self.entity = entity
    }

    init(from decoder: Decoder) throws {
        fatalError()
    }

// MARK: - Properties

    var identifier: BaseEntityIdentifier {
        return self.entity.identifier
    }

// MARK: - Functions

    func encode(to encoder: Encoder) throws {
        fatalError()
    }

// MARK: - Private Properties

    private let entity: BaseEntity
}

public protocol BaseEntity: Codable
{
// MARK: - Properties

    var identifier: BaseEntityIdentifier { get }

}

public protocol Entity: BaseEntity, Equatable
{
// MARK: - Associated Types

    associatedtype Key: EntityKey

// MARK: - Properties

    static var keyPath: KeyPath<Self, Key> { get }
}

extension Entity
{
// MARK: - Properties

    var key: Key {
        return self[keyPath: Self.keyPath]
    }
}

extension Entity
{
// MARK: - Properties

    public var identifier: BaseEntityIdentifier {
        return BaseEntityIdentifier(type: type(of: self), stringKey: self.key.description)
    }
}
