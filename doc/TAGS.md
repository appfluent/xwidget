# Tags

Tags are XML elements that do not, themselves, add components to the widget tree. They provide
common structure and control elements for constructing the UI such as conditionals, iteration,
fragment inclusion, etc. They are always represented in lowercase to distinguish them from inflaters.

## ```<builder>```

A tag that wraps its children in a builder function.

This tag is extremely useful when the parent requires a builder function, such as
[PageView.builder](https://api.flutter.dev/flutter/widgets/PageView/PageView.builder.html).
Use `vars`, `multiChild`, and `nullable` attributes to define the builder function signature.
When the builder function executes, the values of named arguments defined in `vars` are stored
as dependencies in the current `Dependencies` instance. The values of placeholder arguments (_) are
simply ignored. The `BuildContext` is never stored as a dependency, even if explicitly named,
because it would cause a memory leak.

| Attribute         | Description                                                                                                                                | Required | Default |
|-------------------|--------------------------------------------------------------------------------------------------------------------------------------------|----------|---------|
| dependenciesScope | Defines the method for passing Dependencies to immediate children. Valid values are `new`, `copy`, and `inherit`.                          | no       | auto    |
| for               | The name of the parent's attribute that will be assigned the builder function.                                                             | yes      | null    |
| multiChild        | Whether the builder function should return an array of widgets or a single widget.                                                         | no       | false   |
| nullable          | Whether the builder function can return null.                                                                                              | no       | false   |
| vars              | A comma separated list of builder function arguments. Values of named arguments are stored as dependencies. Supports up to five arguments. | no       | null    |

Example usage:
```xml
<PageView.builder>
    <builder for="itemBuilder" vars="_,index" nullable="true">
        <Container>
            <Text data="${index}"/>
        </Container>
    </builder>
</PageView.builder>
```

## ```<callback>```

This tag allows you to bind an event handler with custom arguments. If you don't need to pass any
arguments, then just bind the handler using EL, like so: `<TextButton onPressed="${onPressed}"/>`.
This is sufficient in most cases.

The `callback` tag creates an event handler function for you and executes the `action` when the
event is triggered. `action` is an EL expression that is evaluated at the time of the event. Do not
enclose the expression in curly braces `${...}`, otherwise it will be evaluated immediately upon
creation instead of when the event is fired.

If the handler function defines arguments in its signature, you must declare those arguments using
the `vars` attribute. This attribute takes a comma separated list of argument names. When the
handler is triggered, argument values are added to `Dependencies` using the specified name as the
key, and can be referenced in the `action` EL expression, if needed. They're also accessible
anywhere else that instance of `Dependencies` is available. If you don't need the values, then use
and underscore (_) in place of the name. Doing so will ignore the values and they won't be added to
`Dependencies` e.g. `...vars="_,index"...`. `BuildContext` is never added to `Dependencies` even
when named, because this would cause a memory leak.

| Attribute         | Description                                                                                                                                | Required | Default |
|-------------------|--------------------------------------------------------------------------------------------------------------------------------------------|----------|---------|
| action            | The El expression to evaluate when the event handler is triggered.                                                                         | yes      | null    |
| dependenciesScope | Defines the method for passing Dependencies to immediate children. Valid values are `new`, `copy`, and `inherit`.                          | no       | auto    |
| for               | The name of the parent's attribute that will be assigned the event handler.                                                                | yes      | null    |
| returnVar         | The storage destination within `Dependencies` for the return value of `action`.                                                            | no       | null    |
| vars              | A comma separated list of handler function arguments. Values of named arguments are stored as dependencies. Supports up to five arguments. | no       | null    |

```xml
<TextButton>
    <callback for="onPressed" action="doSomething('Hello World')"/>
    <Text>Press Me</Text>
</TextButton>

```

## ```<debug>```

A simple tag that logs a debug message

| Attribute | Description         | Required | Default |
|-----------|---------------------|----------|---------|
| message   | The message to log. | yes      | null    |

```xml
<debug message="Hello world!"/>
```

## ```<forEach>```

*Add documentation here.*

| Attribute         | Description                                                                                                       | Required | Default |
|-------------------|-------------------------------------------------------------------------------------------------------------------|----------|---------|
| dependenciesScope | Defines the method for passing Dependencies to immediate children. Valid values are `new`, `copy`, and `inherit`. | no       | `copy`  |
| indexVar          |                                                                                                                   | no       | null    |
| items             |                                                                                                                   | yes      | null    |
| multiChild        |                                                                                                                   | no       | null    |
| nullable          |                                                                                                                   | no       | null    |
| var               |                                                                                                                   | yes      | null    |

```xml
<forEach var="user" items="${users}">

</forEach>
```

## ```<forLoop>```

*Add documentation here.*

| Attribute         | Description                                                                                                       | Required | Default |
|-------------------|-------------------------------------------------------------------------------------------------------------------|----------|---------|
| begin             |                                                                                                                   | no       | 0       |
| dependenciesScope | Defines the method for passing Dependencies to immediate children. Valid values are `new`, `copy`, and `inherit`. | no       | `copy`  |
| end               |                                                                                                                   | no       | 0       |
| step              |                                                                                                                   | no       | 1       |
| var               |                                                                                                                   | yes      | null    |

```xml
<forLoop var="index" begin="1" end="5">

</forLoop>
```

## ```<fragment>```

A tag that renders a UI fragment

| Attribute         | Description                                                                                                       | Required | Default |
|-------------------|-------------------------------------------------------------------------------------------------------------------|----------|---------|
| dependenciesScope | Defines the method for passing Dependencies to immediate children. Valid values are `new`, `copy`, and `inherit`. | no       | auto    |
| for               | The name of the parent's attribute that will be assigned the fragment's output.                                   | no       | null    |
| name              | The `Resources` name of the fragment.                                                                             | yes      | null    |

```xml
<AppBar>
    <fragment for="leading" name="profile/icon"/>
</AppBar>
```

## ```<if>```/```<else>```

*Add documentation here.*

| Attribute | Description                                        | Required | Default |
|-----------|----------------------------------------------------|----------|---------|
| test      | EL expression tht must evaluate to a `bool` value. | yes      | null    |


```xml
<if test="${}">
    <fragnent name=""/>
    <else>
        <fragnent name=""/>
    </else>
</if>
```

## ```<var>```

*Add documentation here.*

| Attribute | Description | Required | Default |
|-----------|-------------|----------|---------|
| name      |             | yes      | null    |
| value     |             | yes      | null    |

```xml
<var name="" value=""/>
```