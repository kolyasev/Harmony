
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
            if let observer = observer.getValue() {
                block(observer.callback)
            }
        }
    }

    // MARK: - Inner Types

    typealias Callback = (Value) -> Void

    // MARK: - Private Properties

    private var observers: [WeakBox<Subscription<Parent, Value>>] = []
}

public class SubscriptionToken {}

final class Subscription<Parent, Value>: SubscriptionToken
{
    // MARK: - Initialization

    init(parent: Parent, callback: @escaping Callback)
    {
        self.parent = parent
        self.callback = callback
    }

    // MARK: - Properties

    let parent: Parent

    let callback: Callback

    // MARK: - Inner Types

    typealias Callback = (Value) -> Void
}
