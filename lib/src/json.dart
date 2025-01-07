import 'dart:convert';

typedef Any = Object?;

/// Wraps Json decoded data
class Json {
  static const decoder = JsonDecoder();

  Any _rawValue;

  /// Actual value
  Any get rawValue => _rawValue;

  /// Exceptions are never thrown, instead they are silently stored in the [Json] instance
  JsonException? exception;

  /// Empty [Json]
  Json() : _rawValue = <String, Any>{};

  /// Decodes the string with [JsonDecoder] and wraps it with [Json]
  Json.fromString(String json) : _rawValue = Json.decoder.convert(json);

  /// Create a [Json] instance from any value
  Json.fromDynamic(this._rawValue, {bool initial = true}) {
    if (!initial) {
      // Type checking has already been done
      return;
    }

    final asMap = tryCast<Map<String, Any>>(_rawValue);
    final asIterable = tryCast<Iterable>(_rawValue);

    if (asMap != null) {
      _rawValue = <String, Any>{};
      try {
        asMap.forEach((String key, Any value) => _set(key, value));
      } on JsonException catch (error) {
        exception = exception ?? error;
      }
    } else if (asIterable != null) {
      _rawValue = <Any>[];
      try {
        int i = 0;
        for (var item in asIterable) {
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
  Json.fromMap(Map<String, Any> map, {bool initial = true}) {
    if (!initial) {
      _rawValue = map;
      return;
    }

    _rawValue = <String, Any>{};

    try {
      map.forEach((String key, Any value) => _set(key, value));
    } on JsonException catch (error) {
      exception = exception ?? error;
    }
  }

  /// Create [Json] from a [List]
  Json.fromList(List<Any> list, {bool initial = true}) {
    _rawValue = <Any>[];

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
      _rawValue = Map<String, Any>.from(other._rawValue as Map);
    } else if (other._rawValue is List) {
      _rawValue = List<Any>.from(other._rawValue as List);
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

  Any toJson() {
    return tryCast<Json>(_rawValue)?.toJson() ?? _rawValue;
  }

  /// Compare [Json] by instance or by value
  @override
  bool operator ==(Object other) => identical(this, other) || other is Json && toString() == other.toString();

  @override
  int get hashCode => toString().hashCode;

  void _set(Any key, Any value) {
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

    if (key == null) return;

    final rawMap = tryCast<Map>(_rawValue);
    final rawList = tryCast<List>(_rawValue);
    if (rawList != null) {
      int? index = (key is String) ? int.tryParse(key) : tryCast<int>(key);
      if (index == null) {
        throw JsonException(
          JsonError.wrongType,
          userReason: 'JSON Error: index must be int, ${key.runtimeType} given',
        );
      }

      if (index < 0 || index > rawList.length) {
        throw JsonException(
          JsonError.indexOutOfBounds,
          userReason: 'JSON Error: index `$index` is out of bounds',
        );
      } else if (index == rawList.length) {
        rawList.add(value);
      } else {
        rawList[index] = value;
      }
    } else if (rawMap != null) {
      rawMap[key.toString()] = value;
    }
  }

  /// Returns a [Json] wrapping the data under [key]. If [key] does not exist, returns a empty [Json] instance with an [exception]
  Json operator [](Object key) {
    if ((key is! String && key is! int) || (_rawValue is! List && _rawValue is! Map)) {
      var result = jsonNull;
      result.exception = exception ?? JsonException(JsonError.wrongType);
      return result;
    }

    final rawList = tryCast<List>(_rawValue);
    final rawMap = tryCast<Map>(_rawValue);

    if (rawList != null) {
      int? index = key is String ? int.tryParse(key) : tryCast<int>(key);

      if (index == null) {
        var result = jsonNull;
        result.exception = exception ??
            JsonException(
              JsonError.wrongType,
              userReason: 'JSON Error: index must be int, ${key.runtimeType} given',
            );
        return result;
      }

      if (index < 0 || index >= rawList.length) {
        var result = jsonNull;
        result.exception = exception ??
            JsonException(
              JsonError.indexOutOfBounds,
              userReason: 'JSON Error: index `$index` is out of bounds',
            );
        return result;
      }

      return Json.fromDynamic(rawList.elementAtOrNull(index), initial: false);
    } else if (rawMap != null) {
      final index = key.toString();
      final result = Json.fromDynamic(rawMap[index], initial: false);
      if (!rawMap.containsKey(index)) {
        result.exception = exception ??
            JsonException(
              JsonError.notExist,
              userReason: 'JSON Error: key `$index` does not exists',
            );
      }

      return result;
    }

    // Unreachable
    assert(false, 'Should be unreachable');

    return jsonNull;
  }

  /// Returns [true] if [exception] is [null]
  bool exists([Any key]) {
    return key != null
        ? this[key].exception == null && this[key].rawValue != null
        : exception == null && rawValue != null;
  }

  /// Returns a [String] or [null] if [rawValue] is not a [String]
  String? get string => (_rawValue is String) ? _rawValue as String : null;

  /// Returns a [String] or an empty [String] if [rawValue] is not a [String]
  String get stringValue => switch (_rawValue) {
        const (String) || const (bool) || const (int) || const (double) => _rawValue?.toString() ?? '',
        _ => '',
      };

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
  T? ofType<T>([T? Function(Any)? builder]) {
    if (_rawValue is T) {
      return _rawValue as T;
    } else if (builder != null) {
      return builder(_rawValue);
    }

    return null;
  }

  /// Returns a [T] or [defaultValue] if [rawValue] is not a [T]
  /// If actual data is not [T], calls [builder] to get one
  T ofTypeValue<T>(T defaultValue, [T? Function(Any)? builder]) {
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
      (_rawValue is List) ? (_rawValue as List).map<Json>((Any e) => Json.fromDynamic(e)).toList() : null;

  /// Returns a [List] or an empty [List] if [rawValue] is not a [List]
  /// Each element of the list is wrapped in a [Json] instance
  List<Json> get listValue =>
      (_rawValue is List) ? (_rawValue as List).map<Json>((Any e) => Json.fromDynamic(e)).toList() : [];

  /// Returns a [List] or [null] if [rawValue] is not a [List]
  /// Leaves list items untouched
  List? get listObject => (_rawValue is List) ? _rawValue as List : null;

  /// Returns a [List] or an empty [List] if [rawValue] is not a [List]
  /// Leaves list items untouched
  List get listObjectValue => (_rawValue is List) ? _rawValue as List : <Any>[];

  /// Returns a [List] of [T] or empty list if [rawValue] is not a [List] of [T]
  /// If actual data is not a [List] of [T], calls [builder] to get one
  List<T>? listOf<T>([T? Function(Any)? builder]) {
    if (_rawValue is List) {
      try {
        return (_rawValue as List).map<T>((Any e) {
          if (e is T) {
            return e;
          } else if (builder != null) {
            T? built = builder(e);

            if (built != null) {
              return built;
            }
          }

          exception = exception ??
              JsonException(
                JsonError.wrongType,
                userReason: 'JSON Error: at least one element is not of type `$T`',
              );

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
  List<T> listOfValue<T>([T? Function(Any)? builder]) {
    return listOf(builder) ?? [];
  }

  /// Returns a [Map] or [null] if [rawValue] is not a [Map]
  /// Each value of the map is wrapped in a [Json]
  Map<String, Json>? get map => (_rawValue is Map)
      ? (_rawValue as Map).map((Any key, Any value) => MapEntry('$key', Json.fromDynamic(value)))
      : null;

  /// Returns a [Map] or an empty [Map] if [rawValue] is not a [Map]
  /// Each value of the map is wrapped in a [Json]
  Map<String, Json> get mapValue => (_rawValue is Map)
      ? (_rawValue as Map).map((Any key, Any value) => MapEntry('$key', Json.fromDynamic(value)))
      : {};

  /// Returns a [Map] or [null] if [rawValue] is not a [Map]
  /// Leaves map values untouched
  Map<String, Any>? get mapObject => (_rawValue is Map) ? _rawValue as Map<String, Any> : null;

  /// Returns a [Map] of [T] or empty [Map] if [rawValue] is not a [Map] of [T]
  /// Leaves map values untouched
  Map<String, Any> get mapObjectValue => (_rawValue is Map) ? _rawValue as Map<String, Any> : {};

  /// Returns a [Map] of [T] or [null] if [rawValue] is not a [Map] of [T]
  /// If actual data is not a [Map] of [T], calls [builder] to get one
  Map<String, T>? mapOf<T>([T? Function(Any)? builder]) {
    if (_rawValue is Map) {
      try {
        return (_rawValue as Map).map((Any key, Any value) {
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
  Map<String, T> mapOfValue<T>() {
    return mapOf() ?? {};
  }
}

/// A mutable Json payload that enforce it'll always be able to json encode it's content
class JsonPayload extends Json {
  JsonPayload();
  JsonPayload.fromString(super.json) : super.fromString();
  JsonPayload.fromDynamic(super.rawValue, {super.initial}) : super.fromDynamic();
  JsonPayload.fromMap(super.map, {super.initial}) : super.fromMap();
  JsonPayload.fromList(super.list, {super.initial}) : super.fromList();
  JsonPayload.from(super.other, {super.initial}) : super.from();

  set rawValue(Any newValue) {
    _rawValue = newValue;
  }

  void operator []=(Any key, Any value) {
    _set(key, value);
  }

  @override
  JsonPayload get jsonNull => JsonPayload.fromDynamic(null);

  @override
  JsonPayload operator [](Object key) => JsonPayload.from(super[key], initial: false);

  @override
  List<JsonPayload>? get list =>
      (_rawValue is List) ? (_rawValue as List).map<JsonPayload>((Any e) => JsonPayload.fromDynamic(e)).toList() : null;

  @override
  List<JsonPayload> get listValue =>
      (_rawValue is List) ? (_rawValue as List).map<JsonPayload>((Any e) => JsonPayload.fromDynamic(e)).toList() : [];

  @override
  Map<String, JsonPayload>? get map => (_rawValue is Map)
      ? (_rawValue as Map).map((Any key, Any value) => MapEntry('$key', JsonPayload.fromDynamic(value)))
      : null;

  @override
  Map<String, JsonPayload> get mapValue => (_rawValue is Map)
      ? (_rawValue as Map).map((Any key, Any value) => MapEntry('$key', JsonPayload.fromDynamic(value)))
      : {};

  /// Remove element under [key]
  void removeElementWithKey(Any key) {
    if (_rawValue is List) {
      List rawList = _rawValue as List;
      late int index;

      if (key is String) {
        try {
          index = int.parse(key);
        } catch (_, trace) {
          Error.throwWithStackTrace(
            JsonException(
              JsonError.wrongType,
              userReason: 'JSON Error: index must be int, ${key.runtimeType} given',
            ),
            trace,
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

T? tryCast<T>(Any object) => object is T ? object : null;

/// Json error types
enum JsonError {
  /// Type is not json encodable
  unsupportedType(reason: 'JSON Error: not a valid JSON value'),

  /// Out of bound access to list
  indexOutOfBounds(reason: 'JSON Error: index out of bounds'),

  /// Unexpected type
  wrongType(reason: 'JSON Error: either key is not a index type or value is not indexable'),

  /// Entry does not exists
  notExist(reason: 'JSON Error: key does\'t not exists');

  final String reason;

  const JsonError({required this.reason});
}

/// Exceptions are never thrown, instead they are silently stored in the [Json] instance
class JsonException implements Exception {
  /// What error is this
  final JsonError error;

  /// Error message
  final String reason;

  JsonException(this.error, {String? userReason}) : reason = userReason ?? error.reason;

  @override
  String toString() => 'JsonException{error: $error, reason: $reason}';
}
