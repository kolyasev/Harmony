
class EntityCollectionProvider
{
    init(transactionQueue: TransactionQueue)
    {
        self.transactionQueue = transactionQueue
    }

    func collection<T>(_ type: T.Type) -> EntityCollection<T>
    {
        let identifier = ObjectIdentifier(T.self)
        let collection: EntityCollection<T>

        if let existingCollection = self.collections[identifier] as? EntityCollection<T>
        {
            collection = existingCollection
        }
        else {
            collection = makeDataCollection()
            self.collections[identifier] = collection
        }

        return collection
    }

    private func makeDataCollection<T>() -> EntityCollection<T>
    {
        return EntityCollection(transactionQueue: self.transactionQueue)
    }

    private let transactionQueue: TransactionQueue

    private var collections: [ObjectIdentifier: Any] = [:]

}
