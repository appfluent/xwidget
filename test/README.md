# Running Tests

## Dart Tests

All tests under 'bin' must run as Dart tests, not Flutter tests, otherwise they will fail with 
the following error:

```logcatfilter
Unsupported operation: Isolate.packageConfig
```

This is because the code generator uses classes and methods not supported in at runtime.

```shell
$ dart test test/bin
```

## Flutter Tests

```shell
$ flutter test test/lib
```
