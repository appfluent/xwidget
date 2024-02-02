# Model

*Add documentation here.*

```dart
class Topic extends Model {

  // getters
  String get key => getValue("key!");
  String get label => getValue("label!");
  String get color => getValue("color!");
  String? get rank => getValue("rank");

  // setters
  set rank(String? rank) => setValue("rank", rank);
  
  Topic._(Map<String, dynamic> data): super(data, false);

  // Factory constructor for creating or retrieving managed instances.
  factory Topic(Map<String, dynamic> data) {
    return Model.keyedInstance<Topic>(data["key"], () => Topic._(data));
  }
}
```

## Null Safety

*Add documentation here.*

### `!`

### `?`

## Instance Management

*Add documentation here.*

### `singleInstance`

*Add documentation here.*

### `keyedInstance`

*Add documentation here.*

### `hasInstance`

*Add documentation here.*

### `clearInstances`

*Add documentation here.*