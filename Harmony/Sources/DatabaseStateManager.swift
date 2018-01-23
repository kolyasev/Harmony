
import Foundation

protocol EntityUpdatesListener: class
{
    func handleEntityUpdates(_ updates: [EntityUpdate], in state: DatabaseState)
}

class DatabaseStateManager
{
    init(entityDataStorage: EntityDataStorage)
    {
        self.entityDataStorage = entityDataStorage
        self.currentState = DatabaseState(parentStorage: entityDataStorage)
    }

    let entityDataStorage: EntityDataStorage

    weak var updatesListener: EntityUpdatesListener?

    func read<R>(_ block: (DatabaseState) -> R) -> R
    {
        return updateState(block)
    }

    func write<R>(_ block: (DatabaseState) -> R) -> R
    {
        return self.writeLock.withCriticalScope {
            return updateState(block)
        }
    }

    private func updateState<R>(_ block: (DatabaseState) -> R) -> R
    {
        let state = makeState()
        let result = block(state)
        commit(state: state)
        return result
    }

    private func makeState() -> DatabaseState
    {
        return self.stateLock.withCriticalScope {
            let state = self.currentState.makeChild()
            self.states.insert(state)
            return state
        }
    }

    private func commit(state: DatabaseState)
    {
        return self.stateLock.withCriticalScope {
            guard let state = self.states.remove(state) else {
                fatalError("Unexpected database state.")
            }

            if state.hasChanges() {
                setCurrentState(state)
            }

            saveCurrentStateIfPossible()
        }
    }

    private func setCurrentState(_ state: DatabaseState)
    {
        guard state.isChild(of: self.currentState) else {
            fatalError("Trying to perform multiple write operations at same time.")
        }

        self.currentState = state

        readAsync(withState: state) { readState in
            self.handleEntityUpdates(for: readState)
        }
    }

    private func readAsync(withState state: DatabaseState, block: @escaping (DatabaseState) -> Void)
    {
        let readState = state.makeChild()
        self.states.insert(readState)
        DispatchQueue.global().async {
            block(readState)
            self.commit(state: readState)
        }
    }

    private func saveCurrentStateIfPossible()
    {
        guard self.states.isEmpty else { return }

        // There is no other read or write transactions
        // We able to write state to entity storage
        if  self.currentState.hasChanges() {
            self.currentState.write(to: self.entityDataStorage)

            // Create fresh state based of current entity data storage state
            self.currentState = DatabaseState(parentStorage: self.entityDataStorage)
        }
    }

    private func handleEntityUpdates(for state: DatabaseState)
    {
        let updateBuiler = EntityUpdatesBuilder()
        state.write(to: updateBuiler)
        self.updatesListener?.handleEntityUpdates(updateBuiler.getUpdates(), in: state)
    }

    private var currentState: DatabaseState

    private var states = Set<DatabaseState>()

    private let stateLock = Lock()

    private let writeLock = Lock()

}

private class EntityUpdatesBuilder: WriteEntityDataStorage
{
    func getUpdates() -> [EntityUpdate] {
        return self.updates
    }

    func insert(entityData: EntityData)
    {
        let update = EntityUpdate(identifier: entityData.identifier, type: .insert)
        self.updates.append(update)
    }

    func removeEntityData(withIdentifier identifier: BaseEntityIdentifier)
    {
        let update = EntityUpdate(identifier: identifier, type: .remove)
        self.updates.append(update)
    }

    private var updates: [EntityUpdate] = []
}

