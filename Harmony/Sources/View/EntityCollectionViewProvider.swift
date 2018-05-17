
struct WeakBox<T>
{
    // MARK: - Initialization

    init(_ value: T) {
        self.value = value as AnyObject
    }

    // MARK: - Functions

    func getValue() -> T? {
        return self.value as? T
    }

    // MARK: - Private Functions

    private weak var value: AnyObject?
}

class EntityCollectionViewProvider<Element: Entity>
{
    // MARK: - Functions

    func enumerateViews(_ enumerator: (EntityCollectionView<Element>) -> Void)
    {
        for view in (self.views.values.map{ $0.getValue() }) {
            if let view = view {
                enumerator(view)
            }
        }
    }

    func view<Predicate: EntityPredicate>(stateManager: EntityCollectionStateManager<Element>, predicate: Predicate) -> EntityCollectionView<Predicate.Root> where Predicate.Root == Element
    {
        return makeView(stateManager: stateManager, predicate: predicate)

        // TODO: Reuse views
//        let identifier = ObjectIdentifier(T.self)
//        let view: EntityCollectionView<T>
//
//        if let existingView = self.views[identifier] as? EntityCollectionView<T>
//        {
//            view = existingView
//        }
//        else {
//            view = makeView()
//            self.views[identifier] = view
//        }
//
//        return view
    }

    // MARK: - Private Functions

    private func makeView<Predicate: EntityPredicate>(stateManager: EntityCollectionStateManager<Element>, predicate: Predicate) -> EntityCollectionView<Predicate.Root> where Predicate.Root == Element
    {
        let view = stateManager.read { state in
            return EntityCollectionView(predicate: predicate, storage: state)
        }

        let key = ObjectIdentifier(view)
        self.views[key] = WeakBox(view)

        return view
    }

    // MARK: - Private Properties

    private var views: [ObjectIdentifier: WeakBox<EntityCollectionView<Element>>] = [:]
}
