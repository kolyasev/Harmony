
class DatabaseState: BaseEntityStorage
{
    convenience init(parentStorage: ReadEntityDataStorage) {
        self.init(parentStorage: parentStorage, parent: nil)
    }

    private init(parentStorage: ReadEntityDataStorage, parent: DatabaseState?)
    {
        self.dataStorageState = EntityDataStorageState(parentStorage: parentStorage)
        self.entityStorageState = DefaultBaseEntityStorage(entityDataStorage: self.dataStorageState)
        self.parent = parent
    }

    let sid = DatabaseSID()

    func entityHolder(withIdentifier identifier: BaseEntityIdentifier) -> AnyEntityHolder? {
        return self.entityStorageState.entityHolder(withIdentifier: identifier)
    }

    func entity(withIdentifier identifier: BaseEntityIdentifier) -> BaseEntity? {
        return entityHolder(withIdentifier: identifier)?.entity
    }

    func enumerate(entityType: BaseEntity.Type, identifiers block: (BaseEntityIdentifier, inout Bool) -> Void) {
        self.entityStorageState.enumerate(entityType: entityType, identifiers: block)
    }

    func enumerate(entityType: BaseEntity.Type, entityHolders block: (AnyEntityHolder, inout Bool) -> Void) {
        self.entityStorageState.enumerate(entityType: entityType, entityHolders: block)
    }

    func enumerate(entityType: BaseEntity.Type, entities block: (BaseEntity, inout Bool) -> Void) {
        enumerate(entityType: entityType, entityHolders: { holder, stop in
            block(holder.entity, &stop)
        })
    }

    func insert(entity: BaseEntity) {
        self.entityStorageState.insert(entity: entity)
    }

    func removeEntity(withIdentifier identifier: BaseEntityIdentifier) {
        self.entityStorageState.removeEntity(withIdentifier: identifier)
    }

    func hasChanges() -> Bool {
        return self.dataStorageState.hasChanges()
    }

    func makeChild() -> DatabaseState {
        return DatabaseState(parentStorage: self.dataStorageState, parent: self)
    }

    func isChild(of parent: DatabaseState) -> Bool {
        return self.parent == parent
    }

    func write(to storage: WriteEntityDataStorage)
    {
        self.dataStorageState.write(to: storage)
        self.parent?.write(to: storage)
    }

    private let parent: DatabaseState?

    private let dataStorageState: EntityDataStorageState

    private let entityStorageState: BaseEntityStorage
}

extension DatabaseState: Equatable
{
    static func ==(lhs: DatabaseState, rhs: DatabaseState) -> Bool {
        return lhs.sid == rhs.sid
    }
}

extension DatabaseState: Hashable
{
    var hashValue: Int {
        return self.sid.hashValue
    }
}

private enum EntityDataChange
{
    case insert(EntityData)
    case remove(BaseEntityIdentifier)

    var entityData: EntityData?
    {
        let result: EntityData?

        switch self
        {
            case .insert(let entityData):
                result = entityData

            case .remove(_):
                result = nil
        }

        return result
    }

    var identifier: BaseEntityIdentifier
    {
        let result: BaseEntityIdentifier

        switch self
        {
            case .insert(let entityData):
                result = entityData.identifier

            case .remove(let identifier):
                result = identifier
        }

        return result
    }
}

private class EntityDataStorageState: EntityDataStorage
{
    init(parentStorage: ReadEntityDataStorage)
    {
        self.parentStorage = parentStorage
        self.changeStorage = EntityDataChangeStorage()
    }

    func entityData(withIdentifier identifier: BaseEntityIdentifier) -> EntityData?
    {
        let entityData: EntityData?

        if let change = self.changeStorage.entityDataChange(forIdentifier: identifier)
        {
            entityData = change.entityData
        }
        else {
            entityData = self.parentStorage.entityData(withIdentifier: identifier)
        }

        return entityData
    }

    func insert(entityData: EntityData) {
        self.changeStorage.insert(entityData: entityData)
    }

    func removeEntityData(withIdentifier identifier: BaseEntityIdentifier) {
        self.changeStorage.removeEntityData(withIdentifier: identifier)
    }

    func enumerate(entityType: BaseEntity.Type, identifiers block: (BaseEntityIdentifier, inout Bool) -> Void) {
        var stop = false
        for case .insert(let entityData) in self.changeStorage.allChanges() {
            block(entityData.identifier, &stop)
            if stop { return }
        }

        self.parentStorage.enumerate(entityType: entityType, identifiers: { identifier, stop in
            if self.changeStorage.entityDataChange(forIdentifier: identifier) != nil {
                return
            }
            block(identifier, &stop)
        })
    }

    func enumerate(entityType: BaseEntity.Type, entities block: (EntityData, inout Bool) -> Void) {
        var stop = false
        for case .insert(let entityData) in self.changeStorage.allChanges() {
            block(entityData, &stop)
            if stop { return }
        }

        self.parentStorage.enumerate(entityType: entityType, entities: { entityData, stop in
            if self.changeStorage.entityDataChange(forIdentifier: entityData.identifier) != nil {
                return
            }
            block(entityData, &stop)
        })
    }

    func hasChanges() -> Bool {
        return self.changeStorage.hasChanges()
    }

    func write(to storage: WriteEntityDataStorage) {
        self.changeStorage.write(to: storage)
    }

    private let parentStorage: ReadEntityDataStorage

    private let changeStorage: EntityDataChangeStorage
}

private class EntityDataChangeStorage: WriteEntityDataStorage
{
    func entityDataChange(forIdentifier identifier: BaseEntityIdentifier) -> EntityDataChange? {
        return self.changes[identifier]
    }

    func insert(entityData: EntityData) {
        self.changes[entityData.identifier] = .insert(entityData)
    }

    func removeEntityData(withIdentifier identifier: BaseEntityIdentifier) {
        self.changes[identifier] = .remove(identifier)
    }

    func hasChanges() -> Bool {
        return !self.changes.isEmpty
    }

    func allChanges() -> [EntityDataChange] {
        return Array(self.changes.values)
    }

    func write(to storage: WriteEntityDataStorage)
    {
        for change in self.changes.values
        {
            switch change
            {
                case .insert(let entityData):
                    storage.insert(entityData: entityData)

                case .remove(let identifier):
                    storage.removeEntityData(withIdentifier: identifier)
            }
        }
    }

    private var changes: [BaseEntityIdentifier: EntityDataChange] = [:]
}
