
import Foundation

public class EntityCollectionView<T: Entity>
{
    // MARK: - Initializer

    init<P: EntityPredicate, Storage: EntityReadStorage>(predicate: P, storage: Storage) where P.Root == T, Storage.EnityType == T
    {
        self.predicate = AnyEntityPredicate(predicate)
        self.queue.async {
            self.update(with: storage)
        }
    }

    // MARK: - Properties

    var identifier: String {
        return String(describing: T.self) // + self.predicate.identifier
    }

    // MARK: - Functions

    public func subscribe(block: @escaping SubscriptionBlock) -> SubscriptionToken
    {
        let token = SubscriptionToken()

        self.subscriptions[token.uuid] = block

        self.queue.async { [weak self] in
            guard let instance = self else { return }

            let entities = Array(instance.entities.values)
            instance.dispatch(entities: entities, to: block)
        }

        return token
    }

    public func unsubscribe(_ token: SubscriptionToken)
    {
        self.subscriptions[token.uuid] = nil
    }

    // MARK: - Private Functions

    private func update<Storage: EntityReadStorage>(with storage: Storage) where Storage.EnityType == T
    {
        var entities: [T.Key: T] = [:]

        storage.enumerate(entities: { entity, stop in
            if self.predicate.evaluate(entity) {
                entities[entity.key] = entity
            }
        })

        self.entities = entities
        didUpdateEntities()
    }

    private func update(with entityUpdates: [EntityUpdate<T>])
    {
        for update in entityUpdates
        {
            switch update
            {
                case .insert(let entity):
                    self.entities[entity.key] = entity

                case .remove(let key):
                    self.entities[key] = nil
            }
        }

        didUpdateEntities()
    }

    private func didUpdateEntities()
    {
        let entities = Array(self.entities.values)
        for subscription in self.subscriptions.values {
            dispatch(entities: entities, to: subscription)
        }
    }

    private func dispatch(entities: [T], to subscription: @escaping SubscriptionBlock)
    {
        DispatchQueue.global().async {
            subscription(entities)
        }
    }

    // MARK: - Inner Types

    public typealias SubscriptionBlock = ([T]) -> Void

    public struct SubscriptionToken
    {
        fileprivate let uuid: UUID = UUID()
    }

    // MARK: - Private Properties

    private var entities: [T.Key: T] = [:]

    private let predicate: AnyEntityPredicate<T>

    private var subscriptions: [UUID: SubscriptionBlock] = [:]

    private let queue = DispatchQueue(label: "ru.kolyasev.Harmony.EntityCollectionView.queue")
}

extension EntityCollectionView: EntityUpdatesListener
{
    // MARK: - Functions

    func updateEntities(with entityUpdates: [EntityUpdate<T>])
    {
        self.queue.async { [weak self] in
            self?.update(with: entityUpdates)
        }
    }

    // MARK: - Inner Types

    typealias EntityType = T
}
