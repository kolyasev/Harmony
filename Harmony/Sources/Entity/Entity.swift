
public protocol Property: Equatable { }

extension String: Property { }
extension Int: Property { }

struct AnyBaseEntity: BaseEntity
{
    
    init(_ entity: BaseEntity) {
        self.entity = entity
    }

    init(from decoder: Decoder) throws {
        fatalError()
    }

    func encode(to encoder: Encoder) throws {
        fatalError()
    }

    var identifier: BaseEntityIdentifier {
        return self.entity.identifier
    }

    private let entity: BaseEntity
}

public protocol BaseEntity: Codable
{
    var identifier: BaseEntityIdentifier { get }
}

public protocol Entity: BaseEntity, Property
{
    var key: Key { get }

    associatedtype Key: EntityKey
}

extension Entity
{
    public var identifier: BaseEntityIdentifier {
        return BaseEntityIdentifier(type: type(of: self), stringKey: self.key.description)
    }
}

public protocol EntityKey: LosslessStringConvertible, Hashable { }

extension String: EntityKey { }
