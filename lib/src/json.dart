import 'dart:convert';

/// Json error types
enum JsonError {
  /// Type is not json encodable
  unsupportedType,

  /// Out of bound access to list
  indexOutOfBounds,

  /// Unexpected type
  wrongType,

  /// Entry does not exists
  notExist,
}

/// Exceptions are never thrown, instead they are silently stored in the [Json] instance
class JsonException implements Exception {
  /// What error is this
  final JsonError error;

  /// Error message
  late final String reason;

  JsonException(this.error, {String? userReason}) {
    if (error == JsonError.unsupportedType) {
      reason = userReason ?? 'JSON Error: not a valid JSON value';
    } else if (error == JsonError.indexOutOfBounds) {
      reason = userReason ?? 'JSON Error: index out of bounds';
    } else if (error == JsonError.wrongType) {
      reason = userReason ?? 'JSON Error: either key is not a index type or value is not indexable';
    } else if (error == JsonError.notExist) {
      reason = userReason ?? 'JSON Error: key does\'t not exists';
    }
  }
}

/// Wraps Json decoded data
class Json {
  static const decoder = JsonDecoder();

  dynamic _rawValue;

  /// Actual value
  dynamic get rawValue => _rawValue;

  /// Exceptions are never thrown, instead they are silently stored in the [Json] instance
  JsonException? exception;

  /// Empty [Json]
  Json() : _rawValue = <String, dynamic>{};

  /// Decodes the string with [JsonDecoder] and wraps it with [Json]
  Json.fromString(String json) : _rawValue = Json.decoder.convert(json);

  /// Create a [Json] instance from any value
  Json.fromDynamic(this._rawValue, {bool initial = true}) {
    if (!initial) {
      // Type checking has already been done
      return;
    }

    if (_rawValue is Map) {
      Map<String, dynamic> map = _rawValue as Map<String, dynamic>;

      _rawValue = <String, dynamic>{};

      try {
        map.forEach((String key, dynamic value) => _set(key, value));
      } on JsonException catch (error) {
        exception = exception ?? error;
      }
    } else if (_rawValue is List) {
      List<dynamic> list = _rawValue as List<dynamic>;

      _rawValue = <dynamic>[];

      try {
        int i = 0;
        for (var item in list) {
          _set(i++, item);
        }
      } on JsonException catch (error) {
        exception = exception ?? error;
      }
    } else if (_rawValue is! int &&
        _rawValue is! double &&
        _rawValue is! String &&
        _rawValue != null &&
        _rawValue is! bool) {
      exception = exception ?? JsonException(JsonError.unsupportedType);
      _rawValue = null;
    }
  }

  /// Create [Json] from a [Map]
  Json.fromMap(Map<String, dynamic> map, {bool initial = true}) {
    if (!initial) {
      _rawValue = map;
      return;
    }

    _rawValue = <String, dynamic>{};

    try {
      map.forEach((String key, dynamic value) => _set(key, value));
    } on JsonException catch (error) {
      exception = exception ?? error;
    }
  }

  /// Create [Json] from a [List]
  Json.fromList(List<dynamic> list, {bool initial = true}) {
    _rawValue = <dynamic>[];

    try {
      int i = 0;
      for (var item in list) {
        _set(i++, item);
      }
    } on JsonException catch (error) {
      exception = exception ?? error;
    }
  }

  /// Create [Json] from another
  Json.from(Json other, {bool initial = true}) {
    if (!initial) {
      _rawValue = other._rawValue;
      return;
    }

    if (other._rawValue is int ||
        other._rawValue is double ||
        other._rawValue is bool ||
        other._rawValue is String ||
        other._rawValue == null) {
      _rawValue = other._rawValue;
    } else if (other._rawValue is Map) {
      _rawValue = Map<String, dynamic>.from(other._rawValue as Map);
    } else if (other._rawValue is List) {
      _rawValue = List<dynamic>.from(other._rawValue as List);
    } else {
      assert(false);
    }
    exception = other.exception;
  }

  /// Create a [Json] with a [null] [rawValue]
  Json get jsonNull => Json.fromDynamic(null);

  /// Returns actual Json
  @override
  String toString() => jsonEncode(_rawValue);

  dynamic toJson() {
    return (_rawValue is Json) ? _rawValue.toJson() : _rawValue;
  }

  void _set(dynamic key, dynamic value) {
    // If not a json encodable type fail
    if (value is! String &&
        value is! int &&
        value is! double &&
        value is! bool &&
        value is! List &&
        value is! Map &&
        value != null) {
      throw JsonException(JsonError.unsupportedType);
    }

    if (_rawValue is List) {
      List rawList = _rawValue as List;
      late int index;

      if (key is String) {
        try {
          index = int.parse(key);
        } catch (_) {
          throw JsonException(
            JsonError.wrongType,
            userReason: 'JSON Error: index must be int, ${key.runtimeType} given',
          );
        }
      } else {
        index = key as int;
      }

      if (index < 0 || index > rawList.length) {
        throw JsonException(
          JsonError.indexOutOfBounds,
          userReason: 'JSON Error: index `$index` is out of bounds',
        );
      } else if (index == rawList.length) {
        rawList.add(value);
      } else {
        _rawValue[index] = value;
      }
    } else if (_rawValue is Map) {
      Map rawMap = _rawValue as Map;
      late String index;

      if (key is String) {
        index = key;
      } else {
        index = '$key';
      }

      rawMap[index] = value;
    }
  }

  /// Returns a [Json] wrapping the data under [key]. If [key] does not exist, returns a empty [Json] instance with an [exception]
  Json operator [](dynamic key) {
    if ((key is! String && key is! int) || (_rawValue is! List && _rawValue is! Map)) {
      var result = jsonNull;
      result.exception = exception ?? JsonException(JsonError.wrongType);
      return result;
    }

    if (_rawValue is List) {
      List rawList = _rawValue as List;
      late int index;

      if (key is String) {
        try {
          index = int.parse(key);
        } catch (_) {
          var result = jsonNull;
          result.exception = exception ??
              JsonException(JsonError.wrongType, userReason: 'JSON Error: index must be int, ${key.runtimeType} given');
          return result;
        }
      } else {
        index = key as int;
      }

      if (index < 0 || index >= rawList.length) {
        var result = jsonNull;
        result.exception = exception ??
            JsonException(JsonError.indexOutOfBounds, userReason: 'JSON Error: index `$index` is out of bounds');
        return result;
      }

      return Json.fromDynamic(rawList[index], initial: false);
    } else if (_rawValue is Map) {
      Map rawMap = _rawValue as Map;
      late String index;

      if (key is String) {
        index = key;
      } else {
        index = '$key';
      }

      var result = Json.fromDynamic(rawMap[index], initial: false);

      if (!rawMap.containsKey(index)) {
        result.exception =
            exception ?? JsonException(JsonError.notExist, userReason: 'JSON Error: key `$index` does not exists');
      }

      return result;
    }

    // Unreachable
    assert(false, 'Should be unreachable');

    return jsonNull;
  }

  /// Returns [true] if [exception] is [null]
  bool exists([dynamic key]) {
    return key != null
        ? this[key].exception == null && this[key].rawValue != null
        : exception == null && rawValue != null;
  }

  /// Returns a [String] or [null] if [rawValue] is not a [String]
  String? get string => (_rawValue is String) ? _rawValue as String : null;

  /// Returns a [String] or an empty [String] if [rawValue] is not a [String]
  String get stringValue {
    if (_rawValue is String) {
      return _rawValue as String;
    } else if (_rawValue is bool || _rawValue is int || _rawValue is double) {
      return '$_rawValue';
    }

    return '';
  }

  /// Returns a [bool] or [null] if [rawValue] is not a [bool]
  bool? get boolean => (_rawValue is bool) ? _rawValue as bool : null;

  /// Returns a [bool] or [false] if [rawValue] is not thruthy
  bool get booleanValue {
    if (_rawValue is bool) {
      return _rawValue as bool;
    } else if (_rawValue is int || _rawValue is double) {
      return _rawValue == 1;
    } else if (_rawValue is String) {
      return ['true', 'y', 't', 'yes', '1'].contains((_rawValue as String).toLowerCase());
    }

    return false;
  }

  /// Returns a [int] or [null] if [rawValue] is not a [int]
  int? get integer => (_rawValue is int) ? _rawValue as int : null;

  /// Returns a [int] or 0 if [rawValue] is not a [int]
  int get integerValue {
    if (_rawValue is int) {
      return _rawValue as int;
    } else if (_rawValue is bool) {
      return _rawValue as bool ? 1 : 0;
    } else if (_rawValue is double) {
      return (_rawValue as double).toInt();
    } else if (_rawValue is String) {
      try {
        return int.parse(_rawValue as String);
      } catch (error) {
        return 0;
      }
    }

    return 0;
  }

  double? get float => (_rawValue is num) ? (_rawValue as num).toDouble() : null;

  /// Returns a [double] 0 if [rawValue] is not a [double]
  double get floatValue {
    if (_rawValue is double) {
      return _rawValue as double;
    } else if (_rawValue is int) {
      return (_rawValue as int).toDouble();
    } else if (_rawValue is bool) {
      return _rawValue as bool ? 1 : 0;
    } else if (_rawValue is String) {
      try {
        return double.parse(_rawValue as String);
      } catch (error) {
        return 0;
      }
    }

    return 0;
  }

  /// Returns a [T] or [null] if [rawValue] is not a [T]
  /// If actual data is not [T], calls [builder] to get one
  T? ofType<T>([T? Function(dynamic)? builder]) {
    if (_rawValue is T) {
      return _rawValue as T;
    } else if (builder != null) {
      return builder(_rawValue);
    }

    return null;
  }

  /// Returns a [T] or [defaultValue] if [rawValue] is not a [T]
  /// If actual data is not [T], calls [builder] to get one
  T ofTypeValue<T>(T defaultValue, [T? Function(dynamic)? builder]) {
    if (_rawValue is T) {
      return _rawValue as T;
    } else if (builder != null) {
      T? built = builder(_rawValue);

      if (built != null) {
        return built;
      }
    }

    return defaultValue;
  }

  /// Returns a [List] or [null] if [rawValue] is not a [List]
  /// Each element of the list is wrapped in a [Json] instance
  List<Json>? get list =>
      (_rawValue is List) ? (_rawValue as List).map<Json>((dynamic e) => Json.fromDynamic(e)).toList() : null;

  /// Returns a [List] or an empty [List] if [rawValue] is not a [List]
  /// Each element of the list is wrapped in a [Json] instance
  List<Json> get listValue =>
      (_rawValue is List) ? (_rawValue as List).map<Json>((dynamic e) => Json.fromDynamic(e)).toList() : [];

  /// Returns a [List] or [null] if [rawValue] is not a [List]
  /// Leaves list items untouched
  List? get listObject => (_rawValue is List) ? _rawValue as List : null;

  /// Returns a [List] or an empty [List] if [rawValue] is not a [List]
  /// Leaves list items untouched
  List get listObjectValue => (_rawValue is List) ? _rawValue as List : <dynamic>[];

  /// Returns a [List] of [T] or empty list if [rawValue] is not a [List] of [T]
  /// If actual data is not a [List] of [T], calls [builder] to get one
  List<T>? listOf<T>([T? Function(dynamic)? builder]) {
    if (_rawValue is List) {
      try {
        return (_rawValue as List).map<T>((dynamic e) {
          if (e is T) {
            return e;
          } else if (builder != null) {
            T? built = builder(e);

            if (built != null) {
              return built;
            }
          }

          exception = exception ??
              JsonException(JsonError.wrongType, userReason: 'JSON Error: at least one element is not of type `$T`');

          throw exception!;
        }).toList();
      } on JsonException catch (_) {
        return null;
      }
    }

    return null;
  }

  /// Returns a [List] of [T] or an empty [List] if [rawValue] is not a [List] of [T]
  /// If actual data is not a [List] of [T], calls [builder] to get one
  List<T> listOfValue<T>([T? Function(dynamic)? builder]) {
    return listOf<T>(builder) ?? [];
  }

  /// Returns a [Map] or [null] if [rawValue] is not a [Map]
  /// Each value of the map is wrapped in a [Json]
  Map<String, Json>? get map => (_rawValue is Map)
      ? (_rawValue as Map).map<String, Json>((dynamic key, dynamic value) => MapEntry('$key', Json.fromDynamic(value)))
      : null;

  /// Returns a [Map] or an empty [Map] if [rawValue] is not a [Map]
  /// Each value of the map is wrapped in a [Json]
  Map<String, Json> get mapValue => (_rawValue is Map)
      ? (_rawValue as Map).map<String, Json>((dynamic key, dynamic value) => MapEntry('$key', Json.fromDynamic(value)))
      : {};

  /// Returns a [Map] or [null] if [rawValue] is not a [Map]
  /// Leaves map values untouched
  Map<String, dynamic>? get mapObject => (_rawValue is Map) ? _rawValue as Map<String, dynamic> : null;

  /// Returns a [Map] of [T] or empty [Map] if [rawValue] is not a [Map] of [T]
  /// Leaves map values untouched
  Map<String, dynamic> get mapObjectValue =>
      (_rawValue is Map) ? _rawValue as Map<String, dynamic> : <String, dynamic>{};

  /// Returns a [Map] of [T] or [null] if [rawValue] is not a [Map] of [T]
  /// If actual data is not a [Map] of [T], calls [builder] to get one
  Map<String, T>? mapOf<T>([T? Function(dynamic)? builder]) {
    if (_rawValue is Map) {
      try {
        return (_rawValue as Map).map<String, T>((dynamic key, dynamic value) {
          if (key is! String) {
            exception = exception ?? JsonException(JsonError.wrongType, userReason: 'JSON Error: key must be a String');

            throw exception!;
          } else if (value is T) {
            return MapEntry<String, T>(key, value);
          } else if (builder != null) {
            T? built = builder(value);

            if (built != null) {
              return MapEntry<String, T>(key, built);
            }
          }

          exception = exception ??
              JsonException(JsonError.wrongType, userReason: 'JSON Error: at least one element is not of type `$T`');

          throw exception!;
        });
      } on JsonException catch (_) {
        return null;
      }
    }

    return null;
  }

  /// Returns a [List] of [T] or empty [Map] if [rawValue] is not a [List] of [T]
  /// If actual data is not a [List] of [T], calls [builder] to get one
  Map<String, T>? mapOfValue<T>() {
    return mapOf<T>() ?? {};
  }
}

/// A mutable Json payload that enforce it'll always be able to json encode it's content
class JsonPayload extends Json {
  JsonPayload() : super();
  JsonPayload.fromString(String json) : super.fromString(json);
  JsonPayload.fromDynamic(dynamic rawValue, {bool initial = true}) : super.fromDynamic(rawValue, initial: initial);
  JsonPayload.fromMap(Map<String, dynamic> map, {bool initial = true}) : super.fromMap(map, initial: initial);
  JsonPayload.fromList(List<dynamic> list, {bool initial = true}) : super.fromList(list, initial: initial);
  JsonPayload.from(Json other, {bool initial = true}) : super.from(other, initial: initial);

  set rawValue(dynamic newValue) {
    _rawValue = newValue;
  }

  void operator []=(dynamic key, dynamic value) {
    _set(key, value);
  }

  @override
  JsonPayload get jsonNull => JsonPayload.fromDynamic(null);

  @override
  JsonPayload operator [](dynamic key) => JsonPayload.from(super[key], initial: false);

  @override
  List<JsonPayload>? get list => (_rawValue is List)
      ? (_rawValue as List).map<JsonPayload>((dynamic e) => JsonPayload.fromDynamic(e)).toList()
      : null;

  @override
  List<JsonPayload> get listValue => (_rawValue is List)
      ? (_rawValue as List).map<JsonPayload>((dynamic e) => JsonPayload.fromDynamic(e)).toList()
      : [];
  @override
  Map<String, JsonPayload>? get map => (_rawValue is Map)
      ? (_rawValue as Map)
          .map<String, JsonPayload>((dynamic key, dynamic value) => MapEntry('$key', JsonPayload.fromDynamic(value)))
      : null;

  @override
  Map<String, JsonPayload> get mapValue => (_rawValue is Map)
      ? (_rawValue as Map)
          .map<String, JsonPayload>((dynamic key, dynamic value) => MapEntry('$key', JsonPayload.fromDynamic(value)))
      : {};

  /// Remove element under [key]
  void removeElementWithKey(dynamic key) {
    if (_rawValue is List) {
      List rawList = _rawValue as List;
      late int index;

      if (key is String) {
        try {
          index = int.parse(key);
        } catch (_) {
          throw JsonException(
            JsonError.wrongType,
            userReason: 'JSON Error: index must be int, ${key.runtimeType} given',
          );
        }
      } else {
        index = key as int;
      }

      rawList.removeAt(index);
    } else if (_rawValue is Map) {
      Map rawMap = _rawValue as Map;
      late String index;

      if (key is String) {
        index = key;
      } else {
        index = '$key';
      }

      rawMap.remove(index);
    } else {
      throw throw JsonException(
        JsonError.wrongType,
        userReason: '_rawValue is not a List or a Map',
      );
    }
  }
}
