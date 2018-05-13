
// FIXME: Not implemented
//
//struct WeakBox<T>
//{
//    init(_ value: T) {
//        self.value = value as AnyObject
//    }
//
//    func getValue() -> T? {
//        return self.value as? T
//    }
//
//    private weak var value: AnyObject?
//}
//
//class EntityCollectionViewProvider
//{
//    init(stateManager: DatabaseStateManager) {
//        self.stateManager = stateManager
//    }
//
//    func view<P: EntityPredicate>(_ type: P.Root.Type, predicate: P) -> EntityCollectionView<P.Root>
//    {
//        return makeView(predicate: predicate)
//
//        // TODO: Reuse views
////        let identifier = ObjectIdentifier(T.self)
////        let view: EntityCollectionView<T>
////
////        if let existingView = self.views[identifier] as? EntityCollectionView<T>
////        {
////            view = existingView
////        }
////        else {
////            view = makeView()
////            self.views[identifier] = view
////        }
////
////        return view
//    }
//
//    private func makeView<P: EntityPredicate>(predicate: P) -> EntityCollectionView<P.Root>
//    {
//        let view = EntityCollectionView(predicate: predicate)
//
//        self.stateManager.read { state in
//            view.update(with: state)
//        }
//
//        self.views[ObjectIdentifier(view)] = WeakBox(view)
//
//        return view
//    }
//
//    private let stateManager: DatabaseStateManager
//
//    private var views: [ObjectIdentifier: WeakBox<BaseEntityCollectionView>] = [:]
//
//}
//
//extension EntityCollectionViewProvider: EntityUpdatesListener
//{
//    func handleEntityUpdates(_ updates: [EntityUpdate], in state: DatabaseState)
//    {
//        for view in self.views.values {
//            view.getValue()?.handleEntityUpdates(updates, in: state)
//        }
//    }
//}
