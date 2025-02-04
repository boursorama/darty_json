import 'package:darty_json/darty_json.dart';
import 'package:test/test.dart';

class Person {
  String name;
  int age;

  Person(this.name, this.age);
}

void main() {
  group('Json', () {
    test('Json', () {
      final jsonString = """
      {
        "astring": "hello world",
        "anint": 12,
        "intishstring": "12",
        "afloat": 12.12,
        "floatish": true,
        "floatishstring": "12.12",
        "alist": [1, 2, 3, "hello", "world"],
        "aintlist": [1, 2, 3],
        "amapofint": {
          "yo": 1,
          "lo": 2
        },
        "amap": {
          "hello": "world",
          "yo": 10
        },
        "aboolean": true,
        "booleanish": "y",
        "booleanishint": 1,
        "booleanishdouble": 1.0
      }
    """;

      final json = Json.fromString(jsonString);

      expect(json['astring'].string, 'hello world');

      expect(json['anint'].integer, 12);
      expect(json['anint'].integerValue, 12);
      expect(json['afloat'].integerValue, 12);
      expect(json['intishstring'].integerValue, 12);
      expect(json['floatish'].integerValue, 1);

      expect(json['afloat'].float, 12.12);
      expect(json['anint'].float, 12);
      expect(json['anint'].floatValue, 12);
      expect(json['afloat'].floatValue, 12.12);
      expect(json['floatishstring'].floatValue, 12.12);
      expect(json['floatish'].floatValue, 1);

      expect(json['alist'].list, TypeMatcher<List<Json>>());
      expect(json['alist'].listValue.elementAtOrNull(3)?.string, 'hello');
      expect(json['afloat'].listValue, isEmpty);

      expect(json['amap']['hello'].stringValue, 'world');

      expect(json['amap']['hello']['doesnexists'].rawValue, isNull);

      expect(json['amap']['doesnexists'].exception?.error, JsonError.notExist);
      expect(
        json['amap']['hello']['doesnexists'].exception?.error,
        JsonError.wrongType,
      );
      expect(json['alist'][1000].exception?.error, JsonError.indexOutOfBounds);
      expect(json['alist']['hello'].exception?.error, JsonError.wrongType);

      expect((json['aintlist'].listOf<int>()?.length ?? 0) > 0, isTrue);
      expect((json['amapofint'].mapOf<int>()?.values.length ?? 0) > 0, isTrue);

      // Heterogeneous list/map ignore non-matching elements
      expect(json['alist'].listOf<int>(), [1, 2, 3]);
      expect(json['amap'].mapOf<int>(), {'yo': 10});

      expect(json['amap'].map, isNotEmpty);
      expect(json['amap'].mapValue, isNotEmpty);
      expect(json['alist'].mapValue, isEmpty);

      expect(json['aboolean'].boolean, isTrue);
      expect(json['aboolean'].booleanValue, isTrue);
      expect(json['booleanish'].booleanValue, isTrue);
      expect(json['booleanishint'].booleanValue, isTrue);
      expect(json['booleanishdouble'].booleanValue, isTrue);
    });
  });

  test('Payload', () {
    final json = JsonPayload();

    // Empty payload is null, we can't set any key on it
    expect(() => json['newdata'] = 'hello', throwsException);
    expect(() => json.removeElementWithKey('one'), throwsException);

    json.rawValue = <String, Any>{};
    json['newdata'] = 'hello';

    expect(json['newdata'].string, 'hello');

    try {
      json['notallowed'] = () => "wat";
    } catch (error) {
      expect(true, true);
    }

    expect(json['notallowed'].rawValue, null);

    final jsonFromMap = JsonPayload.fromMap(
      <String, dynamic>{
        "astring": "hello world",
        "anint": 12,
        "afloat": 12.12,
        "alist": [1, 2, 3, "hello", "world"],
        "aintlist": [1, 2, 3],
        "amapofint": {"yo": 1, "lo": 2},
        "amap": {"hello": "world", "yo": 10},
        "notallowed": () => "wat",
        "true": true,
      },
    );

    expect(jsonFromMap.map, TypeMatcher<Map<String, JsonPayload>>());
    expect(jsonFromMap.mapValue, TypeMatcher<Map<String, JsonPayload>>());
    expect(jsonFromMap['alist'].list, TypeMatcher<List<JsonPayload>>());
    expect(jsonFromMap['alist'].listValue, TypeMatcher<List<JsonPayload>>());
    expect(jsonFromMap['astring'].string, 'hello world');
    expect(jsonFromMap['notallowed'].rawValue, null);
    expect(jsonFromMap.exception?.error, JsonError.unsupportedType);

    expect((jsonFromMap..removeElementWithKey('astring')).exists('astring'),
        isFalse);

    expect((jsonFromMap..removeElementWithKey(true)).exists('true'), isFalse);

    jsonFromMap['alist'].removeElementWithKey(0);
    expect(jsonFromMap['alist'].listValue.firstOrNull?.rawValue, 2);

    expect(
        () => jsonFromMap['alist'].removeElementWithKey(100), throwsException);
    expect(() => jsonFromMap['alist'].removeElementWithKey('nope'),
        throwsException);

    jsonFromMap['newkey'] = 'hello';
    expect(jsonFromMap['newkey'].string, 'hello');

    final jsonFromList = JsonPayload.fromList([1, 2, 3, 4]);

    jsonFromList[4] = 'hello';

    expect(jsonFromList[4].string, 'hello');
  });

  test('Nested payload modification', () {
    final jsonString = '''
  {
  "request": 
    { 
      "pathName": "yolo"
    }
  }''';

    final jsonPayload = JsonPayload.fromString(jsonString);

    jsonPayload["request"]["pathName"] = "toto";

    expect(jsonPayload["request"]["pathName"].string, "toto");
  });

  test('Expect JSON object to be jsonEncodable', () {
    final requestString = '{"pathName":"yolo"}';
    final jsonInputString = '{"request":$requestString}';

    final jsonPayload = JsonPayload.fromString(jsonInputString);

    expect(jsonPayload.toString(), jsonInputString);
    expect(jsonPayload["request"].toString(), requestString);

    jsonPayload["request"]["pathName"] = "toto";

    expect(jsonPayload["request"].toString(), '{"pathName":"toto"}');
    expect(jsonPayload["baaaaaaad"].toString(), "null");
  });

  test('Expect JSON object to be equals', () {
    final jsonPayload1 =
        JsonPayload.fromString('{"request":{"pathName":"yolo"}}');
    final jsonPayload2 =
        JsonPayload.fromString('{"request":{"pathName":"yolo"}}');
    final jsonPayload3 =
        JsonPayload.fromString('{"request":{"pathName":"yolo2"}}');

    expect(jsonPayload1, jsonPayload1);
    expect(jsonPayload1, jsonPayload2);
    expect(jsonPayload1 != jsonPayload3, isTrue);
  });

  test('fromXXX', () {
    final payload = Json.fromDynamic(
      {
        "one": 1,
        "more": [1, 2, 3],
      },
    );

    expect(payload.toString(), '{"one":1,"more":[1,2,3]}');

    final invalidPayload = Json.fromDynamic(
      {
        "one": 1,
        "invalid": Exception('invalid'),
        "more": [1, 2, 3],
      },
    );

    expect(invalidPayload.toString(), '{"one":1,"more":[1,2,3]}');
    expect(invalidPayload.exception, TypeMatcher<JsonException>());
    expect(invalidPayload.exception?.toString(),
        'JsonException{error: JsonError.unsupportedType, reason: ${JsonError.unsupportedType.reason}}');

    final listPayload = Json.fromDynamic([1, "two", false]);

    expect(listPayload.toString(), '[1,"two",false]');

    final invalidListPayload = Json.fromDynamic(
      [1, "two", Exception('invalid'), false],
    );

    expect(invalidListPayload.toString(), '[1,"two",false]');
    expect(tryCast<JsonException>(invalidListPayload.exception)?.error,
        JsonError.unsupportedType);

    expect(
      tryCast<JsonException>(Json.fromDynamic(Exception('invalid')).exception)
          ?.error,
      JsonError.unsupportedType,
    );
    expect(
      tryCast<JsonException>(Json.fromDynamic(Json.fromDynamic(true)).exception)
          ?.error,
      JsonError.unsupportedType,
    );

    final invalidList = Json.fromList([1, "two", Exception('invalid'), false]);

    expect(invalidList.toString(), '[1,"two",false]');
    expect(invalidList.exception, TypeMatcher<JsonException>());

    expect(Json.from(Json.fromDynamic(1)).toString(), '1');
    expect(Json.from(Json.fromDynamic(true)).toString(), 'true');
    expect(Json.from(Json.fromDynamic(12.42)).toString(), '12.42');
    expect(Json.from(Json.fromDynamic(null)).toString(), 'null');
    expect(Json.from(Json.fromDynamic(<String, Any>{})).toString(), '{}');
    expect(Json.from(Json.fromDynamic(<Any>[])).toString(), '[]');
  });

  test('Json == Json', () {
    expect(Json.fromDynamic([1, 2, 3]) == Json.fromDynamic([1, 2, 3]), true);

    expect(
      {
        Json.fromDynamic([1, 2, 3]): true,
      }[Json.fromDynamic([1, 2, 3])],
      true,
    );
  });

  test('list set', () {
    final list = JsonPayload.fromList([1, 2, 3]);

    expect(() => list[100] = true, throwsException);
    expect(() => list["yolo"] = true, throwsException);

    list[0] = "hello";

    expect(list[0].rawValue, "hello");

    expect(list[0].exists(), isTrue);
    expect(list[100].exists(), isFalse);
    expect(list.exists(0), isTrue);
    expect(list.exists(100), isFalse);
  });

  test('ofType', () {
    final payload = Json.fromDynamic({"name": "joe", "age": 30});

    expect(
      payload
          .ofType(
            (raw) => Person(raw['name'].stringValue, raw['age'].integerValue),
          )
          ?.name,
      'joe',
    );

    expect(payload['name'].ofType<String>(), 'joe');

    expect(
      payload
          .ofTypeValue(
            Person('default', 0),
            (raw) => Person(raw['name'].stringValue, raw['age'].integerValue),
          )
          .name,
      'joe',
    );

    expect(payload['name'].ofTypeValue<String>('default'), 'joe');
    expect(payload['age'].ofTypeValue<String>('default'), 'default');

    final listPayload = Json.fromDynamic([
      {
        "name": "joe",
        "age": 30,
      },
    ]);

    expect(
      listPayload
          .listOf(
            (raw) => Person(raw['name'].stringValue, raw['age'].integerValue),
          )?[0]
          .name,
      'joe',
    );

    expect(
      listPayload
          .listOfValue(
            (raw) => Person(raw['name'].stringValue, raw['age'].integerValue),
          )[0]
          .name,
      'joe',
    );

    final heterogenousList = Json.fromDynamic([
      {
        "name": "joe",
        "age": 30,
      },
      "something else",
      {
        "name": "doe",
        "age": 31,
      },
    ]);

    expect(
      heterogenousList
          .listOfValue(
            (raw) => Person(raw['name'].stringValue, raw['age'].integerValue),
          )[0]
          .name,
      'joe',
    );

    expect(
      heterogenousList.listOfValue(
        (raw) => raw.exists('name') && raw.exists('age')
            ? Person(raw['name'].stringValue, raw['age'].integerValue)
            : null,
      ),
      hasLength(2),
    );

    final heterogenousMap = Json.fromDynamic(
      {
        "one": {
          "name": "joe",
          "age": 30,
        },
        "two": "something else",
        "three": {
          "name": "doe",
          "age": 31,
        },
      },
    );

    expect(
      heterogenousMap
          .mapOfValue(
            (raw) => Person(raw['name'].stringValue, raw['age'].integerValue),
          )["one"]
          ?.name,
      'joe',
    );

    expect(
      heterogenousMap.mapOfValue(
        (raw) => raw.exists('name') && raw.exists('age')
            ? Person(raw['name'].stringValue, raw['age'].integerValue)
            : null,
      ),
      hasLength(2),
    );
  });

  test('listOf', () {
    expect(Json.fromList([1, 2, 3]).listObject?[0], 1);
    expect(Json.fromList([1, 2, 3]).listObjectValue[0], 1);
    expect(Json.fromDynamic(null).listObjectValue, isEmpty);
  });

  test('mapOf', () {
    expect(Json.fromMap({'one': 1}).mapObject?['one'], 1);
    expect(Json.fromMap({'one': 1}).mapObjectValue['one'], 1);
    expect(Json.fromDynamic(null).mapObjectValue, isEmpty);
  });
}
