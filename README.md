# SwiftUIReactor

A small protocol which should help to strucuture your data flow in SwiftUI.

Heavily inspired by [@mecid](https://github.com/mecid)´s [blog](https://swiftwithmajid.com) and [@devxoul](https://github.com/devxoul)´s [ReactorKit](https://www.github.com/ReactorKit/ReactorKit).

I am sure there is a lot that can be done better, so please feel free to contribute :)


## Usage

### Basic Setup

#### Reactor

```swift
public class AppReactor: Reactor {
    
    // marked with `@Published` to recognize any changes
    @Published public var state = State()
    
    // like the DisposeBag in RxSwift, this is a collection of cancellables
    // to cancel any subscriptions on deinit
    public var cancellables: Set<AnyCancellable> = []
    
    // represents all (user) actions
    // ex.: a value of a `TextField` changes
    public enum Action {
        case nameChanged(String)
    }
    
    // represents all changes to the state
    public enum Mutation {
        case setName(String)
    }
    
    // contains the all the values that represents the view
    public struct State {
        var name = "Hans"
    }
    
    // this method takes an action and generates an AnyPubisher
    // this allows you and should be the place to do any (async) tasks like API calls
    // ex: you can set the `isLoading` value in your state before and after your API call
    // so your UI shows the correct loading state
    public func mutate(action: Action) -> AnyPublisher<Mutation, Never> {
        switch action {
        case .nameChanged(let name):
            return Just(.setName(name + "action"))
                .eraseToAnyPublisher()
        }
    }
    
    // Mutates the state baseed on the given mutation.
    // There shouldn´t be any side effects in this method.
    public func reduce(mutation: Mutation) {
        switch mutation {
        case .setName(let name):
            state.name = name
        }
    }
}
```

#### Environment Object - SceneDelegate

```swift
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    // initialize the basic `AppReactor`
    private let appReactor = AppReactor()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView:
                // set the reactor as environment object to access it everywhere in your view hierachy
                ContentView()
                    .environmentObject(appReactor)
            )
            self.window = window
            window.makeKeyAndVisible()
        }
    }

    ...
}
```

#### View

```swift
struct ContentView: View {
    // access your reactor via the `@EnvironmentObject` property wrapper
    @EnvironmentObject var store: AppReactor
    
    // you can create a bindind to your state value and action
    private var name: Binding<String> {
        store.mutate(binding: \.name) { .nameChanged($0) }
    }
    
    var body: some View {
        VStack {
            // access the value from the binding (the value from your current state)
            Text(name.wrappedValue)
            // bind your action to the changes of this textfield
            TextField("Name", text: name)
        }
    }
}
```

### Advanced

It is also possible to split your logic into different reactors but also ensure a single source of truth by nesting reactors in your states.

#### Reactor

```swift
public class AppReactor: Reactor {
    
    @Published public private(set) var state = State()
    
    public var cancellables: Set<AnyCancellable> = []
    
    public enum Action {
        case subReactor(SubReactor.Action)
    }
    
    public enum Mutation {
        case subReactor(SubReactor.Action)
    }
    
    public struct State {
        var subReactor = SubReactor()
    }
    
    public init() {
        // The parent reactor is not being notified about changes if the state contains a reference type.
        // An `ObservableObject` conforms to `AnyObject` so it cannot be a value type (struct)
        // So you have to trigger the changes yourself, if you want a nested reactor
        // TODO: bind to `objectWillChange` (not use `sink`)
        // Please feel free to solve this with a better solution ;)
        state.subReactor
            .objectWillChange
            .sink(receiveValue: { [unowned self] _ in
                self.objectWillChange.send()
            })
            .store(in: &cancellables)
    }
    
    public func mutate(action: Action) -> AnyPublisher<Mutation, Never> {
        switch action {
        case .subReactor(let action):
            return Just(.subReactor(action)).eraseToAnyPublisher()
        }
    }
    
    public func reduce(mutation: Mutation) {
        switch mutation {
        case .subReactor(let action):
            state.subReactor.action(action)
        }
    }
}
```

#### View
In the View everything remains the same except for the binding value:
```swift
    // access your reactor via the `@EnvironmentObject` property wrapper
    @EnvironmentObject var store: AppReactor

    // make sure to bind to the `SubReactor` state
    private var name: Binding<String> {
        store.mutate(binding: \.subReactor.state.name) { .subReactor(.nameChanged($0)) }
    }
```


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
