# darty_json

<!-- [![pub](https://img.shields.io/pub/v/darty_json?label=version&style=flat-square)](https://pub.dev/packages/darty_json)
[![pub points](https://badges.bar/darty_json/pub%20points)](https://pub.dev/packages/darty_json/score)
[![popularity](https://badges.bar/darty_json/popularity)](https://pub.dev/packages/darty_json/score)
[![likes](https://badges.bar/darty_json/likes)](https://pub.dev/packages/darty_json/score) -->

🚚 A safe and elegant way to deal with Json data inspired by [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON)

## What is it?

Safely interact with Json data by requiring the user to specify what type of data they want to extract.

```dart
Json json = Json.fromString(jsonString);

json['someKey'].string;      // Gets the data under `someKey`, if a string returns it otherwise return null
json['someKey'].stringValue; // Same but provides default string if `someKey` does not exists or is not a string

json['alist'].list; // Returns a list, each item is wrapped in a Json instance
json['amap'].map;   // Returns a map, each value is wrapped in a Json instance

json['you']['can']['chain'].string; // This enables to chain subscript access to a Json instance

json['listofint'].listOf<int>(); // Returns a list of `int`, if any element of the list is not an `int`, returns null
```