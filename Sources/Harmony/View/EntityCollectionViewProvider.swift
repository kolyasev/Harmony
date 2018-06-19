
final class EntityCollectionViewProvider<Element: Entity>
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

    func view<P: Predicate>(stateManager: EntityCollectionStateManager<Element>, predicate: P) throws -> EntityCollectionView<P.Element> where P.Element == Element
    {
        let identifier = AnyPredicate(predicate)
        let view: EntityCollectionView<Element>

        if let existingView = self.views[identifier]?.getValue()
        {
            view = existingView
        }
        else {
            view = try makeView(stateManager: stateManager, predicate: predicate)
            self.views[identifier] = WeakBox(view)
        }

        return view
    }

    // MARK: - Private Functions

    private func makeView<P: Predicate>(stateManager: EntityCollectionStateManager<Element>, predicate: P) throws -> EntityCollectionView<P.Element> where P.Element == Element
    {
        let view = try stateManager.read { state in
            return try EntityCollectionView(predicate: predicate, storage: state)
        }

        let identifier = AnyPredicate(predicate)
        self.views[identifier] = WeakBox(view)

        return view
    }

    // MARK: - Private Properties

    private var views: [AnyPredicate<Element>: WeakBox<EntityCollectionView<Element>>] = [:]
}
