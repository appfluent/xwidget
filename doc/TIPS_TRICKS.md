# Tips and Tricks

### Regenerate inflaters after upgrading Flutter

*Add documentation here.*

### Use controllers to create reusable components

*Add documentation here.*

### Specify generic types with literals when your model is mutable.

When listening for changes using `<ValueListener>` or `listenForChanges`, XWidget wraps a
`ModelValueNotifier` around the data that is being listening to. Therefore, it is important
that model collections be type agnostic i.e. `dynamic` or `Object?`. For example:

```dart
// don't do this - no types
final model = Model({
  "users": {
    "user1": { "email": "@", "phone": "0" },
    "user2": { "email": "@", "phone": "0" }
  }
});
// throws exception
final user1Notifier = model.listenForChanges("users.user1", null, null);
```
This throws `type 'ModelValueNotifier' is not a subtype of type 'Map<String, String>' of 'value'`.
To fix this, explicitly specify the Map's `key` and `value` types:

```dart
// this is ok - explicitly typed maps
final model = Model({
  "users": <String, dynamic>{
    "user1": <String, dynamic>{ "email": "@", "phone": "0" },
    "user2": <String, dynamic>{ "email": "@", "phone": "0" }
  }
});
// this now works.
// NOTE: You typically wouldn't call `listenForChanges' directly. You would use <ValueListener> 
// in your fragment instead.
final user1Notifier = model.listenForChanges("users.user1", null, null);
```