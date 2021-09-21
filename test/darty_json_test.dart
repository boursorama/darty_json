import 'package:darty_json/darty_json.dart';
import 'package:test/test.dart';

void main() {
  group('Json', () {
    test('Json', () {
      var jsonString = """
      {
        "astring": "hello world",
        "anint": 12,
        "afloat": 12.12,
        "alist": [1, 2, 3, "hello", "world"],
        "aintlist": [1, 2, 3],
        "amapofint": {
          "yo": 1,
          "lo": 2
        },
        "amap": {
          "hello": "world",
          "yo": 10
        }
      }
    """;

      Json json = Json.fromString(jsonString);

      expect(json['astring'] is Json, true);
      expect(json['astring'].string, 'hello world');

      expect(json['anint'] is Json, true);
      expect(json['anint'].integer, 12);

      expect(json['alist'].list is List<Json>, true);
      expect(json['alist'].listValue[3].string, 'hello');

      expect(json['amap']['hello'] is Json, true);
      expect(json['amap']['hello'].string, 'world');

      expect(json['amap']['hello']['doesnexists'].rawValue, null);

      expect(json['amap']['doesnexists'].exception?.error, JsonError.notExist);
      expect(json['amap']['hello']['doesnexists'].exception?.error, JsonError.wrongType);
      expect(json['alist'][1000].exception?.error, JsonError.indexOutOfBounds);
      expect(json['alist']['hello'].exception?.error, JsonError.wrongType);

      expect((json['aintlist'].listOf<int>()?.length ?? 0) > 0, true);
      expect((json['amapofint'].mapOf<int>()?.values.length ?? 0) > 0, true);

      // Heterogeneous list/map don't work
      expect(json['alist'].listOf<int>(), null);
      expect(json['amap'].mapOf<int>(), null);
    });
  });

  test('Payload', () {
    JsonPayload json = JsonPayload();

    json['newdata'] = 'hello';

    expect(json['newdata'].string, 'hello');

    try {
      json['notallowed'] = () => "wat";
    } catch (error) {
      expect(true, true);
    }

    expect(json['notallowed'].rawValue, null);

    JsonPayload jsonFromMap = JsonPayload.fromMap(
      <String, dynamic>{
        "astring": "hello world",
        "anint": 12,
        "afloat": 12.12,
        "alist": [1, 2, 3, "hello", "world"],
        "aintlist": [1, 2, 3],
        "amapofint": {"yo": 1, "lo": 2},
        "amap": {
          "hello": "world",
          "yo": 10,
        },
        "notallowed": () => "wat",
      },
    );

    expect(jsonFromMap['astring'].string, 'hello world');
    expect(jsonFromMap['notallowed'].rawValue, null);
    expect(jsonFromMap.exception?.error, JsonError.unsupportedType);

    jsonFromMap['newkey'] = 'hello';
    expect(jsonFromMap['newkey'].string, 'hello');

    JsonPayload jsonFromList = JsonPayload.fromList(<dynamic>[1, 2, 3, 4]);

    jsonFromList[4] = 'hello';

    expect(jsonFromList[4].string, 'hello');
  });
}
