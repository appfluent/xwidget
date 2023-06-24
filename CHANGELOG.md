### 0.0.14 (Jun 23, 2023)

* Inflater parsers now return the unparsed value if there's no attribute name match.
* Inflater builder now skips deprecated elements by default.
* [Resources](https://github.com/appfluent/xwidget/blob/main/lib/src/utils/resources.dart) 
  can now use an alternate [AssetBundle](https://api.flutter.dev/flutter/services/AssetBundle-class.html),
  when passed to `loadResources` method. Otherwise, it uses
  [rootBundle](https://api.flutter.dev/flutter/services/rootBundle.html).
* Documentation updates
* Added <fragment> tag unit tests

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
