### 0.0.30 (Dec 12, 2023)

#### BREAKING CHANGES: Please run `dart run xwidget:generate` after upgrading.

* Controller now extends `StatefulWidget`. This allows Controllers to use mixins designed for
  stateful widgets such as `TickerProviderStateMixin`.
* Renamed `Controller.initialize` to `Controller.init`.
* Removed `build` parameter from Controller constructor.
* Removed multi-controller support from Controllers.
* Some code cleanup

### 0.0.29 (Nov 8, 2023)

#### BREAKING CHANGES: Please run `dart run xwidget:generate` after upgrading.

* Renamed `execution` parameter to `build` in `ControllerWidget` constructor.
* Fixed `ControllerWidget`'s async build.
* Enhanced `parseDuration` function to accept `m`, `min`, `mins`, `h`, `hr`, `hrs`, 
  `d`, `day`, `days` duration suffixes i.e. `5m`, `1hr`, `3days`.  
* Added `isTrue`, `isFalse`, and `logDebug` EL functions.
* Improved invalid EL function error message.
* Minor XML parsing performance improvements.

### 0.0.28 (Oct 31, 2023)

* Fixed reference parser 'null' error.
* Fixed `parseEnum` method signature.

### 0.0.27 (Oct 2, 2023)

* Added `varDisposal` option to `ValueListener`. Possible values are `none`, `byOwner`, and 
  `byLastListener`.
* Added `onChange` callback to `ValueListener`.
* Updated `DataValueNotifier` to be owner and listener aware.
* Added `removeValue` method to `Dependencies` and `MapBrackets` extension. This method is
  dot/bracket notation aware.
* Deleted `remove` method from `Dependencies`. Use `removeValue` instead.

### 0.0.26 (Sep 17, 2023)

* Updated dependencies.

### 0.0.25 (Sep 17, 2023)

* Updated documentation.

### 0.0.24 (Sep 12, 2023)

* Added EL functions `isTrueOrNull` and `isFalseOrNull`.
* Updated documentation.

### 0.0.23 (Sep 8, 2023)

* Removed `disposeOfDependencies` parameter from `DynamicBuilder` constructor.
* `Inflater.parseAttribute` now returns the unparsed value if the value is not parsed. 

### 0.0.22 (Sep 5, 2023)

* Updated analyzer and linter rules
* Minor code formatting
* Added publishing tool

### 0.0.21 (Aug 22, 2023)

* Improved inflater builder's generation of default values from variables.
* Added new built-in EL function `toBool`.
* Updated documentation.

### 0.0.20 (Aug 16, 2023)

#### BREAKING CHANGES: Please run `dart run xwidget:generate` after upgrading.

* Changed `Inflater.inflate` signature to pass a list of unprocessed child strings instead of a 
  single preprocessed string. The inflater's implementation now determines how to process the 
  strings i.e. `Text` inflater uses `XWidgetUtils.joinStrings(text)`.
* Removed `includeAttributes` argument from `XWidget.inflateXmlElementChildren` signature. Use
  `excludeAttributes` argument instead.
* Removed `XWidget.inflateFromXml` convenience method. Use `XWidget.inflateFromXmlElement` instead.
* Added an `excution` option to the `Controller` inflater that specifies its inflation method, either
  asynchronous or synchronous. Valid values are `async` and `sync`. The default is `sync`.
* Minor performance improvements when setting or retrieving `Dependencies` values and parsing
  certain attribute types.
* Added `XWidgetUtils.joinStrings` utility function.
* Added fragment XML caching to improve inflater performance. Use `XWidget.xmlCacheEnabled`
  to enable or disable the cache. Enabled by default.

### 0.0.19 (Aug 9, 2023)

* Attribute parsing performance improvements.
* Documentation updates and additions.
* Minor code cleanup.

### 0.0.18 (Aug 3, 2023)

* Added support for a simplified inflater and icon specification format. See the 
  'Inflaters Configuration' and 'Icons Configuration' README sections.
* Updated documentation.

### 0.0.17 (Jul 7, 2023)

* Substantially increased attribute value parsing performance.
* Added embedded expression parsing to attribute values i.e. `<Text data="Dear ${name},"/>`
* Removed `@fragment` attribute directive. Use the `fragment` tag accompanied with the `for` attribute instead.
* Replaced `copyDependencies` option with `dependenciesScope`. Can be `new`, `copy`, or `inherit`.
* Added `dependenciesScope` option to `frgament` tag.
* Updated documentation.

### 0.0.16 (Jul 4, 2023)

* Improved fragment XML validation.
* Auto generate inflater attribute restrictions for enum types.
* Removed ability to override built-in functions.
* Controller no longer extends `WidgetsBindingObserver`. Subclasses can add it as a mixin, if needed.
* Added `callback` schema element.
* Updated documentation

### 0.0.15 (Jul 2, 2023)

* Overhauled EL functions to simplify implementation.
* Renamed `handler` tag to `callback`.
* Fixed `action` attribute evaluation in `callback` tag.
* Added `returnVar` attribute to `callback` tag.
* Deleted deprecated `attribute` tag. Use `ListOf` inflater instead.
* Documentation updates and additions.

### 0.0.14 (Jun 23, 2023)

* Inflater parsers now return the unparsed value if there's no attribute name match.
* Inflater builder now skips deprecated elements by default.
* [Resources](https://github.com/appfluent/xwidget/blob/main/lib/src/utils/resources.dart) 
  can now use an alternate [AssetBundle](https://api.flutter.dev/flutter/services/AssetBundle-class.html),
  when passed to `loadResources` method. Otherwise, it uses
  [rootBundle](https://api.flutter.dev/flutter/services/rootBundle.html).
* Documentation updates.
* Added `fragment` tag unit tests.

### 0.0.13 (Jun 18, 2023)

* Removed unnecessary import that was causing a web compatibility issue. 
* Updated `var` tag to allow dot/bracket notation in name attribute.
* Continued work on documentation.

### 0.0.12 (Jun 15, 2023)

* Improved CommonLog callback feature. Callback now returns a bool to continue or skip logging.
* Updated xwidget dependency in example 'pubspec.yaml' to point to pub.dev.
* Fixed invalid identifier parsing error.
* Fixed deprecated usages.

### 0.0.11 (Jun 12, 2023)

* Improved log messages from code generator.
* Replaced deprecated commands in documentation.

### 0.0.10 (Jun 12, 2023)

* Continued work on documentation.
* Added license.

### 0.0.9 (Jun 10, 2023)

* ControllerWidget now supports multiple controllers.
* Initialize CommonLog with callback functions instead of class instance.
* EL parser now capable of referencing global dependencies.
* Improved Dependencies toString() format.
* Added more unit tests.

### 0.0.8 (Jun 5, 2023)

* Fixed inflater builder getOnlyChild function call.
* Fixed example inflaters.

### 0.0.7 (Jun 4, 2023)

* Renamed logging class from Log to CommonLog.
* Created XWidgetUtils to hold XWidget helper functions.
* Created CommonUtils to hold common helper functions.
* Cleaned up messy exports.
* Documentation updates.

### 0.0.6 (Jun 4, 2023)

* Added example folder.
* Fixed async resources loading issue. 

### 0.0.5 (Jun 4, 2023)

* Fixed inflater builder's default imports.
* Fixed default inflater config location.
* Fixed controller builder's type scanner.
* Export EL parser.
* Export custom widgets.
* Export logger.

### 0.0.4 (Jun 4, 2023)

* Restructured project files.
* Statically create required inflaters.
* Added InvalidType checks to inflater builder.
* Added inflater test.

### 0.0.3 (Jun 3, 2023)

* Fixed library resolution issue.

### 0.0.2 (Jun 2, 2023)

* Continued work on documentation.
* Fixed an issue with source analysis.
* Automatically scan 'lib/xwidget/controllers' for controllers.

### 0.0.1 (May 31, 2023)

* Initial release. 
* Fully functional, but lacking proper documentation and unit tests.
