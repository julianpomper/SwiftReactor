# SwiftUIReactor

A protocol which should help to structure your data flow in SwiftUI (and UIKit).

Inspired by [@devxoul](https://github.com/devxoul)´s [ReactorKit](https://www.github.com/ReactorKit/ReactorKit).

Special thanks to [@oanhof](https://github.com/oanhof) for contributing.

## Concept

This protocol helps to structure and maintain the ReactorKit architecture in your SwiftUI or UIKit (with Combine) project.
I highly encourage you to read the concept of this architecture in the ReactorKit´s [README.md](https://github.com/ReactorKit/ReactorKit#basic-concept)

## Usage

<!-- TODO: update the url if published -->
To see the SwiftUIReactor in action, clone this repository and try the [example project](https://github.com/julianpomper/SwiftUIReactor/tree/refactoring/SwiftUIReactorExample)

### Reactor

For a basic setup just:

1. inherit from the `BaseReactor` class
2. define your `Action`s, `Mutation`s and your `State`
3. implement the `mutate(action: Action)` and `reduce(state: State, mutation: Mutation)` method

and you are ready to go.

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

### Reactor Nesting

<details>
<summary>Click here to expand</summary>

It is also possible to split your logic into different reactors but also ensure a single source of truth by nesting reactors in your states.
In this case you have to trigger  `objectWillChange` in the reactor manually.

```swift
    public init() {
        // The parent reactor is not being notified about changes if the state contains a reference type.
        // An `ObservableObject` conforms to `AnyObject` so it cannot be a value type (struct)
        // For this reason you have to trigger the changes yourself, if you want a nested reactor
        state.subReactor
            .objectWillChange
            .sink(receiveValue: { [unowned self] _ in
                self.objectWillChange.send()
            })
            .store(in: &cancellables)
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
    
This is the implementation of the `BaseReactor`:
    
```swift
    /// A base class that can be used to simplify
    /// the implementation of the `Reactor` protocol.
    ///
    /// It adds all necessary properties and calls the `createStateStream` function for you
    open class BaseReactor<Action, Mutation, State>: Reactor {
        
        public let action = PassthroughSubject<Action, Never>()
        
        public let mutation = PassthroughSubject<Mutation, Never>()
        
        @Published
        public var state: State
        
        public var cancellables = Set<AnyCancellable>()
        
        public init(initialState: State) {
            state = initialState
            createStateStream()
        }
        
        open func mutate(action: Action) -> Mutations<Mutation> {
            .none
        }
        
        open func reduce(state: State, mutation: Mutation) -> State {
            state
        }
        
        open func transform(action: AnyPublisher<Action, Never>) -> AnyPublisher<Action, Never> {
            action
        }
        
        open func transform(mutation: AnyPublisher<Mutation, Never>) -> AnyPublisher<Mutation, Never> {
            mutation
        }
        
        open func transform(state: AnyPublisher<State, Never>) -> AnyPublisher<State, Never> {
            state
        }
    }
```
</details>


### UKit

<details>
<summary>Click here to expand</summary>

Add UIKit Usage

</details>

## TODOs
- [ ] Improve example project
- [ ] Add more tests

## Installation

### Swift Package Manager

The Swift Package Manager is a tool for automating the distribution of swift code and is integrated into the swift compiler.

Once you have your Swift package set up (ex: with [this guide](https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app)), adding SwiftUIReactor as a dependency is as easy as adding it to the dependencies value of your `Package.swift`.

```swift
dependencies: [
    .package(url: "https://github.com/julianpomper/SwiftUIReactor.git", from: "1.0.0")
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

SwiftUIReactor is released under the MIT license. [See LICENSE](https://github.com/julianpomper/SwiftUIReactor/blob/master/LICENSE) for details.
