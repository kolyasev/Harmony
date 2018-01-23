
import Foundation

protocol TransactionQueueTarget: class
{
    func run<T>(transaction: T) -> T.Result where T: Transaction
}

class TransactionQueue
{
    weak var target: TransactionQueueTarget?

    func enqueueAsync<T>(transaction: T, completion: ((T.Result) -> Void)? = nil) where T: Transaction
    {
        return self.queue.async {
            let result: T.Result = self.getTarget().run(transaction: transaction)

            if let completion = completion
            {
                DispatchQueue.global().async {
                    completion(result)
                }
            }
        }
    }

    func enqueueSync<T>(transaction: T) -> T.Result where T: Transaction
    {
        return self.queue.sync {
            return self.getTarget().run(transaction: transaction)
        }
    }

    private func getTarget() -> TransactionQueueTarget
    {
        guard let target = self.target else {
            fatalError("Unknown target for queue.")
        }

        return target
    }

    private let queue = DispatchQueue(label: "ru.kolyasev.Harmony.TransactionQueue.queue", attributes: [.concurrent])
}
