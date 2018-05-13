
import Foundation

class EntityCollectionStateManager<T: Entity>
{
    // MARK: - Initialization

    init<Storage: EntityReadWriteStorage>(entityStorage: Storage) where Storage.EnityType == T
    {
        self.entityStorage = AnyEntityReadWriteStorage<T>(entityStorage)
        self.currentState = EntityCollectionReadState<T>(entityStorage: entityStorage)
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
            let state = self.currentState.makeReadChild()
            self.states.insert(state)
            return state
        }
    }

    private func makeReadWriteState() -> EntityCollectionReadWriteState<T>
    {
        return self.stateLock.withCriticalScope {
            let state = self.currentState.makeReadWriteChild()
            self.states.insert(state)
            return state
        }
    }

    private func commit(state: EntityCollectionReadState<T>)
    {
        return self.stateLock.withCriticalScope {
            guard let state = self.states.remove(state) else {
                fatalError("Unexpected database state.")
            }

            if state.hasChanges {
                setCurrentState(state)
            }

            saveCurrentStateIfPossible()
        }
    }

    private func setCurrentState(_ state: EntityCollectionReadState<T>)
    {
        guard state.isChild(of: self.currentState) else {
            fatalError("Trying to perform multiple write operations at same time.")
        }

        self.currentState = state

        readAsync(withState: state) { readState in
            self.handleEntityUpdates(for: readState)
        }
    }

    private func readAsync(withState state: EntityCollectionReadState<T>, block: @escaping (EntityCollectionReadState<T>) -> Void)
    {
        let readState = state.makeReadChild()
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
        if  self.currentState.hasChanges {
            self.currentState.writeChanges(to: self.entityStorage)

            // Create fresh state based of current entity storage state
            self.currentState = EntityCollectionReadState(entityStorage: self.entityStorage)
        }
    }

    // FIXME: Not implemented
    private func handleEntityUpdates(for state: EntityCollectionState<T>)
    {
        // ...
    }

    private var currentState: EntityCollectionReadState<T>

    private var states = Set<EntityCollectionReadState<T>>()

    private let stateLock = Lock()

    private let writeLock = Lock()
}
