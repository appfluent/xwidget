# Trouble Shooting

## The generated inflater code has errors

The most common cause of errors in generated inflater code is due to constructor argument defaults
referencing undefined variables. If the referenced variable type is not a primitive, then XWidget
can't infer how to generate the default value and will fallback to using the variable reference.

The solution is to manually set the default value for the constructor argument in XWidget's
configuration file under the `constructor_arg_defaults:` key.

```yaml
# xwidget_config.yaml
inflaters:  
  constructor_arg_defaults:
    # example defaults
    "WidgetSpan:alignment": "PlaceholderAlignment.middle",
    "*:colorBlendMode": "BlendMode.srcIn"
```

See [Inflaters Configuration](#inflaters-configuration) for details.

## Hot Reload/Restart clears dependency values

Hot reload loads code changes into the VM and re-builds the widget tree, preserving the app state;
it doesn't rerun `main()` or `initState()`.

Make sure that you're not binding dependencies in `main()`, `initState()` or any other
initialization function such as `Controller.initialize()`. Dependencies should be bound in the
build function of your widget. If you are using a Controller, simply override the
`bindDependencies()` method with your implementation and XWidget will handle the rest.