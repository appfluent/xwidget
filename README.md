<p align="center">
    <img src="https://raw.githubusercontent.com/appfluent/xwidget/main/doc/assets/xwidget_logo_full.png"
        alt="XWidget Logo"
        height="100"
    />
</p>

<p align="center">
    <img src="https://raw.githubusercontent.com/appfluent/xwidget/main/doc/assets/code_animation.gif"
        alt="Code Animation"
        style="max-width:800px; width:100%; height:auto;"
    />
</p>

### *Note: This document is very much still a work in progress.*

# What is XWidget?

XWidget is a not-so-opinionated library for building dynamic UIs in Flutter using an expressive,
XML based markup language.

That was a mouth full, so let's break it down. "Not-so-opinionated" means that you're not forced to
use XWidget in any particular way. You can use as much or as little of the framework as you want -
whatever makes sense for your project. There are, however, a few [Best Practices](#best-practices)
that you should follow to help keep your code organized and your final build size down to a minimum.

An XWidget UI is defined in XML and parsed at runtime. You have access to all the Flutter widgets
and classes you are used to working with, including widgets from 3rd party libraries and even your
own custom widgets. This is achieved through code generation. You specify which widgets you want to
use and XWidget will generate the appropriate classes and functions and make them available as XML
elements. You'll have access to all of the Widgets' constructor arguments as element attribute just
as if you were writing Dart code. You'll even have code completion and access to Widgets'
documentation in tooltips, if provided by the author, when you register the generated XML schema
with your IDE.

For example:

```xml
<Column crossAxisAlignment="start">
    <Text data="Hello World">
        <TextStyle for="style" fontWeight="bold" color="#262626"/>
    </Text>
    <Text>Welcome to XWidget!</Text>
</Column>
```

**Important:** Only specify widgets that you actually use in your UI. Specifying unused widgets and
helper classes in your configuration will bloat your app size. This is because code is generated for
every component you specify and thus neutralizes Flutter's tree-shaking.

# Table of Contents

1. [Quick Start](./doc/QUICK_START.md)
2. [Example](./doc/EXAMPLE.md)
3. [Configuration](./doc/CONFIGURATION.md)
4. [Code Generation](./doc/CODE_GENERATION.md)
5. [Inflaters](./doc/INFLATERS.md)
6. [Dependencies](./doc/DEPENDENCIES.md)
7. [Model](./doc/MODEL.md) 
8. [Fragments](./doc/FRAGMENTS.md)
9. [Controllers](./doc/CONTROLLERS.md)
10. [Expression Language (EL)](./doc/EL.md)
    - [Operators](./doc/EL.md#operators)
    - [Built-In Functions](./doc/EL.md#built-in-functions)
    - [Custom Functions](./doc/EL.md#custom-functions)
11. [Resources](./doc/RESOURCES.md)
    - [Strings](./doc/RESOURCES.md#strings)
    - [Ints](./doc/RESOURCES.md#ints)
    - [Doubles](./doc/RESOURCES.md#doubles)
    - [Bools](./doc/RESOURCES.md#bools)
    - [Colors](./doc/RESOURCES.md#colors)
    - [Fragments](#fragments-1)
12. [Components](./doc/COMPONENTS.md)
    - [Flutter](./doc/COMPONENTS.md#flutter)
    - [Third Party](./doc/COMPONENTS.md#third-party)
    - [Built-In](./doc/COMPONENTS.md#built-in)
      - [```<Controller>```](./doc/COMPONENTS.md#controller)
      - [```<DynamicBuilder>```](./doc/COMPONENTS.md#dynamicbuilder)
      - [```<List>```](./doc/COMPONENTS.md#list)
      - [```<Map>```](./doc/COMPONENTS.md#map)
      - [```<MapEntry>```](./doc/COMPONENTS.md#mapentry)
      - [```<MediaQuery>```](./doc/COMPONENTS.md#mediaquery)
      - [```<ValueListener>```](./doc/COMPONENTS.md#valuelistener)
    - [Custom](./doc/COMPONENTS.md#custom)
13. [Tags](./doc/TAGS.md)
    - [```<builder>```](./doc/TAGS.md#builder)
    - [```<callback>```](./doc/TAGS.md#callback)
    - [```<debug>```](./doc/TAGS.md#debug)
    - [```<forEach>```](./doc/TAGS.md#foreach)
    - [```<forLoop>```](./doc/TAGS.md#forloop)
    - [```<fragment>```](./doc/TAGS.md#fragment)
    - [```<if>/<else>```](./doc/TAGS.md#ifelse)
    - [```<var>```](./doc/TAGS.md#var)
14. [Best Practices](./doc/BEST_PRACTICES.md)
15. [Tips and Tricks](./doc/TIPS_TRICKS.md)
16. [Trouble Shooting](./doc/TROUBLE_SHOOTING.md)
    - [The generated inflater code has errors](./doc/TROUBLE_SHOOTING.md#the-generated-inflater-code-has-errors)
    - [Hot reload/restart clears dependency values](./doc/TROUBLE_SHOOTING.md#hot-reloadrestart-clears-dependency-values)
17. [FAQ](./doc/FAQ.md)
18. [Roadmap](./doc/ROADMAP.md)
    - [0.0.x Releases (2023)](./doc/ROADMAP.md#00x-releases-2023)
    - [0.x Releases (2024)](./doc/ROADMAP.md#0x-releases-2024)
    - [1.0.0 Release (mid 2024)](./doc/ROADMAP.md#100-release-mid-2024)
19. [Known Issues](#known-issues)
