
import Foundation

protocol BaseEntityCollectionView: EntityUpdatesListener
{
    static var entityType: BaseEntity.Type { get }

    func update(with state: DatabaseState)
}

class EntityCollectionView<T: Entity>: BaseEntityCollectionView
{
    init<P: EntityPredicate>(predicate: P) where P.Root == T {
        self.predicate = AnyEntityPredicate(predicate)
    }

    var identifier: String {
        return String(describing: T.self) // + self.predicate.identifier
    }

    class var entityType: BaseEntity.Type {
        return T.self
    }

    func subscribe(block: @escaping SubscriptionBlock) -> SubscriptionToken
    {
        let token = SubscriptionToken()

        self.subscriptions[token.uuid] = block

        if let entityHolders = self.entityHolders {
            dispatch(entityHolders: entityHolders, to: block)
        }

        return token
    }

    func unsubscribe(_ token: SubscriptionToken)
    {
        self.subscriptions[token.uuid] = nil
    }

    func update(with state: DatabaseState)
    {
        var holders: [EntityHolder<T>] = []

        state.enumerate(entityType: T.self, entityHolders: { holder, stop in
            if let holder = holder.cast(to: T.self), self.predicate.evaluate(holder.entity) {
                holders.append(holder)
            }
        })

        self.entityHolders = holders
        didUpdateEntities()
    }

    func handleEntityUpdates(_ updates: [EntityUpdate], in state: DatabaseState)
    {
        guard var entityHolders: [EntityHolder<T>?] = self.entityHolders else {
            fatalError()
        }

        let rootTypeUpdates = self.rootTypeUpdates(from: updates)

        var rootTypeUpdatesDict: [BaseEntityIdentifier: EntityUpdate.UpdateType] = [:]
        for update in rootTypeUpdates {
            rootTypeUpdatesDict[update.identifier] = update.type
        }

        for (idx, entityHolder) in entityHolders.enumerated()
        {
            guard let entityHolder = entityHolder else {
                fatalError()
            }

            if let updateType = rootTypeUpdatesDict[entityHolder.entity.identifier]
            {
                self.dependencies.removeDependencies(forEntityHolder: entityHolder.castToAny())

                switch updateType
                {
                    case .insert:
                        if let holder = state.entityHolder(withIdentifier: entityHolder.entity.identifier)?.cast(to: T.self),
                           self.predicate.evaluate(holder.entity)
                        {
                            entityHolders[idx] = holder
                            self.dependencies.addDependencies(forEntityHolder: holder.castToAny())
                        }
                        else {
                            entityHolders[idx] = nil
                        }

                    case .remove:
                        entityHolders[idx] = nil
                }

                rootTypeUpdatesDict[entityHolder.entity.identifier] = nil
            }
        }

        for (identifier, update) in rootTypeUpdatesDict where update == .insert
        {
            if let holder = state.entityHolder(withIdentifier: identifier)?.cast(to: T.self),
               self.predicate.evaluate(holder.entity)
            {
                entityHolders.append(holder)
            }
        }

        self.entityHolders = entityHolders.flatMap{ $0 }
        didUpdateEntities()
    }

    private func setEntityHolders(_ entityHolders: [EntityHolder<T>])
    {
        precondition(self.entityHolders == nil)

        for entityHolder in entityHolders
        {
            for dependencyIdentifier in entityHolder.dependencies
            {
                let dependency = Dependency(parent: entityHolder.entity.identifier, child: dependencyIdentifier)
                self.dependencies.add(dependency: dependency)
            }
        }

        self.entityHolders = entityHolders
    }

    private func didUpdateEntities()
    {
        guard let entityHolders = self.entityHolders else {
            preconditionFailure()
        }

        for subscription in self.subscriptions.values {
            dispatch(entityHolders: entityHolders, to: subscription)
        }
    }

    private func dispatch(entityHolders: [EntityHolder<T>], to subscription: @escaping SubscriptionBlock)
    {
        DispatchQueue.global().async {
            subscription(entityHolders.map{ $0.entity })
        }
    }

    private func rootTypeUpdates(from updates: [EntityUpdate]) -> [EntityUpdate]
    {
        var rootTypeUpdates: [EntityUpdate] = []

        for update in updates
        {
            if update.identifier.type == T.self
            {
                rootTypeUpdates.append(update)
            }
            else {
                let identifiers = self.dependencies.topParentIdentifiers(forChildIdentifier: update.identifier)
                let updates = identifiers.map{ EntityUpdate(identifier: $0, type: update.type) }
                rootTypeUpdates.append(contentsOf: updates)
            }
        }

        return rootTypeUpdates
    }

    typealias SubscriptionBlock = ([T]) -> Void

    struct SubscriptionToken
    {
        fileprivate let uuid: UUID = UUID()
    }

    private let predicate: AnyEntityPredicate<T>

    private var subscriptions: [UUID: SubscriptionBlock] = [:]

    private var entityHolders: [EntityHolder<T>]?

    private let dependencies = Dependencies()
}

private struct Dependency
{
    let parent: BaseEntityIdentifier
    let child: BaseEntityIdentifier
}

private class Dependencies
{
    func add(dependency: Dependency)
    {
        var childs = self.parentToChild[dependency.parent] ?? []
        childs.insert(dependency.child)
        self.parentToChild[dependency.parent] = childs

        var parents = self.childToParent[dependency.child] ?? []
        parents.insert(dependency.parent)
        self.childToParent[dependency.child] = parents
    }

    func addDependencies(forEntityHolder entityHolder: AnyEntityHolder)
    {
        for identifier in entityHolder.dependencies
        {
            let dependency = Dependency(parent: entityHolder.entity.identifier, child: identifier)
            add(dependency: dependency)
        }
    }

    func remove(dependency: Dependency)
    {
        var childs = self.parentToChild[dependency.parent] ?? []
        childs.remove(dependency.child)
        self.parentToChild[dependency.parent] = childs

        var parents = self.childToParent[dependency.child] ?? []
        parents.remove(dependency.parent)
        self.childToParent[dependency.child] = parents
    }

    func removeDependencies(forEntityHolder entityHolder: AnyEntityHolder)
    {
        for identifier in entityHolder.dependencies
        {
            let dependency = Dependency(parent: entityHolder.entity.identifier, child: identifier)
            remove(dependency: dependency)
        }
    }

    func topParentIdentifiers(forChildIdentifier identifier: BaseEntityIdentifier) -> [BaseEntityIdentifier]
    {
        var parentIdentifiers: Set<BaseEntityIdentifier> = []

        if let parents = self.childToParent[identifier]
        {
            let parents = topParentIdentifiers(forParentIdentifiers: Array(parents))
            for parent in parents {
                parentIdentifiers.insert(parent)
            }
        }

        return Array(parentIdentifiers)
    }

    func topParentIdentifiers(forParentIdentifiers identifiers: [BaseEntityIdentifier]) -> [BaseEntityIdentifier]
    {
        var parentIdentifiers: Set<BaseEntityIdentifier> = []

        for identifier in identifiers
        {
            let parents = topParentIdentifiers(forChildIdentifier: identifier)
            if !parents.isEmpty
            {
                for parent in parents {
                    parentIdentifiers.insert(parent)
                }
            }
            else {
                parentIdentifiers.insert(identifier)
            }
        }

        return Array(parentIdentifiers)
    }

    private(set) var parentToChild: [BaseEntityIdentifier: Set<BaseEntityIdentifier>] = [:]

    private(set) var childToParent: [BaseEntityIdentifier: Set<BaseEntityIdentifier>] = [:]
}
