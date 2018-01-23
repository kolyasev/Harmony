
class EntityCollection<T: Entity>
{
    init(transactionQueue: TransactionQueue)
    {
        self.transactionQueue = transactionQueue
    }

    func view() -> EntityCollectionView<T>
    {
        fatalError()
    }

    func read<R>(_ block: @escaping (EntityCollectionReadState<T>) -> R) -> R
    {
        let transaction = ReadTransaction<T, R>(block: block)
        return self.transactionQueue.enqueueSync(transaction: transaction)
    }

    func write<R>(_ block: @escaping (EntityCollectionReadWriteState<T>) -> R) -> R
    {
        let transaction = ReadWriteTransaction<T, R>(block: block)
        return self.transactionQueue.enqueueSync(transaction: transaction)
    }

    private let transactionQueue: TransactionQueue
}

extension EntityCollection
{
    func asyncRead<R>(_ block: @escaping (EntityCollectionReadState<T>) -> R, completion: ((R) -> Void)? = nil)
    {
        let transaction = ReadTransaction<T, R>(block: block)
        self.transactionQueue.enqueueAsync(transaction: transaction, completion: completion)
    }

    func asyncWrite<R>(_ block: @escaping (EntityCollectionReadWriteState<T>) -> R, completion: ((R) -> Void)? = nil)
    {
        let transaction = ReadWriteTransaction<T, R>(block: block)
        return self.transactionQueue.enqueueAsync(transaction: transaction, completion: completion)
    }
}
