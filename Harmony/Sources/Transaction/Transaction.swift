
protocol Transaction
{
    associatedtype TransactionEntity: Entity

    associatedtype Result

    func run(database: Database) -> Result
}

class ReadTransaction<T: Entity, R>: Transaction
{
    typealias TransactionEntity = T

    typealias Result = R

    init(block: @escaping ReadBlock)
    {
        self.block = block
    }

    func run(database: Database) -> R
    {
        return database.read { state in
            let collectionState = EntityCollectionReadState<T>(databaseState: state)
            return self.block(collectionState)
        }
    }

    typealias ReadBlock = (EntityCollectionReadState<T>) -> R

    private let block: ReadBlock
}

class ReadWriteTransaction<T: Entity, R>: Transaction
{
    typealias TransactionEntity = T

    typealias Result = R

    init(block: @escaping ReadWriteBlock)
    {
        self.block = block
    }

    func run(database: Database) -> R
    {
        return database.write { state in
            let collectionState = EntityCollectionReadWriteState<T>(databaseState: state)
            return self.block(collectionState)
        }
    }

    typealias ReadWriteBlock = (EntityCollectionReadWriteState<T>) -> R

    private let block: ReadWriteBlock
}
