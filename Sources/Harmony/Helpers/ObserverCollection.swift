
class ObserverCollection<Parent, Value>
{
    // MARK: - Functions

    func subscribe(parent: Parent, callback: @escaping Callback) -> SubscriptionToken
    {
        let subscription = Subscription(parent: parent, callback: callback)
        self.observers.append(WeakBox(subscription))
        return subscription
    }

    func each(_ block: (@escaping Callback) -> Void)
    {
        for observer in self.observers
        {
            if let observer = observer.getValue(),
               let callback = observer.callback
            {
                block(callback)
            }
        }
    }

    // MARK: - Inner Types

    typealias Callback = (Value) -> Void

    // MARK: - Private Properties

    private var observers: [WeakBox<Subscription<Parent, Value>>] = []
}

public protocol SubscriptionToken: class {

    // MARK: - Functions

    func invalidate()

}

final class Subscription<Parent, Value>: SubscriptionToken
{
    // MARK: - Initialization

    init(parent: Parent, callback: @escaping Callback)
    {
        self.parent = parent
        self.callback = callback
    }

    // MARK: - Properties

    private(set) var parent: Parent?

    private(set) var callback: Callback?

    // MARK: - Functions

    func invalidate()
    {
        self.parent = nil
        self.callback = nil
    }

    // MARK: - Inner Types

    typealias Callback = (Value) -> Void
}
