
import Foundation

public final class EntityCollectionView<Element: Entity>
{
    // MARK: - Initializer

    init<P: Predicate, Storage: EntityReadStorage>(predicate: P, storage: Storage) where P.Element == Element, Storage.EnityType == Element
    {
        self.predicate = AnyPredicate(predicate)
        self.queue.sync {
            self.update(with: storage)
        }
    }

    // MARK: - Functions

    public func subscribe(block: @escaping SubscriptionBlock) -> SubscriptionToken
    {
        let token = self.observerCollection.subscribe(parent: self, callback: block)

        self.queue.async { [weak self] in
            guard let instance = self else { return }

            let entities = Array(instance.entities.values)
            instance.dispatch(entities: entities, to: block)
        }

        return token
    }

    // MARK: - Private Functions

    private func update<Storage: EntityReadStorage>(with storage: Storage) where Storage.EnityType == Element
    {
        var entities: [Element.Key: Element] = [:]

        storage.enumerate(entities: { entity, stop in
            if self.predicate.evaluate(entity) {
                entities[entity.key] = entity
            }
        })

        self.entities = entities
        didUpdateEntities()
    }

    private func update(with entityUpdates: [EntityUpdate<Element>])
    {
        for update in entityUpdates
        {
            switch update
            {
                case .insert(let entity):
                    if self.predicate.evaluate(entity) {
                        self.entities[entity.key] = entity
                    }

                case .remove(let key):
                    self.entities[key] = nil
            }
        }

        didUpdateEntities()
    }

    private func didUpdateEntities()
    {
        let entities = Array(self.entities.values)
        self.observerCollection.each { callback in
            self.dispatch(entities: entities, to: callback)
        }
    }

    private func dispatch(entities: [Element], to subscription: @escaping SubscriptionBlock)
    {
        DispatchQueue.global().async {
            subscription(entities)
        }
    }

    // MARK: - Inner Types

    public typealias SubscriptionBlock = ([Element]) -> Void

    // MARK: - Private Properties

    private var entities: [Element.Key: Element] = [:]

    private let predicate: AnyPredicate<Element>

    private var observerCollection = ObserverCollection<EntityCollectionView<Element>, [Element]>()

    private let queue = DispatchQueue(label: "ru.kolyasev.Harmony.EntityCollectionView.queue")
}

extension EntityCollectionView: EntityUpdatesListener
{
    // MARK: - Functions

    func updateEntities(with entityUpdates: [EntityUpdate<Element>])
    {
        self.queue.async { [weak self] in
            self?.update(with: entityUpdates)
        }
    }
}
