
### Generate documentation

```shell
dart run tool/markdown.dart -i doc/README.md -o README.md
```

### Publish

```shell
dart pub publish --dry-run
```

### Delete tag

```shell
git push --delete origin TAGNAME
git tag -d TAGNAME
```