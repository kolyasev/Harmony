
protocol ReadBaseEntityStorage
{
    func entityHolder(withIdentifier identifier: BaseEntityIdentifier) -> AnyEntityHolder?

    func enumerate(entityType: BaseEntity.Type, identifiers block: (BaseEntityIdentifier, inout Bool) -> Void)

    func enumerate(entityType: BaseEntity.Type, entityHolders block: (AnyEntityHolder, inout Bool) -> Void)
}

protocol WriteBaseEntityStorage
{
    func insert(entity: BaseEntity)

    func removeEntity(withIdentifier identifier: BaseEntityIdentifier)
}

typealias BaseEntityStorage = ReadBaseEntityStorage & WriteBaseEntityStorage

class InMemoryBaseEntityStorage: DefaultBaseEntityStorage
{
    init() {
        super.init(entityDataStorage: InMemoryEntityDataStorage())
    }
}

class DefaultBaseEntityStorage: BaseEntityStorage
{
    init(entityDataStorage: EntityDataStorage) {
        self.entityDataStorage = entityDataStorage
    }

    func entityHolder(withIdentifier identifier: BaseEntityIdentifier) -> AnyEntityHolder?
    {
        let entityHolder: AnyEntityHolder?

        let decoder = EntityDecoder(storage: self.entityDataStorage)
        do {
            entityHolder = try decoder.decode(forIdentifier: identifier)
        }
        catch {
            // TODO: Log error
            entityHolder = nil
            fatalError()
        }

        return entityHolder
    }

    func enumerate(entityType: BaseEntity.Type, identifiers block: (BaseEntityIdentifier, inout Bool) -> Void) {
        self.entityDataStorage.enumerate(entityType: entityType, identifiers: block)
    }

    func enumerate(entityType: BaseEntity.Type, entityHolders block: (AnyEntityHolder, inout Bool) -> Void) {
        enumerate(entityType: entityType, identifiers: { identifier, stop in
            if let entity = self.entityHolder(withIdentifier: identifier) {
                block(entity, &stop)
            }
        })
    }

    func insert(entity: BaseEntity)
    {
        let encoder = EntityEncoder(storage: self.entityDataStorage)
        do {
            try encoder.encode(entity)
        }
        catch {
            // TODO: Log error
            fatalError()
        }
    }

    func removeEntity(withIdentifier identifier: BaseEntityIdentifier)
    {
        self.entityDataStorage.removeEntityData(withIdentifier: identifier)
    }

    private let entityDataStorage: EntityDataStorage
}
