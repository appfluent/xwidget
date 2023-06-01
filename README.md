# What is XWidget?

XWidget is a not-so-opinionated framework for building dynamic UIs in Flutter using an expressive, 
XML based markup language.

That was a mouth full, so let's break it down. "Not-so-opinionated" means that you're not forced to
use XWidget in any particular way. You can use as much or as little of the framework as you want - 
whatever makes sense for your project. There are, however, a few [Best Practices] that you should
follow to help keep your code organized and your final build size down to a minimum.

An XWidget UI is defined in XML and parsed at runtime. You have access to all the Flutter
widgets and objects you are used to working with, including widgets from 3rd libraries and even your
own custom widgets. This is achieved through code generation. You specify which widgets you want 
to use and XWidget will generate the appropriate classes and functions and make them available
via XML. You'll have access to all of the Widgets' constructors just as if you were writing Dart code.
You'll even have code completion and access to Widgets' documentation if provided by the author.

For example:

```xml
<Column crossAxisAlignment="start">
    <Text data="Hello World">
        <TextStyle for="style" fontWeight="bold" color="#262626"/>
    </Text>
    <Text>Welcome to XWidget!</Text>
</Column>
```

**Important:** Only specify widgets that you actually use in your UI. Specifying unused widgets or 
objects in your configuration will bloat your app size. This is because code is generated for every 
widget you specify and thus neutralizes Flutter's tree-shaking.

# Usage

## Installation

```shell
$ flutter pub add xwidget 
```

## Configuration


### Inflaters

### Icons

### Controllers

## Code Generation


```shell
$ flutter pub run xwidget:generate 
```

# Core Concepts

## Dependencies

// Add documentation

## Inflaters

// Add documentation

## Parsers

// Add documentation

# Features

## Fragments

// Add documentation

## Controllers

// Add documentation

## Expression Language (EL)

### Static Functions

#### Built-In

#### Custom

### Dynamic Functions

// Add documentation

## Resource Management

### Strings

### Ints

### Bools

### Colors

### Fragments

// Add documentation

## Custom Widgets

// Add documentation

## Tag Language

// Add documentation

## Value Listeners

// Add documentation

## Code Completion and In-Editor Documentation

// Add documentation

# Best Practices

## Do use fragment folders

## Don't specify unused widgets

## Do check-in generated files into source control

The generated dart code is 

# Tips and Tricks

## Regenerate artifacts after upgrading Flutter
 
## Wrap your fragment in a controller to provide reusable functionality

# To Do

- Add a build function to scan all fragments and create a list of all active widgets and then compare
  it to the spec to see which widgets can be dropped from the spec.




