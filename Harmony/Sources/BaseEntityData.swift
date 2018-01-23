
struct RawEntity
{
    init(identifier: BaseEntityIdentifier)
    {
        self.identifier = identifier
    }

    var identifier: BaseEntityIdentifier

    static func make(from entity: BaseEntity) -> [RawEntity]
    {
        var result: [RawEntity] = []

        let map = EntityMaps().map(type(of: entity))
        var data = RawEntity(identifier: entity.identifier)

        for property in map.properties
        {
            let value = entity[keyPath: property.path]
            data.set(value: value, forKey: property.name)
        }

        for reference in map.references
        {
            if let value = entity[keyPath: reference.path] as? BaseEntity
            {
                let entityReference = BaseEntityReference(identifier: value.identifier)
                data.set(value: entityReference, forKey: reference.name)

                result.append(contentsOf: make(from: value))
            }
            else {
                data.set(value: nil, forKey: reference.name)
            }
        }

        result.append(data)

        return result
    }

    mutating func set(value: Any?, forKey key: String)
    {
        self.data[key] = value
    }

    func value(forKey key: String) -> Any?
    {
        return nil
    }

    private var data: [String: Any] = [:]

}

struct BaseEntityReference
{
    let identifier: BaseEntityIdentifier
}
