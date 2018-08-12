
protocol EntityUpdatesListener: class
{
// MARK: - Functions

    func updateEntities(with entityUpdates: [EntityUpdate<Element>])

// MARK: - Inner Types

    associatedtype Element: Entity
}

final class AnyEntityUpdatesListener<T: Entity>: EntityUpdatesListener
{
// MARK: - Initialization

    init<Listener: EntityUpdatesListener>(_ updatesListener: Listener) where Listener.Element == T {
        self._didUpdateEntitiesWith = { updates in updatesListener.updateEntities(with: updates) }
    }

// MARK: - Functions

    func updateEntities(with entityUpdates: [EntityUpdate<T>]) {
        self._didUpdateEntitiesWith(entityUpdates)
    }

// MARK: - Inner Types

    typealias Element = T

// MARK: - Private Properties

    private let _didUpdateEntitiesWith: ([EntityUpdate<T>]) -> Void
}
