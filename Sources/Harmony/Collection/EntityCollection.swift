
public final class EntityCollection<Element: Entity>
{
    // MARK: - Initialization

    init(baseEntityStorage: BaseEntityStorage)
    {
        let entityCollectionStorage = EntityCollectionStorage<Element>(baseEntityStorage: baseEntityStorage)
        self.stateManager = EntityCollectionStateManager(entityStorage: entityCollectionStorage)
        self.transactionQueue.target = self
        self.stateManager.updatesListener = { [weak self] updates in
            self?.updateEntities(with: updates)
        }
    }

    // MARK: - Functions: Views

    public func view<P: Predicate>(_ predicate: P) throws -> EntityCollectionView<P.Element> where P.Element == Element
    {
        return try self.collectionViewProvider.view(stateManager: self.stateManager, predicate: predicate)
    }

    public func view(_ key: Element.Key) throws -> EntityView<Element>
    {
        return try self.viewProvider.view(stateManager: self.stateManager, key: key)
    }

    // MARK: - Functions: Read / Write

    public func read<R>(_ block: @escaping (EntityCollectionReadState<Element>) throws -> R) throws -> R
    {
        let transaction = ReadTransaction<Element, R>(block: block)
        return try self.transactionQueue.enqueueSync(transaction: transaction)
    }

    public func write<R>(_ block: @escaping (EntityCollectionReadWriteState<Element>) throws -> R) throws -> R
    {
        let transaction = ReadWriteTransaction<Element, R>(block: block)
        return try self.transactionQueue.enqueueSync(transaction: transaction)
    }

    // MARK: - Private Functions

    private func perform<T: Transaction, Result>(transaction: T) throws -> Result where T.TransactionEntity == Element, T.Result == Result
    {
        return try transaction.run(entityCollectionStateManager: self.stateManager)
    }

    private func handleEntityUpdates(_ entityUpdates: [EntityUpdate<Element>])
    {
        self.collectionViewProvider.enumerateViews { view in
            view.updateEntities(with: entityUpdates)
        }

        for entityUpdate in entityUpdates
        {
            if let view = self.viewProvider.existingView(for: entityUpdate.key) {
                view.updateEntity(with: entityUpdate)
            }
        }
    }

    // MARK: - Private Properties

    private let transactionQueue = TransactionQueue<EntityCollection<Element>>()

    private let stateManager: EntityCollectionStateManager<Element>

    private let collectionViewProvider = EntityCollectionViewProvider<Element>()

    private let viewProvider = EntityViewProvider<Element>()
}

extension EntityCollection
{
    // MARK: - Functions

    public func asyncRead<R>(_ block: @escaping (EntityCollectionReadState<Element>) -> R, completion: ((Result<R>) -> Void)? = nil)
    {
        let transaction = ReadTransaction<Element, R>(block: block)
        self.transactionQueue.enqueueAsync(transaction: transaction, completion: completion)
    }

    public func asyncWrite<R>(_ block: @escaping (EntityCollectionReadWriteState<Element>) -> R, completion: ((Result<R>) -> Void)? = nil)
    {
        let transaction = ReadWriteTransaction<Element, R>(block: block)
        return self.transactionQueue.enqueueAsync(transaction: transaction, completion: completion)
    }
}

extension EntityCollection: TransactionQueueTarget
{
    // MARK: - Functions

    func run<T: Transaction>(transaction: T) throws -> T.Result where T.TransactionEntity == TransactionEntity
    {
        return try transaction.run(entityCollectionStateManager: self.stateManager)
    }

    // MARK: - Inner Types

    typealias TransactionEntity = Element
}

extension EntityCollection: EntityUpdatesListener
{
    // MARK: - Functions

    func updateEntities(with entityUpdates: [EntityUpdate<Element>]) {
        handleEntityUpdates(entityUpdates)
    }

    // MARK: - Inner Types

    typealias EntityType = Element
}

extension EntityCollection
{
    // MARK: - Functions: Read

    public func entity(forKey key: Element.Key) throws -> Element?
    {
        return try read { state in
            return try state.entity(forKey: key)
        }
    }

    public func enumerate(keys enumerator: @escaping (Element.Key, inout Bool) -> Void) throws
    {
        return try read { state in
            return try state.enumerate(keys: enumerator)
        }
    }

    public func enumerate(entities enumerator: @escaping (Element, inout Bool) -> Void) throws
    {
        return try read { state in
            return try state.enumerate(entities: enumerator)
        }
    }

    // MARK: - Functions: Write

    public func insert(entity: Element) throws
    {
        try write { state in
            try state.insert(entity: entity)
        }
    }

    public func removeEntity(forKey key: Element.Key) throws
    {
        try write { state in
            try state.removeEntity(forKey: key)
        }
    }

}
