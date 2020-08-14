# SwiftReactor

A protocol which should help to structure your data flow in SwiftUI (and UIKit).

Inspired by [@devxoul](https://github.com/devxoul)´s [ReactorKit](https://www.github.com/ReactorKit/ReactorKit).

Special thanks to [@oanhof](https://github.com/oanhof) for contributing.

## Concept

This protocol helps to structure and maintain the ReactorKit architecture in your SwiftUI or UIKit (with Combine) project.
I highly encourage you to read the concept of this architecture in the ReactorKit´s [README.md](https://github.com/ReactorKit/ReactorKit#basic-concept)

## Usage

To see the SwiftReactor in action, clone this repository and try the [example project](https://github.com/julianpomper/SwiftReactor/tree/master/SwiftReactorExample)

### Reactor

For a basic setup just:

1. inherit from the `BaseReactor` class
2. define your `Action`s, `Mutation`s and your `State`
3. implement the `mutate(action: Action)` and `reduce(state: State, mutation: Mutation)` method

and you are ready to go.

<details>
<summary>Click here to show an example</summary>

```swift
class ExampleReactor: BaseReactor<ExampleReactor.Action, ExampleReactor.Mutation, ExampleReactor.State> {
    enum Action {
        case enterText(String)
        case setSwitch(Bool)
        case setSwitchAsync(Bool)
        case colorChangePressed(Color)
    }
    
    enum Mutation {
        case setText(String)
        case setSwitch(Bool)
        case setBackgroundColor(Color)
    }
    
    struct State {
        var text = "initial text"
        var switchValue = false
        var backgroundColor = Color.white
    }
    
    init() {
        super.init(initialState: State())
    }
    
    override func mutate(action: Action) -> Mutations<Mutation> {
        switch action {
        case .enterText(let text):
            return [.setText(text)] //is equal to: Mutations(sync: .setText(text))
        case .setSwitch(let value):
            return [.setSwitch(value)] //is equal to: Mutations(sync: .setSwitch(value))
        case .setSwitchAsync(let value):
            let mutation = Just(Mutation.setSwitch(!value)).delay(for: 2, scheduler: DispatchQueue.global())
                .eraseToAnyPublisher()
            
            return Mutations(sync: .setSwitch(value), async: mutation)
        case .colorChangePressed(let color):
            return [.setBackgroundColor(color)] //is equal to: Mutations(sync: .setBackgroundColor(color))
        }
    }
    
    override func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case .setText(let text):
            newState.text = text
        case .setSwitch(let value):
            newState.switchValue = value
        case .setBackgroundColor(let color):
            newState.backgroundColor = color
        }
        
        return newState
    }
    
    override func transform(mutation: AnyPublisher<Mutation, Never>) -> AnyPublisher<Mutation, Never> {
        mutation
            .prepend(.setText("hello"))
            .eraseToAnyPublisher()
    }
}
```
</details>

#### `mutate(action: Action)`
This method takes an `Action` and transforms it sync or async into an mutation.
**If you have any side effects do it here.**

Return `sync` mutations if you want to mutate the state instantly
and sychronously on the main thread.  `Binding` and `withAnimation` require the state to be changed
on the main thread synchronously. For that reason use `sync` mutations for
this use cases.


Return `async` mutations if you have to do async tasks (ex.: network requests)
or expensive tasks on a background queue

```swift
func mutate(action: Action) -> Mutations {
     switch action {
     case .noMutationNeededAction:
         return .none
     case .enterText(let text):
         return Mutations(sync: .setText(text))
     case .setSwitchAsync(let value):
        let mutation = API.setSetting(value)
            .catch { _ in Just(.setSwitch(!value)) }

        return Mutations(sync: .setSwitch(value), async: mutation)
     }
 }
 ```
 
 #### `reduce(state: State, mutation: Mutation)`
 This method takes a `State` and a `Mutation` and returns a new mutated `State`.
 **Don't perform any side effects in this method. Extract them to the `mutate(action: Action)`**
 
 ```swift
 func reduce(state: State, mutation: Mutation) -> State {
     var newState = state
     
     switch mutation {
     case .setText(let text):
         newState.text = text
     }
     
     return newState
 }
 ```
 
 #### `transform()`
 Use these methods to intersect the state stream. This is the best place to combine and insert global event streams into your reactor.
They are being called once, when the state stream is created in the `createStateStream()` method.
 
 ```swift
 /// Transforms an action and can be used to combine it with other publishers.
 func transform(action: AnyPublisher<Action, Never>) -> AnyPublisher<Action, Never>
 
 /// Transforms an mutation and can be used to combine it with other publishers.
 func transform(mutation: AnyPublisher<Mutation, Never>) -> AnyPublisher<Mutation, Never>
 
 /// Transforms the state and can be used to combine it with other publishers.
 func transform(state: AnyPublisher<State, Never>) -> AnyPublisher<State, Never>
 ```

#### `Mutations`

`Mutations` is a `struct` for a better separation of your `sync` and `async` mutations.

- `sync` is an `Array` with `Mutation`s that mutate the state instantly and are always automatically forced on the main thread synchronously. Use them specifically for UI interactions like `Binding`s, especially if the change should be animated (ex.: `withAnimation`)

- `async` is an `AnyPublisher<Mutation, Never>` that contains mutations that happen asynchronously and can mutate the state at any given time (ex.: if a network request returns a result). The `state` is always mutated on the main thread asychronously, everything before that happens on the thread of your choice.

You can initialize sync `Mutations` like an array. In this case `[.mySyncMutation]` is equal to `Mutations(sync: .mySyncMutation)` or  `[.mySyncMutation, .mySecondSyncMutation]`  is equal to `Mutations(sync: [.mySyncMutation, .mySecondSyncMutation])` .

If you do not want to mutate the state with an `Action` just return `.none` that equals to `Mutations()`


### View

```swift
struct ContentView: View {
    // access your reactor via the `@EnvironmentObject` property wrapper
    @EnvironmentObject
    var reactor: AppReactor
    
    // you can use this property wrapper to bind your value and action
    // it can be used and behaves like the `@State` property wrapper
    @ActionBinding(\AppReactor.self, keyPath: \.name, action: AppReactor.Action.nameChanged)
    private var name: String
    
    var body: some View {
        VStack {
            // access the value from the binding (the value from your current state)
            Text(name.wrappedValue)
            // bind your action to the changes of this textfield
            TextField("Name", text: $name)
        }
    }
}
```

## Advanced

### `Reactor` Nesting

<details>
<summary>Click here to expand</summary>

It is also possible to split your logic into different reactors but also ensure a single source of truth by nesting reactors states.

```swift
    class AppReactor: BaseReactor<AppReactor.Action, AppReactor.Mutation, AppReactor.State> {
    
        [...]
        
        public enum Mutation {
            case setDetail(DetailReactor.State)
        }
        
        struct State {
            var detail: DetailReactor.State
        }
        
        let detailReactor: DetailReactor
        
        init() {
        
            detailReactor = DetailReactor()
        
            super.init(
                initialState: State(
                    detail: detailReactor.state
                )
            )
        }
        
        override func reduce(state: State, mutation: Mutation) -> State {
            var newState = state
        
            switch mutation {
            case let .setDetail(state):
                newState.detail = state
            }
            
            return newState
        }
        
        // transform the state changes to mutations
        override func transform(mutation: AnyPublisher<Mutation, Never>) -> AnyPublisher<Mutation, Never> {
            let detail = detailReactor.$state
                .map { Mutation.setDetail($0) }
            
            return mutation
                .merge(with: detail)
        }
    }
```

To access or bind actions to nested reactors use the following property wrappers:

```swift
    // get the root Reactor
    @EnvironmentReactor()
    var reactor: AppReactor
    
    // get a nested reactor
    @EnvironmentReactor(\AppReactor.detailViewReactor)
    var reactor: DetailReactor
    
    // bind `Action`s using the root reactor
    @ActionBinding(\AppReactor.self, keyPath: \.name, action: AppReactor.Action.nameChanged)
    private var name: String
    
    // bind `Action`s using the nested reactor
    @ActionBinding(\AppReactor.detailViewReactor, keyPath: \.age, action: DetailReactor.Action.ageChanged)
    private var age: Int
```

</details>

### Use the `Reactor` protocol

<details>
<summary>Click here to expand</summary>

If you do not want to inherit the `BaseReactor` class, you can also implement the `Reactor` protocol on your own.
    
1. add all necessary propeties
2. add `@Published` to your state property
3. call the `createStateStream()` method (ex.: in your `init()`)
    
```swift
    class CountingReactor: Reactor {
    
        enum Action {
            case countUp
            case countUpAsync
        }
        
        enum Mutation {
            case countUp
        }
        
        struct State {
            var currentCount: Int = 0
        }
        
        public let action = PassthroughSubject<Action, Never>()
        
        public let mutation = PassthroughSubject<Mutation, Never>()
        
        @Published
        public var state = State()
        
        public var cancellables = Set<AnyCancellable>()
        
        public init() {
            createStateStream()
        }
        
        open func mutate(action: Action) -> Mutations<Mutation> {
            switch action {
            case .countUp:
                return [.countUp]
            case .countUpAsync:
                return Mutations(async: Just(.countUp).eraseToAnyPublisher())
            }
        }
        
        open func reduce(state: State, mutation: Mutation) -> State {
            var newState = state
            
            switch mutation {
            case .countUp:
                newState.currentCount += 1
            }
            
            return newState
        }
    }
```
</details>


### UIKit

<details>
<summary>Click here to expand</summary>

`SwiftReactor` is also compatible with UIKit if you need it.  To use it, you have to select and install the additional library `SwiftReactorUIKit` when you add the SwiftPackage to your project.

1. inherit from the `BaseReactorView` or `BaseReactorViewController` class
2. set the `reactor` property somewhere (ex.: when the `UIView` or `UIViewController` is being created)
3. implement the `bind(reactor:)` method and add your bindings

<details>
<summary>Click here to show an example</summary>

```swift
let countingViewController = BaseCountingViewController()
countingViewController.reactor = CountingReactor()
```

```swift
final class BaseCountingViewController: BaseReactorViewController<CountingReactor> {
    
    var label = UILabel()
    
    /// automatically called when you set the reactor
    override func bind(reactor: Reactor) {
        reactor.$state
            .map { String($0.currentCount) }
            .assign(to: \.label.text, on: self)
            .store(in: &cancellables)
    }
}
```
</details>

</details>

## TODOs
- [ ] Improve example project
- [ ] Add more tests
- [ ] Improve README

## Installation

### Swift Package Manager

The Swift Package Manager is a tool for automating the distribution of swift code and is integrated into the swift compiler.

Once you have your Swift package set up (ex: with [this guide](https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app)), adding SwiftReactor as a dependency is as easy as adding it to the dependencies value of your `Package.swift`.

```swift
dependencies: [
    .package(url: "https://github.com/julianpomper/SwiftReactor.git", from: "2.0.0")
]
```

### Manually

If you prefer not to use any of the aforementioned dependency managers, you can integrate it into your project manually.


## Requirements

* Swift 5.1
* iOS 13
* watchOS 6
* tvOS 13
* macOS 10.15


## License

SwiftReactor is released under the MIT license. [See LICENSE](https://github.com/julianpomper/SwiftReactor/blob/master/LICENSE) for details.
