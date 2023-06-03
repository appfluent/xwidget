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
You'll even have code completion and access to Widgets' documentation, if provided by the author.

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

## Installation

```shell
$ flutter pub add xwidget 
```

## Configuration

### Inflaters

### Schema

### Controllers

### Icons

## Code Generation

```shell
$ flutter pub run xwidget:generate 
```

```shell
$ flutter pub run xwidget:generate --help 
```

## Simple Example

# Core Concepts

## Dependencies

In the context of XWidget, dependencies are data, objects, and functions needed to render a fragment.
The ```Dependencies``` object, at its core, is just a map of dependencies as defined above. Every
*inflate* method call requires a ```Dependencies``` object. It can be a new instance or one that was
received from a previous *inflate* method invocation.

```Dependencies``` objects have a few characteristics that make them a little more interesting than plain
old maps.

1. Values can be referenced using dot/bracket notation for easy access to nested collections. Nulls
   are handled automatically. If the underlying collection does not exist, reads will resolve to
   null and writes will create the appropriate collections and store the data.<br><br>

   Dart:
   ```dart
   final index = 0;
   final dependencies = Dependencies();
   dependencies.setValue("index", 0);
   dependencies.setValue("users[$index].email", "name@example.com");
   print(dependencies.getValue("users[$index].email"));
   ```
   
   Markup:
   ```xml
   <Text data="${user[index].email}"/>
   ```
2. Supports global data. Sometimes you just need to get data from one part of the application to another
   without a lot of fuss. Global data are accessible across all ```Dependencies``` instances by adding a
   ```global``` prefix to the key notation.<br><br>

   Dart:
   ```dart
   final index = 0;
   final dependencies = Dependencies();
   dependencies.setValue("index", 0);
   dependencies.setValue("global.users[$index].email", "name@example.com");
   ```
   
   Markup:
   ```xml
   <Text data="${global.user[index].email}"/>
   ```
3. When combined with the ```ValueListener``` custom widget, the UI can listen for data changes and
   update itself. In the following example, if the user's email address changes, then the ```Text```
   widget is rebuilt.

   ```xml
   <ValueListener varName="${'users[' + index + '].email'}">
       <Text data="${user[index].email}"/>
   </ValueListener>
   ```
   
**Note:** ```Dependencies``` also supports the bracket operator []; however, it behaves like an
ordinary map.

## Inflaters

Inflaters are the heart of XWidget. They are responsible for building the UI at runtime by parsing
attribute values and constructing the widgets defined in fragments. In other words, they are the
primary mechanism by which your XML markup get transformed from this:

```XML
<Container height="50" width="50">
   <Text data="Hello world!"/>
</Container>
```

into the widget tree equivalent of this:

```Dart
Container({
   height: 50,
   width: 50,
   child: Text("Hello world!")
});
```

A good analogy is the relationship between a recipe, a chef and a meal. The recipe describes how to
create the meal. It lists the ingredients, preparation instructions, etc. The chef does all the work 
described in the recipe. The meal is the finished product. Your XML markup is the recipe, the
inflaters are the chefs in the kitchen, and the instantiated widget tree is the meal, which is then
served to the end user.

Inflaters are generated from a user (a developer using XWidget) defined specification written in
Dart. The specification is very simple and its sole purpose is to tell the code generator which
widgets to generate code for. Once the code has been generated, the widgets can be referenced in
your markup.

```Dart
// a very simple inflater specification
import 'package:flutter/material.dart';

const Container? _container = null;
const Text? _text = null;
const TextStyle? _textStyle = null;
```

You can add as many widgets as required by your application; however, you should only specify 
widgets that you actually need. Specifying unused widgets or objects in your configuration will 
unnecessarily increase your app size. This is because code is generated for every widget you specify
and thus neutralizes Flutter's tree-shaking.  

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

### Doubles

### Bools

### Colors

### Fragments

// Add documentation

## Custom Widgets

// Add documentation

## Tags

Tags are XML elements that do not, themselves, add components to the widget tree. They provide 
common structure control elements for constructing the UI such as conditionals, iteration, fragment
inclusion, etc. They are always represented in lowercase to distinguish them from Widgets and 
objects. 

### ```<attribute>```

| Attribute | Description | Required | Default |
|-----------|-------------|----------|---------|
| name      |             | yes      | null    |

```xml
<attribute name="widget">
   
</attribute>
```

### ```<builder>```

| Attribute        | Description | Required | Default |
|------------------|-------------|----------|---------|
| copyDependencies |             | no       | false   |
| for              |             | yes      | null    |
| multiChild       |             | no       | false   |
| nullable         |             | no       | false   |
| vars             |             | no       | null    |

```xml
<builder for="builder" vars="_,_">
   
</builder>
```

### ```<debug>```

| Attribute | Description | Required | Default |
|-----------|-------------|----------|---------|
| message   |             | no       | null    |

```xml
<debug message="Hello world!"/>
```

### ```<forEach>```

| Attribute        | Description | Required | Default |
|------------------|-------------|----------|---------|
| copyDependencies |             | no       | false   |
| indexVar         |             | no       | null    |
| items            |             | yes      | null    |
| multiChild       |             | no       | null    |
| nullable         |             | no       | null    |
| var              |             | yes      | null    |

```xml
<forEach items="users" var="user">
   
</forEach>
```

### ```<forLoop>```

| Attribute        | Description | Required | Default |
|------------------|-------------|----------|---------|
| begin            |             | no       | 0       |
| copyDependencies |             | no       | false   |
| end              |             | no       | 0       |
| step             |             | no       | 1       |
| var              |             | yes      | null    |

```xml
<forLoop var="index" begin="1" end="5">
   
</forLoop>
```

### ```<fragment>```

| Attribute | Description | Required | Default |
|-----------|-------------|----------|---------|
| for       |             | no       | null    |
| name      |             | yes      | null    |

```xml
<fragment name="profile">
   
</fragment>
```

### ```<handler>```

| Attribute        | Description | Required | Default |
|------------------|-------------|----------|---------|
| action           |             | yes      | null    |
| copyDependencies |             | no       | false   |
| for              |             | yes      | null    |
| vars             |             | no       | null    |

```xml
<handler for="leading">
   
</handler>
```

### ```<if>```/```<else>```

| Attribute | Description | Required | Default |
|-----------|-------------|----------|---------|
| test      |             | yes      | null    |


```xml
<if test="${}">
    <fragnent name=""/>    
    <else>
       <fragnent name=""/>
    </else>
</if>
```

### ```<variable>```

| Attribute | Description | Required | Default |
|-----------|-------------|----------|---------|
| name      |             | yes      | null    |
| value     |             | yes      | null    |

```xml
<variable name="" value=""/>
```

## Value Listeners

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
