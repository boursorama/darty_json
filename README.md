# darty_json

[![pub](https://img.shields.io/pub/v/darty_json?label=version&style=flat-square)](https://pub.dev/packages/darty_json)
[![pub points](https://badges.bar/darty_json/pub%20points)](https://pub.dev/packages/darty_json/score)
[![popularity](https://badges.bar/darty_json/popularity)](https://pub.dev/packages/darty_json/score)
[![likes](https://badges.bar/darty_json/likes)](https://pub.dev/packages/darty_json/score)

🚚 A safe and elegant way to deal with Json data inspired by [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON)

## What is it?

Safely interact with Json data by requiring the user to specify what type of data they want to extract.

```dart
Json json = Json.fromString(jsonString);

// Gets the data under `someKey`, if a string returns it otherwise return null
json['someKey'].string;
// Same but provides default empty string if `someKey` does not exists or is not a string
json['someKey'].stringValue;

// Same exists for all json types
json['someKey'].boolean;
json['someKey'].booleanValue; // Will try to coerce the data to bool and returns false if couldn't
json['someKey'].float;
json['someKey'].floatValue; // Will try to coerce the data to double and returns 0 if couldn't
json['someKey'].integer;
json['someKey'].integerValue; // Will try to coerce the data to int and returns 0 if couldn't

// List items and Map values are wrapped in Json instances, which enables chaining acces to them
json['alist'].list;
json['amap'].map;

// If any path element does not exist or is not subscriptable, it'll return null
json['you']['can']['chain']['them'].string;

// Returns a list of `int`, if any element of the list is not an `int`, returns null
json['listofint'].listOf<int>();
// Same with maps
json['amapofint'].mapOf<int>();

// If you provide a builder you can get a list or map of anything
json['list'].listOf<MyType>((value) => MyType(value));

// You can do the same for a single value
json['some'].ofType<MyType>((value) => MyType(value));
// For the `value` variant you must provide a default value
json['some'].ofTypeValue<MyType>(MyType(), (value) => MyType(value));

// If you want the unaltered data you can get it with `rawValue`
json['some'].rawValue;

// If you want list and map with unaltered values
json['list'].listObject;
json['map'].mapObject;

// If you get null, you can check if its the result of an illegal access
if (json['idontexists'].exception != null) {
    print('something went wrong');
}
```

## `JsonPayload`

`JsonPayload` are `Json` instances you can modify. It'll try to enforce a json encodable payload.

```dart
JsonPayload payload = JsonPayload();

payload['newkey'] = 'somevalue';

paylaod['newkey'].string == 'someValue';
```
