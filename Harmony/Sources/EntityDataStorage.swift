
protocol ReadEntityDataStorage
{
    func entityData(withIdentifier identifier: BaseEntityIdentifier) -> EntityData?

    func enumerate(entityType: BaseEntity.Type, identifiers block: (BaseEntityIdentifier, inout Bool) -> Void)

    func enumerate(entityType: BaseEntity.Type, entities block: (EntityData, inout Bool) -> Void)
}

protocol WriteEntityDataStorage
{
    func insert(entityData: EntityData)

    func removeEntityData(withIdentifier identifier: BaseEntityIdentifier)
}

typealias EntityDataStorage = ReadEntityDataStorage & WriteEntityDataStorage

class InMemoryEntityDataStorage: EntityDataStorage
{
    func entityData(withIdentifier identifier: BaseEntityIdentifier) -> EntityData? {
        return self.entities[identifier]
    }

    func insert(entityData: EntityData) {
        self.entities[entityData.identifier] = entityData
    }

    func removeEntityData(withIdentifier identifier: BaseEntityIdentifier) {
        self.entities.removeValue(forKey: identifier)
    }

    func enumerate(entityType: BaseEntity.Type, identifiers block: (BaseEntityIdentifier, inout Bool) -> Void) {
        var stop = false
        for identifier in self.entities.keys {
            if identifier.type == entityType {
                block(identifier, &stop)
                if stop { return }
            }
        }
    }

    func enumerate(entityType: BaseEntity.Type, entities block: (EntityData, inout Bool) -> Void) {
        var stop = false
        for entityData in self.entities.values {
            if entityData.identifier.type == entityType {
                block(entityData, &stop)
                if stop { return }
            }
        }
    }

    private var entities: [BaseEntityIdentifier: EntityData] = [:]
}
