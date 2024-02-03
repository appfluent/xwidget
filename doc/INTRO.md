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