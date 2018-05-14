
import Foundation

class EntityCollectionStateManager<T: Entity>
{
    // MARK: - Initialization

    init<Storage: EntityReadWriteStorage>(entityStorage: Storage) where Storage.EnityType == T
    {
        self.entityStorage = AnyEntityReadWriteStorage<T>(entityStorage)
    }

    // MARK: - Properties

    let entityStorage: AnyEntityReadWriteStorage<T>

    // MARK: - Functions

    func read<R>(_ block: (EntityCollectionReadState<T>) -> R) -> R
    {
        return perform(block: block, in: makeReadState())
    }

    func write<R>(_ block: (EntityCollectionReadWriteState<T>) -> R) -> R
    {
        return self.writeLock.withCriticalScope {
            return perform(block: block, in: makeReadWriteState())
        }
    }

    // MARK: - Private Functions

    private func perform<State: EntityCollectionReadState<T>, Result>(block: (State) -> Result, in state: State) -> Result
    {
        let result = block(state)
        commit(state: state)
        return result
    }

    private func makeReadState() -> EntityCollectionReadState<T>
    {
        return self.stateLock.withCriticalScope {
            let state = EntityCollectionReadState(entityStorage: getEntityReadStorage())
            self.activeStates.insert(state)
            return state
        }
    }

    private func makeReadWriteState() -> EntityCollectionReadWriteState<T>
    {
        return self.stateLock.withCriticalScope {
            let state = EntityCollectionReadWriteState(entityStorage: getEntityReadStorage())
            self.activeStates.insert(state)
            return state
        }
    }

    private func commit(state: EntityCollectionReadState<T>)
    {
        return self.stateLock.withCriticalScope {
            guard let state = self.activeStates.remove(state) else {
                fatalError("Unexpected database state.")
            }

            if let readWriteState = (state as? EntityCollectionReadWriteState),
               readWriteState.hasChanges
            {
                addWriteState(readWriteState)
            }

            saveWriteStatesIfNeeded()
        }
    }

    private func addWriteState(_ state: EntityCollectionReadWriteState<T>)
    {
        self.writeStates.append(state)

        readAsync(withState: state) { readState in
            self.handleEntityUpdates(for: readState)
        }
    }

    private func readAsync(withState state: EntityCollectionReadState<T>, block: @escaping (EntityCollectionReadState<T>) -> Void)
    {
        let readState = EntityCollectionReadState(entityStorage: state)
        self.activeStates.insert(readState)
        DispatchQueue.global().async {
            block(readState)
            self.commit(state: readState)
        }
    }

    private func saveWriteStatesIfNeeded()
    {
        guard self.activeStates.isEmpty else { return }

        // There is no other read or write transactions
        // We able to write states to entity storage
        for state in self.writeStates {
            state.writeChanges(to: self.entityStorage)
        }
        self.writeStates = []
    }

    // FIXME: Not implemented
    private func handleEntityUpdates(for state: EntityCollectionState<T>)
    {
        // ...
    }

    private func getEntityReadStorage() -> AnyEntityReadStorage<T>
    {
        guard let writeState = self.writeStates.last else {
            return AnyEntityReadStorage(self.entityStorage)
        }
        return AnyEntityReadStorage(writeState)
    }

    // MARK: - Private Properties

    private var activeStates: Set<EntityCollectionReadState<T>> = []

    private var writeStates: [EntityCollectionReadWriteState<T>] = []

    private let stateLock = Lock()

    private let writeLock = Lock()
}
