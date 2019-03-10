---
title: Decoding Array Gracefully
categories: [ios]
excerpt: todo
---

Since the introduction of `Codable`, transforming APIs into data models has been a blessing. All you need is a simple conformance to the `Decodable` protocol, and let Swift do its magic.

But sometimes, you need more control. Quickly, you end up declaring your coding keys and overriding the default implementation of `init(from: Decoder)`, to state your own business logic.

Eventually you'll get exactly what you want. Well, *almost* exactly.

## The issue

Let's say you want to display a list of item, retrieved from an API.

```swift
enum Planet: String, Decodable {
  case mercury, venus, earth, mars, jupiter, saturn, uranus, neptune
}

class SolarSystem: Decodable {
    let planets: [Planet]

    enum CodingKeys: String, CodingKey {
        case planets
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.planets = try container.decode([Planet].self, forKey: .planets)
    }
}

let json = """
    [
        {
            "planets": ["mercury", "mars", "saturn"]
        },
        {
            "planets": ["mercury", "mars", "saturn", "pluto"]
        }
    ]
    """
let jsonData = json.data(using: .utf8)!

do {
    let solarSystems = try JSONDecoder().decode([SolarSystem].self, from: jsonData)
} catch let error {
    dump(error)
}
```

A naive data model and a quick JSON mock. A `SolarSystem` with a list of `Planet`. The JSON data contains a list of `SolarSystem`.

Executing this code will throw a `DecodingError.dataCorrupted`, with the following, rather explicit, debug description : `Cannot initialize Planet from invalid String value pluto`.

And this is where the problem lies. You can't be sure the data will be valid.

`Decodable` provides a great way to handle that when the data is a simple object, thanks to optional. But it does not provides one when the data is a list. You either get a full list of items, or an error, if any of the item does not conform to the item's data model.

**What if we want something in between? The list of *valid* items, the items that conform to the data model?**

We need to build a fault tolerant system, one that will allow lossy decoding of array elements.

## The idea

The way `Decodale`works when processing a collection is simple : it will throw as soon as one of the children's collection throws. In our example, `Decodable` only throws at the very end, and all the data process before is *throw* away. A fail strategy.

Our first step is to define new strategies. We start simple: either we remove the faulty element, or we apply the standard behavior and fail. 

We then need to use the choosen strategy to apply when encountering an invalid element while decoding.

We'll use a generic enum to represent it.

```swift
enum InvalidElementStrategy<T> {
    case remove
    case fail

    func decodeItem(decode: () throws -> T) throws -> T? {
        do {
            return try decode()
        } catch {
            switch self {
            case .remove:
                return nil
            case .fail:
                throw error
            }
        }
    }
}
```

The second step 

a way to use a choosen strategy to apply when encountering an invalid element while decoding. Two possible state: .

Now, we wish to apply the strategy when processing a collection. To do this, we have to create a new method in `KeyedDecodingContainer`.

The method have the same signature as the standard with an additional parameter, our strategy. By default, the strategy is the standard one, throw an error.

The job is then as stated. We iterate over the container, try to decode our object, using our strategy :

- if we have an element, we keep it, and we continue looping over the container
- if we don't have an element
  - and the strategy is removing : nothing happen, we continue looping over the container
  - and the strategy is failing : we throw, as usual, and the decoding stop

````swift
extension KeyedDecodingContainer {

    private struct EmptyDecodable: Decodable {}

    public func decode<T: Decodable>(_ type: [T].Type,
                                     forKey key: KeyedDecodingContainer<K>.Key,
                                     invalidElementStrategy: InvalidElementStrategy<T> = .fail) throws -> [T] {

        var container = try nestedUnkeyedContainer(forKey: key)
        var array: [T] = []

        while !container.isAtEnd {
            let element: T? = try invalidElementStrategy.decodeItem(decode: { try container.decode(T.self) })
            if let element = element {
                array.append(element)
            } else {
                // hack to advance the index
                _ = try? container.decode(EmptyDecodable.self)
            }
        }
        return array
    }
}
````

I love the fact that if all of your objects are corrupted and you choose the remove strategy, you'll get an empty array and not an error. 

Updating our example code, and we have a rather simple fault tolerant decoding system.

```swift
self.planets = try container.decode([Planet].self, forKey: .planets, invalidElementStrategy: .remove)
```

## Next step

This solution works great when using a wrapper object, like the `SolarSystem`. Not with a plain object like `Planet`.

```swift
let json = """
["mercury", "mars", "saturn", "pluto"]
"""
let jsonData = json.data(using: .utf8)!

do {
    let planets = try JSONDecoder().decode([Planet].self, from: jsonData)
} catch let error {
    dump(error)
}
```

Executing this code will throw the exact same error that before.

Same as before we would need to create a new method, in `JSONDecoder` this time, to have something like this :

```swift
func decode<T>(_ type: [T].Type, from data: Data, invalidElementStrategy: InvalidElementStrategy<T> = .fail) throws -> [T] where T : Decodable
```

Unfortunately, we hit the limit of our possibilities. In order to decode the `Data` we would need access to the internal `_JSONDecoder` type, which is.. internal. Without it, we cannot do more, unless rewritting our own `JSONDecoder`.

If you wish to know more about this, Greg Heo wrote a full article on how JSONDecoder works internally.
{: .notice--info}

## What you can do

Since September 2017, an issue about this subject is opened on the Swift bug tracker, [SR-5953](https://bugs.swift.org/browse/SR-5953). 

Unfortunately, not much has been made since. So, if this issue is important to you, go upvote and comment!