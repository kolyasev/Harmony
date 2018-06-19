
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
