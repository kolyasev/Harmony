
import Foundation

public final class EntityView<Element: Entity>
{
    // MARK: - Initializer

    init<Storage: EntityReadStorage>(key: Element.Key, storage: Storage) where Storage.EnityType == Element
    {
        self.key = key
        self.queue.sync {
            self.update(with: storage)
        }
    }

    // MARK: - Properties

    public private(set) var entity: Element?

    // MARK: - Public Functions

    public func subscribe(block: @escaping SubscriptionBlock) -> SubscriptionToken
    {
        let token = self.observerCollection.subscribe(parent: self, callback: block)

        self.queue.async { [weak self] in
            guard let instance = self else { return }

            instance.dispatch(entity: instance.entity, to: block)
        }

        return token
    }

    // MARK: - Inner Functions

    func updateEntity(with entityUpdate: EntityUpdate<Element>)
    {
        guard entityUpdate.key == self.key else { return }

        self.queue.async { [weak self] in
            self?.entity = entityUpdate.entity
            self?.didUpdateEntity()
        }
    }

    // MARK: - Private Functions

    private func update<Storage: EntityReadStorage>(with storage: Storage) where Storage.EnityType == Element
    {
        self.entity = storage.entity(forKey: self.key)
        didUpdateEntity()
    }

    private func didUpdateEntity()
    {
        self.observerCollection.each { callback in
            self.dispatch(entity: self.entity, to: callback)
        }
    }

    private func dispatch(entity: Element?, to subscription: @escaping SubscriptionBlock)
    {
        DispatchQueue.global().async {
            subscription(entity)
        }
    }

    // MARK: - Inner Types

    public typealias SubscriptionBlock = (Element?) -> Void

    // MARK: - Private Properties

    private let key: Element.Key

    private var observerCollection = ObserverCollection<EntityView<Element>, Element?>()

    private let queue = DispatchQueue(label: "ru.kolyasev.Harmony.EntityView.queue")
}
