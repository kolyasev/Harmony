
final class EntityViewProvider<Element: Entity>
{
    // MARK: - Functions

    func enumerateViews(_ enumerator: (EntityView<Element>) -> Void)
    {
        for view in (self.views.values.map{ $0.getValue() }) {
            if let view = view {
                enumerator(view)
            }
        }
    }

    func view(stateManager: EntityCollectionStateManager<Element>, key: Element.Key) -> EntityView<Element>
    {
        let view: EntityView<Element>

        if let existingView = self.views[key]?.getValue()
        {
            view = existingView
        }
        else {
            view = makeView(stateManager: stateManager, key: key)
            self.views[key] = WeakBox(view)
        }

        return view
    }

    func existingView(for key: Element.Key) -> EntityView<Element>?
    {
        return self.views[key]?.getValue()
    }

    // MARK: - Private Functions

    private func makeView(stateManager: EntityCollectionStateManager<Element>, key: Element.Key) -> EntityView<Element>
    {
        let view = stateManager.read { state in
            return EntityView(key: key, storage: state)
        }

        self.views[key] = WeakBox(view)

        return view
    }

    // MARK: - Private Properties

    private var views: [Element.Key: WeakBox<EntityView<Element>>] = [:]

}
