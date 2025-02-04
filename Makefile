test_with_coverage:
	dart pub global activate coverage
	dart test test/main.dart --coverage=./build/coverage
	dart pub global run coverage:format_coverage --lcov --check-ignore  --in=./build/coverage --out=./build/lcov.info --packages=./.dart_tool/package_config.json --report-on=lib
	genhtml ./build/lcov.info --output=./build/coverage/html
