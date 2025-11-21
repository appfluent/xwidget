# Code Generation

XWidget provides a command-line tool for generating inflaters, controllers, icons, and schema
files based on your configuration. The generated code ensures that XML-based UI definitions
can be properly interpreted and rendered within your Flutter application.

To generate inflaters, controllers, and other required files, run the following command:

```shell
$ dart run xwidget_builder:generate
```

To see available options and flags, use:
```shell
$ dart run xwidget_builder:generate --help
```

You can also specify a custom configuration file:
```shell
$ dart run xwidget_builder:generate --config "my_config.yaml"
```

To generate only specific components, use the --only flag:
```shell
$ dart run xwidget_builder:generate --only inflaters,controllers,icons
```

If you need to support deprecated APIs, use:
```shell
$ dart run xwidget_builder:generate --allow-deprecated
```

The generated files will be placed in the appropriate directories as specified
in xwidget_config.yaml.
