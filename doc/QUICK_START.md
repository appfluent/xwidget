# Quick Start

This Quick Start guide will help you get up and running with XWidget in just a few minutes. For a
more comprehensive description of the various components and features, please see the sections
below.

1. Install XWidget using the following command:

    ```shell
    $ flutter pub add xwidget
    ```

2. Initialize your project by running:

    ```shell
    $ dart run xwidget:init --new-app
    ```
   
   This will create and configure all the components required for a simple XWidget application.
   It will overwrite `main.dart`, `pubscpec.yaml` and existing XWidget specifications,
   configurations, colors and string values. If you don't want to overwrite these files, run the
   following non-destructive initialization command:

    ```shell
    $ dart run xwidget:init
    ```
   
   The non-destructive command is intended for advanced users that want to add XWidget to an
   existing project. For those users, follow the [Manual Setup](#manual-setup) guide starting
   with step #4. Everyone else should continue to step #3 in this guide.

3. Register the generated schema file `xwidget_scheme.g.xsd` with your IDE under the namespace
   `http://www.appfluent.us/xwidget`. This will provide validation, code completion, and tooltip
   documentation while editing your fragments.

4. To register additional Flutter components, simply modify `lib/xwidget/inflater_spec.dart`
   and run:

    ```shell
    $ dart run xwidget:generate --only inflaters
    ```

5. Install the [Flutter XWidget](https://plugins.jetbrains.com/plugin/25494-flutter-xwidget)
   plugin for Android Studio. This step is optional, but recommended. It provide EL syntax
   highlighting, contextual navigation, component generation and more.

   See [Inflaters](#inflaters), [Components](#components) and [Fragments](#fragments) for
   more information.