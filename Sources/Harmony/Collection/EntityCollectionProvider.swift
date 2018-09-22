
class EntityCollectionProvider
{
    // MARK: - Initialization

    init(baseEntityStorage: BaseEntityStorage)
    {
        self.baseEntityStorage = baseEntityStorage
    }

    // MARK: - Functions

    func collection<Element>(_ type: Element.Type) -> EntityCollection<Element>
    {
        self.lock.lock(); defer { self.lock.unlock() }

        let identifier = ObjectIdentifier(Element.self)
        let collection: EntityCollection<Element>

        if let existingCollection = self.collections[identifier] as? EntityCollection<Element>
        {
            collection = existingCollection
        }
        else {
            collection = makeEntityCollection()
            self.collections[identifier] = collection
        }

        return collection
    }

    // MARK: - Private Functions

    private func makeEntityCollection<Element>() -> EntityCollection<Element>
    {
        return EntityCollection(baseEntityStorage: self.baseEntityStorage)
    }

    // MARK: - Private Properties

    private let baseEntityStorage: BaseEntityStorage

    private var collections: [ObjectIdentifier: Any] = [:]

    private let lock = Lock()

}
