# FAQ

## 1. What problems does XWidget solve?

The first and most obvious answer is that it gives applications the flexibility to create and modify
its UI at runtime. An app might want to give its users the ability to download a different
look-and-feel or create dynamic forms all without a redeployment. You're only limited by the
existing functionality of your custom controllers, since they're static Dart code.

It provides better separation between business and presentation layers out of the box. Sometimes
developers struggle with the best way to separate these concerns. XWidget inherently addresses
these problems in an uncomplicated way with fragments and controllers.

This may just be our opinion, but building views in code just feels clunky. We find it more
enjoyable to write our UIs using markup - it feels more natural and it's certainly a lot easier to
read. The experience should only get better as we improve IDE integration.

## I don't need dynamic UIs, why should I still use XWidget?

While not all apps require dynamic user interfaces, incorporating XWidget can still yield
substantial benefits. XWidget enhances code quality by promoting organization and readability,
contributing to overall code improvement.

Code readability is a fundamental aspect of quality code for any software project. Readable
code is much easier to debug, maintain, and understand. XWidget's strong separation between
presentation logic and layout leads to better organized code. Its XML based markup language
for building layouts is vastly easier to read and modify than the default, code centric approach
offered by the Flutter framework. Additionally, XWidget can manage your static string, boolean,
numeric, and color resources, so that values are never hardcoded directly into your layouts or
anywhere else. Please read the [Fragments](#fragments), [Controllers](#controllers), and
[Resources](#resources) sections above.