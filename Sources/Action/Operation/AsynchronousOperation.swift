//
//  AsynchronousOperation.swift
//  QMobileUI
//
//  Created by phimage on 05/11/2020.
//

import Foundation

open class AsynchronousOperation: Operation {

    /// State for this operation.
    @objc enum OperationState: Int {
        case ready
        case executing
        case finished
    }

    /// Concurrent queue for synchronizing access to `state`.
    private let stateQueue = DispatchQueue(label: Bundle.main.bundleIdentifier! + ".rw.state", attributes: .concurrent)
    // to test with lock: private let lock: NSLock

    /// Private backing stored property for `state`.
    private var _state: OperationState = .ready

    /// The state of the operation
    @objc dynamic var state: OperationState {
        get {
            return stateQueue.sync {
                _state
            }
        }
        set {
            stateQueue.async(flags: .barrier) {
                self._state = newValue
                self.onStateChanged?(newValue)
            }
        }
    }

    /// Be notified on state change without KVN
    var onStateChanged: ((_ state: OperationState) -> Void)?

    // MARK: - Various `Operation` properties

    open override var isReady: Bool { return state == .ready && super.isReady }
    public final override var isExecuting: Bool { return state == .executing }
    public final override var isFinished: Bool { return state == .finished }
    public final override var isAsynchronous: Bool { return true }

    // KVN for dependent properties
    open override class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        if ["isReady", "isFinished", "isExecuting"].contains(key) {
            return [#keyPath(state)]
        }
        return super.keyPathsForValuesAffectingValue(forKey: key)
    }

    /// Start
    public final override func start() {
        if isCancelled {
            state = .finished
            return
        }
        state = .executing
        main()
    }

    /// Subclasses must implement this to perform their work and they must not call `super`. The default implementation of this function throws an exception.
    open override func main() {
        fatalError("Subclasses must implement `main`.")
    }

    /// Call this function to finish an operation that is currently executing
    open func finish() {
        if !self.isFinished { self.state = .finished }
    }
}

open class AsynchronousResultOperation<Success, Failure>: AsynchronousOperation where Failure: Error {
    private(set) public var result: Result<Success, Failure>! {
        didSet {
            onResult?(result)
        }
    }
    public var onResult: ((_ result: Result<Success, Failure>) -> Void)?

    public final override func finish() {
        guard !isCancelled else { return super.finish() }
        fatalError("Make use of finish(with:) instead to ensure a result")
    }
    public func finish(with result: Result<Success, Failure>) {
        self.result = result
        super.finish()
    }
    override open func cancel() {
        fatalError("Make use of cancel(with:) instead to ensure a result")
    }
    public func cancel(with error: Failure) {
        self.result = .failure(error)
        super.cancel()
    }
}
