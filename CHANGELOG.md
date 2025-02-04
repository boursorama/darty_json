# 2.0.0

- If a element of map of a list is not JSON serializable it'll be ignore but the subsequence elements will be added to the resulting `Json`
- `Json` and `JsonPayload` equal operator override to handle comparison by instance or by value

## Breaking changes
- `ofType`, `listOf` and `mapOf` will wrap the element in a `Json` when calling `builder` instead of the raw value
- When expecting a single type when raw value is heterogeneous list and maps, matching type element will remain and the rest will be discarded instead of returning empty list/map

# 1.0.4

- `Json` and `JsonPayload` are json encodable, meaning they can be use with `darat:convert jsonEncode`

# 1.0.3

- Fixed `JsonPayload` nested assignment

# 1.0.2

- Fixed `JsonPayload` nested assignment

# 1.0.1

- `.float` returns a value when actual value is an integer

# 1.0.0

- Initial version.
