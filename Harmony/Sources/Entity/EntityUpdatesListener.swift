
protocol EntityUpdatesListener: class
{
    // MARK: - Functions

    func updateEntities(with entityUpdates: [EntityUpdate<EntityType>])

    // MARK: - Inner Types

    associatedtype EntityType: Entity
}

final class AnyEntityUpdatesListener<T: Entity>: EntityUpdatesListener
{
    // MARK: - Initialization

    init<Listener: EntityUpdatesListener>(_ updatesListener: Listener) where Listener.EntityType == T {
        self._didUpdateEntitiesWith = { updates in updatesListener.updateEntities(with: updates) }
    }

    // MARK: - Functions

    func updateEntities(with entityUpdates: [EntityUpdate<T>]) {
        self._didUpdateEntitiesWith(entityUpdates)
    }

    // MARK: - Inner Types

    typealias EntityType = T

    // MARK: - Private Properties

    private let _didUpdateEntitiesWith: ([EntityUpdate<T>]) -> Void
}
