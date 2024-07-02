### 0.0.42 (July 2, 2024)

#### Please run `dart run xwidget:generate` after upgrading.

* Added an initialization command to setup a new XWidget project. Please see the Quick Start guide.
* Updated Example project to use Material3.

### 0.0.41 (May 26, 2024)

#### BREAKING CHANGES: Please run `dart run xwidget:generate` after upgrading.
#### This is a big release with many changes. Please read the release notes carefully.

* Reorganized utility functions to eliminate duplication, clarify purpose, and better
  support reuse. They are divided into the following groups: converters, math, parsers, validators,
  and misc. All parsing function now only parse `String` values; conversion function convert
  `dynamic` values and may call a parsing function if the value is a `String`. 
* Added the following EL functions:
  - `formatDuration`
  - `isBlank`
  - `isNotBlank`
  - `toColor`
  - `toDays`
  - `toHours`
  - `toMillis`
  - `toMinutes`
  - `toSeconds`
  - `tryToBool`
  - `tryToColor`
  - `tryToDateTime`
  - `tryToDays`
  - `tryToDouble`
  - `tryToDuration`
  - `tryToHours`
  - `tryToInt`
  - `tryToMillis`
  - `tryToMinutes`
  - `tryToSeconds`
* Added the following parsing functions:
  - `parseInt`
  - `parseDouble`
  - `tryParseBool`
  - `tryParseDateTime`
  - `tryParseDouble`
  - `tryParseDuration`
  - `tryParseEnum`
  - `tryParseInt`
* You can now listen changes to nested model properties with `<ValueListener>`,
  `Model.listenForChanges` or `Dependencies.listenForChanges` when using `Model.setValue` or
  `Dependencies.setValue`. For example:
  ```dart
  final user = Model({
    "first": "Mike",
    "last": "Smith",
    "email": "test@example.com"
  });
  dependecies.setValue("profile", user);
  ```
  ```xml
  <ValueListener varName="profile">
    <Row>
        <Text data="${profile.first}"/>
        <Text data="${profile.last}"/>
        <Text data="${profile.email}"/>
    </Row>
  </ValueListener>
  ```
  Any changes to `first`, `last` or `email` using `setValue` will trigger the `<ValueListener>` to
  rebuild.
* `Model` instances now default to mutable.
* Added named constructor `Model.immutable`.
* Added `<Item>` tag to `<List>` for situations where you want to build a list from values stored in
  `Dependencies` or EL functions.
  ```xml
  <List for="...">
    <Item value="${color}"/>
    <Item value="${toColor('0xFF272727')}"/>
    <Item value="${backgroundColor}"/>
  </List>
  ```
* You can now pass `int` values to inflaters that previously required `doubles` and they will be
  automatically converted to `doubles` i.e. any widget that takes `width` and `height`.   
* Updated EL Functions and Tips & Tricks documentation.
* Removed the following EL functions:
  `durationInDays` - use `toDays` instead
  `durationInHours` - use `toHours` instead
  `durationInMinutes` - use `toMinutes` instead
  `durationInSeconds` - use `toSeconds` instead
  `durationInMills` - use `toMillis` instead
* Removed the following parser functions:
  `parseWidth` - use `parseDouble` instead
  `parseHeight` - use `parseDouble` instead

### 0.0.40 (May 9, 2024)

#### BREAKING CHANGES: Please run `dart run xwidget:generate` after upgrading.

* Added `abs`, `ceil`, `floor`, and `round` EL functions. 
* Added grouping functionality to `forEach` tag. Useful for creating simple multi-column layouts. 
  ```xml
  <!-- forEach grouping example -->
  <forEach var="group" items="${items}" groupSize="2">
      <Row>
          <forEach var="item" items="${group}">
              <Text data="${item.title}"/>
          </forEach>
      </Row>
  </forEach>
  ```
* Added `returnType` attribute to `builder` tag. Valid values are `Widget`, `Widget?`, `List:Widget`, 
  and `List:PopupMenuEntry`. Defaults to `Widget` if empty.
* Added return type `List<PopupMenuEntry>` (display name `List:PopupMenuEntry`) to `builder` tag.
* Added support for defining inflaters with generic types i.e. `AlwaysStoppedAnimation<T>`,
  `MaterialStatePropertyOf<T>`, etc.
  ```dart
  // inflater_spec.dart example
  const inflaters = [
    AlwaysStoppedAnimation<Color>
    MaterialStatePropertyOf<Color>,
    MaterialStatePropertyOf<Size>,
    MaterialStatePropertyOf<TextStyle>,
  ];
  ```
  ```xml
    <!-- simple fragment examples -->
    <AlwaysStoppedAnimationColor for="..." value="@color/primary"/>
    <MaterialStatePropertyOfColor for="..." primary="#272727" disabled="#676767"/>
    <MaterialStatePropertyOfSize for="..." primary="8x8" focused="12x12" error="x24"/>
    <MaterialStatePropertyOfTextStyle for="...">
        <TextStyle for="primary" fontWeight="400"/>
        <TextStyle for="selected" fontWeight="600"/>
    </MaterialStatePropertyOfTextStyle>
  ```
* Removed `nullable` and `multiChild` attributes from `builder` tag. Use `returnType` instead.
* Removed erroneous `start`, `end` attributes from `forEach` schema definition.
* Removed previously added `MaterialStateXXX` custom inflaters. Use `MaterialStatePropertyOf<T>` instead.
* Removed support for original inflater specification format. Use the new specification format.
  ```dart
  // old format - no longer supported
  const Column? _column = null;
  const Text? _text = null;
  const TextStyle? _textStyle = null;

  // new format
  const inflaters = [
    Column,
    Text,
    TextStyle,
  ];
  ```

### 0.0.39 (May 6, 2024)

#### Please run `dart run xwidget:generate --only inlfaters` after upgrading.

* Added default inflater constructor value for `BoxShadow:color`.
* `parseBool` now parses `int`s. Zero is `false`, non-zero values are `true`.
* Added custom `MaterialState` implementations and parsers to better support `MaterialState` properties.
  ```dart
  // inflater_spec.dart example
  const inflaters = [
    MaterialStateBorderSide,
    MaterialStateColor,
    MaterialStateDouble,
    MaterialStateEdgeInsets
    MaterialStateMouseCursor,
    MaterialStateOutlineBorder,
    MaterialStateSize,
    MaterialStateTextStyle,
  ];
  ```
  ```xml
    <!-- simple fragment examples -->
    <MaterialStateColor for="..." primary="#272727" disabled="#676767"/>
    <MaterialStateSize for="..." primary="8x8" focused="12x12" error="x24"/>
    <MaterialStateTextStyle for="...">
        <TextStyle for="primary" fontWeight="400"/>
        <TextStyle for="selected" fontWeight="600"/>
    </MaterialStateTextStyle>
  ```
  Configured default parsers:
  ```yaml
    # default_config.yaml
    "MaterialStateProperty<Color>": "parseMaterialStateColor(value)"
    "MaterialStateProperty<double>": "parseMaterialStateDouble(value)"
    "MaterialStateProperty<EdgeInsetsGeometry>": "parseMaterialStatePadding(value)"
    "MaterialStateProperty<Size>": "parseMaterialStateSize(value)"
  ```

### 0.0.38 (April 29, 2024)

* Fixed EL `RangeError` when referencing data using an out of range index i.e. `${items[2].name}`
  where `items.length == 2` now returns a null. This is consistent with how null property
  references are handled i.e `${person.name}` where `person == null`. Maybe in the future we'll add
  a `strict` mode that throws Exceptions.

### 0.0.37 (March 28, 2024)

* Added `toDouble` and `toInt` EL functions.
* Minor documentation updates

### 0.0.36 (Feb 11, 2024)

#### Please run `dart run xwidget:generate` after upgrading.

* Added `EventNotifier` component.
  ```xml
  <EventNotifier event="UserEvents.login">
    ...
  </EventNotifier>
  ```
* Added mapped `Controller` options.
  ```xml
  <Controller name="...">
      <Map for="options">
          <Entry key="name" value="${value}"/>
      </Map>
  </Controller>
  ```
* Added arguments to `XWidget.inflateXmlElementChildren` that optionally include or exclude the
  processing of attributes defined as children i.e. `for='<parent_attribute>'`
* Removed `ValueListener`'s `onChange` callback.

### 0.0.35 (Feb 2, 2024)

* Fixed readability issues with README.md file.
* Added documentation builder tool (internal).

### 0.0.34 (Feb 2, 2024)

#### BREAKING CHANGES: Please up all usages of `Data` to `Model`.

* Renamed `Data` to `Model` to more accurately represent its purpose.
* Fixed a bug where `Model` operators `[]` and `[]=` were incorrectly calling `getValue` and `setValue` respectively.
  They now directly access the underlying collection.
* Added static instance management methods to `Model` to help with state management:
  `singleInstance`, `keyedInstance`, `clearInstances`, `hasInstance`
* Reorganized documentation.

### 0.0.33 (Jan 28, 2024)

* Fixed dot/bracket notation parsing of `List` paths.
* Fixed relative `import` statements.
* Export `MediaQueryWidget`.

### 0.0.32 (Jan 23, 2024)

#### Please run `dart run xwidget:generate` after upgrading.

* Fixed issues with code generator not recognizing some `List` types.
* Improved EL dot notation path resolution error messages.
* Changed `<builder/>`'s `for` attribute from required to optional. This is needed for
  creating lists of builders as required by `BottomNavLayout.pages`.
* Added `innerLists` attribute to `<List/>` for configuration of how inner lists are handled.
  The options are `add` and `spread`. `add` (default) will add the inner list object.
  `spread` will add the inner list's items to the containing list. 
* Added `visible` attribute to `<fragment/>`.
* Added new EL functions: `randomDouble`, `randomInt`, `replaceAll`, `replaceFirst`
* Improved code generator's handling of private constant defaults.
* Added `<Media/>` component. Writes MediaQuery values to `Dependencies`.
* Added `createMaterialColor`, `parseMaterialColor` utility functions.

### 0.0.31 (Jan 1, 2024)

#### BREAKING CHANGES: Please run `dart run xwidget:generate` after upgrading.

* Renamed `ListOf` element to `List` for consistency
* Added `Map` element. Example usage:
  ```xml
  <Map for="attribute">
    <Entry key="name" value="name"/>
    <Entry value="description">description</Entry>
  </Map>
  ```
 * Allow `param`, `forEach`, and `if` elements as optional children of `fragment`
   element. Example usage:
   ```xml
   <fragment name="header">
       <param name="bottom" value="tab_bar"/>
   </fragment>
   ```
* Auto scope dependencies for elements that support the `dependenciesScope` attribute.
* Updated minimum `petitparser` version to `6.0.0`.
* Removed deprecated imports.

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
