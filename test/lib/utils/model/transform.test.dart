import 'package:flutter_test/flutter_test.dart';
import 'package:type_plus/type_plus.dart';

import '../../../../lib/xwidget.dart' hide startsWith;
import '../../testing_utils.dart';

main() {

  setUpAll(() {
    XWidget.registerModel<Profile>(Profile.import, const [
      PropertyTransformer<String>("username"),
      PropertyTransformer<String>("email"),
      PropertyTransformer<String?>("name"),
      PropertyTransformer<DateTime?>("lastLogin"),
    ]);

    XWidget.registerModel<Image>(Image.new, const [
      PropertyTransformer<String>("url", isKey: true),
      PropertyTransformer<String?>("caption"),
    ]);

    XWidget.registerModel<Person>(Person.new, const [
      PropertyTransformer<String>("first"),
      PropertyTransformer<String>("last"),
      PropertyTransformer<bool>("employee"),
      PropertyTransformer<int>("age"),
    ]);
  });

  test('Assert import without translation', () {
    final person = Person({
      "first": "Mike",
      "last": "Jones",
      "employee": "true",
      "age": "25"
    });

    expect(person, {
      "first": "Mike",
      "last": "Jones",
      "employee": true,
      "age": 25
    });
  });

  test('Assert import ignores undefined properties', () {
    final person = Person({
      "first": "Mike",
      "last": "Jones",
      "employee": "true",
      "age": "25",
      "ssn": "123-45-6789"
    });

    expect(person, {
      "first": "Mike",
      "last": "Jones",
      "employee": true,
      "age": 25
    });
  });

  test('Assert import translation', () {
    final person = Person({
        "firstName": "Mike",
        "lastName": "Jones",
        "employee": "true",
        "age": "25"
      }, translation: PropertyTranslation({
        "firstName": "first",
        "lastName": "last"
      })
    );

    expect(person, {
      "first": "Mike",
      "last": "Jones",
      "employee": true,
      "age": 25
    });
  });

  test('Assert that nested models are imported', () {
    XWidget.registerModel<TestModel>(TestModel.new, const [
      PropertyTransformer<String>("title"),
      PropertyTransformer<String?>("summary"),
      PropertyTransformer<Image>("image"),
    ]);

    final content = TestModel({
        "title": "Hello World",
        "summary": "Basic App",
        "imageUrl": "https://www.example.com/image.jpg",
        "imageCaption": "Sunset",
      }, translation: PropertyTranslation({
        "imageUrl": "image.url",
        "imageCaption": "image.caption",
      })
    );

    expect(content, {
      'title': 'Hello World',
      'summary': 'Basic App',
      'image': {'url': 'https://www.example.com/image.jpg', 'caption': 'Sunset'}
    });
  });

  test('Assert that a nested model can be null when data does not exist', () {
    XWidget.registerModel<TestModel>(TestModel.new, const [
      PropertyTransformer<String>("title"),
      PropertyTransformer<String?>("summary"),
      PropertyTransformer<Image?>("image"),
    ]);

    final model = TestModel({
        "title": "Mike",
        "summary": "Jones",
      }, translation: PropertyTranslation({
        "image.url": "imageUrl",
        "image.caption": "imageCaption",
      })
    );

    expect(model, {
      'title': 'Mike',
      'summary': 'Jones',
    });
  });

  test('Assert that errors are captured when data does not exist and the model is required', () {
    XWidget.registerModel<TestModel>(TestModel.new, const [
      PropertyTransformer<String>("title"),
      PropertyTransformer<String?>("summary"),
      PropertyTransformer<Image>("image"),
    ]);

    final model = TestModel({
        "title": "Mike",
        "summary": "Jones",
        // "imageUrl": "https://www.example.com/image.jpg",
        // "imageCaption": null,
      }, translation: PropertyTranslation({
        "imageUrl": "image.url",
        "imageCaption": "image.caption",
      })
    );

    expect(model, {
      'title': 'Mike',
      'summary': 'Jones'
    });

    expect(model.errors, {'image': ModelErrors.required});
  });

  test('Assert that nested errors are captured when data partial data exists for a nullable model property, but required data is null', () {
    XWidget.registerModel<TestModel>(TestModel.new, const [
      PropertyTransformer<String>("title"),
      PropertyTransformer<String?>("summary"),
      PropertyTransformer<Image?>("image"),
    ]);

    final model = TestModel({
        "title": "Mike",
        "summary": "Jones",
        // "imageUrl": "https://www.example.com/image.jpg",
        "imageCaption": "Example Caption", // partial data
      }, translation: PropertyTranslation({
        "imageUrl": "image.url",
        "imageCaption": "image.caption",
      })
    );

    expect(model, {
      'title': 'Mike',
      'summary': 'Jones',
      'image': {
        'caption': 'Example Caption'
      }
    });

    expect(model.errors, {'image.url': ModelErrors.required});
  });

  test('Assert that a single unindexed model can be added to a list', () {
    XWidget.registerModel<TestModel>(TestModel.new, const [
      PropertyTransformer<String>("title"),
      PropertyTransformer<String?>("summary"),
      PropertyTransformer<List<Image>>("images"),
    ]);

    final model = TestModel({
        "title": "Mike",
        "summary": "Jones",
        "imageUrl": "https://www.example.com/image.jpg",
        "imageCaption": null, // partial data
      }, translation: PropertyTranslation({
        "imageUrl": "images.url",
        "imageCaption": "images.caption",
      })
    );

    expect(model, {
      'title': 'Mike',
      'summary': 'Jones',
      'images': [{'url': 'https://www.example.com/image.jpg'}]
    });

    expect(model.errors, {});
  });

  test('Assert that multiple unindexed models can be added to a list', () {
    XWidget.registerModel<TestModel>(TestModel.new, const [
      PropertyTransformer<String>("title"),
      PropertyTransformer<String?>("summary"),
      PropertyTransformer<List<Image>>("images"),
    ]);

    final model = TestModel({
        "title": "Hello World",
        "summary": "Basic App",
        "primaryImageUrl": "https://www.example.com/image.jpg",
        "secondaryImageUrl": "https://www.example.com/image2.jpg",
        "secondaryImageCaption": "Secondary",
      }, translation: PropertyTranslation({
        "primaryImageUrl": "images.url",
        "primaryImageCaption": "images.caption",
        "secondaryImageUrl": "images.url",
        "secondaryImageCaption": "images.caption",
      })
    );

    expect(model, {
      'title': 'Hello World',
      'summary': 'Basic App',
      'images': [
        {'url': 'https://www.example.com/image.jpg'},
        {'url': 'https://www.example.com/image2.jpg', 'caption': 'Secondary'}
      ]
    });
  });

  test('Assert that multiple unindexed basic types models can be added to a list', () {
    XWidget.registerModel<TestModel>(TestModel.new, const [
      PropertyTransformer<String>("first"),
      PropertyTransformer<String?>("last"),
      PropertyTransformer<List<int>>("numbers"),
    ]);

    final model = TestModel({
        "firstName": "Mike",
        "lastName": "Jones",
        "num1": 1,
        "num2": "2",
        "num3": 3,
      }, translation: PropertyTranslation({
        "firstName": "first",
        "lastName": "last",
        "num1": "numbers",
        "num2": "numbers",
        "num3": "numbers",
      })
    );

    expect(model, {
      'first': 'Mike',
      'last': 'Jones',
      'numbers': [1, 2, 3]
    });
  });

  test('Assert that multiple unindexed basic types models can be added to a set', () {
    XWidget.registerModel<TestModel>(TestModel.new, const [
      PropertyTransformer<String>("first"),
      PropertyTransformer<String?>("last"),
      PropertyTransformer<Set<int>>("numbers"),
    ]);

    final model = TestModel({
        "firstName": "Mike",
        "lastName": "Jones",
        "num1": 1,
        "num2": "2",
        "num3": 3,
        "num4": 3,
      }, translation: PropertyTranslation({
        "firstName": "first",
        "lastName": "last",
        "num1": "numbers",
        "num2": "numbers",
        "num3": "numbers",
        "num4": "numbers",
      })
    );

    expect(model, {
      'first': 'Mike',
      'last': 'Jones',
      'numbers': [1, 2, 3]
    });
  });

  test('Assert that indexed basic types models can be added to a list', () {
    XWidget.registerModel<TestModel>(TestModel.new, const [
      PropertyTransformer<String>("first"),
      PropertyTransformer<String?>("last"),
      PropertyTransformer<List<int>>("numbers"),
    ]);

    final model = TestModel({
        "firstName": "Mike",
        "lastName": "Jones",
        "numbers": ["1", "2", "3"]
      }, translation: PropertyTranslation({
        "firstName": "first",
        "lastName": "last",
      })
    );

    expect(model, {
      'first': 'Mike',
      'last': 'Jones',
      'numbers': [1, 2, 3]
    });
  });

  test('Assert that a multiple listed models can be added to a list w/o translation', () {
    XWidget.registerModel<TestModel>(TestModel.new, const [
      PropertyTransformer<String>("first"),
      PropertyTransformer<String?>("last"),
      PropertyTransformer<List<Image>>("images"),
    ]);

    final model = TestModel({
      "firstName": "Mike",
      "lastName": "Jones",
      "images": [
        {"url": "https://www.example.com/image1.jpg", "caption": "#1"},
        {"url": "https://www.example.com/image2.jpg", "caption": "#2"},
        {"url": "https://www.example.com/image3.jpg", "caption": "#3"},
      ]}, translation: PropertyTranslation({
        "firstName": "first",
        "lastName": "last",
      })
    );

    expect(model, {
      'first': 'Mike',
      'last': 'Jones',
      'images': [
        {'url': 'https://www.example.com/image1.jpg', 'caption': '#1'},
        {'url': 'https://www.example.com/image2.jpg', 'caption': '#2'},
        {"url": "https://www.example.com/image3.jpg", "caption": "#3"},
      ]
    });
  });

  test('Assert that a multiple listed models can be added to a list w/ list only translation', () {
    XWidget.registerModel<TestModel>(TestModel.new, const [
      PropertyTransformer<String>("first"),
      PropertyTransformer<String?>("last"),
      PropertyTransformer<List<Image>>("images"),
    ]);

    final model = TestModel({
      "firstName": "Mike",
      "lastName": "Jones",
      "myImages": [
        {"url": "https://www.example.com/image1.jpg", "caption": "#1"},
        {"url": "https://www.example.com/image2.jpg", "caption": "#2"},
        {"url": "https://www.example.com/image3.jpg", "caption": "#3"},
      ]}, translation: PropertyTranslation({
        "firstName": "first",
        "lastName": "last",
        "myImages": "images",
      })
    );

    expect(model, {
      'first': 'Mike',
      'last': 'Jones',
      'images': [
        {'url': 'https://www.example.com/image1.jpg', 'caption': '#1'},
        {'url': 'https://www.example.com/image2.jpg', 'caption': '#2'},
        {"url": "https://www.example.com/image3.jpg", "caption": "#3"},
      ]
    });
  });

  test('Assert that a multiple listed models can be added to a set w/o translation', () {
    XWidget.registerModel<TestModel>(TestModel.new, const [
      PropertyTransformer<String>("first"),
      PropertyTransformer<String?>("last"),
      PropertyTransformer<Set<Image>>("images"),
    ]);

    final model = TestModel({
      "firstName": "Mike",
      "lastName": "Jones",
      "images": [
        {"url": "https://www.example.com/image1.jpg", "caption": "#1"},
        {"url": "https://www.example.com/image2.jpg", "caption": "#2"},
        {"url": "https://www.example.com/image2.jpg", "caption": "#2"},
      ]}, translation: PropertyTranslation({
        "firstName": "first",
        "lastName": "last",
      })
    );

    expect(model, {
      'first': 'Mike',
      'last': 'Jones',
      'images': {
        {'url': 'https://www.example.com/image1.jpg', 'caption': '#1'},
        {'url': 'https://www.example.com/image2.jpg', 'caption': '#2'},
      }
    });
  });

  test('Assert that a multiple listed models can be added to a list w/ full translation', () {
    XWidget.registerModel<TestModel>(TestModel.new, const [
      PropertyTransformer<String>("first"),
      PropertyTransformer<String?>("last"),
      PropertyTransformer<List<Image>>("images"),
    ]);

    final model = TestModel({
      "firstName": "Mike",
      "lastName": "Jones",
      "myImages": [
        {"imageUrl": "https://www.example.com/image1.jpg", "imageCaption": "#1"},
        {"imageUrl": "https://www.example.com/image2.jpg", "imageCaption": "#2"},
      ]}, translation: PropertyTranslation({
        "firstName": "first",
        "lastName": "last",
        "myImages": "images",
        "myImages.imageUrl": "images.url",
        "myImages.imageCaption": "images.caption",
      })
    );

    expect(model, {
      'first': 'Mike',
      'last': 'Jones',
      'images': [
        {'url': 'https://www.example.com/image1.jpg', 'caption': '#1'},
        {'url': 'https://www.example.com/image2.jpg', 'caption': '#2'}
      ]
    });
  });

  test('Assert simple list of lists of models w/ full translation and specific source indexes', () {
    XWidget.registerModel<TestModel>(TestModel.new, const [
      PropertyTransformer<String>("first"),
      PropertyTransformer<String?>("last"),
      PropertyTransformer<List<List<Image>>>("images"),
    ]);

    final model = TestModel({
      "firstName": "Mike",
      "lastName": "Jones",
      "myImages": [
        {"imageUrl": "https://www.example.com/image1.jpg", "imageCaption": "#1"},
        {"imageUrl": "https://www.example.com/image2.jpg", "imageCaption": "#2"},
        {"imageUrl": "https://www.example.com/image3.jpg", "imageCaption": "#3"},
      ]}, translation: PropertyTranslation({
        "firstName": "first",
        "lastName": "last",
        "myImages[0].imageUrl": "images.url",
        "myImages[0].imageCaption": "images.caption",
        "myImages[2].imageUrl": "images.url",
        "myImages[2].imageCaption": "images.caption",
      })
    );

    expect(model, {
      'first': 'Mike',
      'last': 'Jones',
      'images': [
        [{'url': 'https://www.example.com/image1.jpg', 'caption': '#1'}],
        [{'url': 'https://www.example.com/image3.jpg', 'caption': '#3'}]
      ]
    });
  });

  test('Assert simple list of lists of models w/ full translation an no source indexes', () {
    XWidget.registerModel<TestModel>(TestModel.new, const [
      PropertyTransformer<String>("first"),
      PropertyTransformer<String?>("last"),
      PropertyTransformer<List<List<Image>>>("images"),
    ]);

    final model = TestModel({
        "firstName": "Mike",
        "lastName": "Jones",
        "myImages": [
          {"imageUrl": "https://www.example.com/image1.jpg", "imageCaption": "#1"},
          {"imageUrl": "https://www.example.com/image2.jpg", "imageCaption": "#2"},
          {"imageUrl": "https://www.example.com/image3.jpg", "imageCaption": "#3"},
        ]
      }, translation: PropertyTranslation({
        "firstName": "first",
        "lastName": "last",
        "myImages": "images",
        "myImages.imageUrl": "images.url",
        "myImages.imageCaption": "images.caption",
      })
    );

    expect(model, {
      'first': 'Mike',
      'last': 'Jones',
      'images': [
        [{'url': 'https://www.example.com/image1.jpg', 'caption': '#1'}],
        [{'url': 'https://www.example.com/image2.jpg', 'caption': '#2'}],
        [{'url': 'https://www.example.com/image3.jpg', 'caption': '#3'}],
      ]
    });
  });

  test('Assert that a unregistered property types that need conversion are checked', () {
    XWidget.registerModel<TestModel>(TestModel.new, const [
      PropertyTransformer<String>("first"),
      PropertyTransformer<String?>("last"),
      PropertyTransformer<Status>("status"),
    ]);

    expect(
      () => TestModel({
        "firstName": "Mike",
        "lastName": "Jones",
        "status": "active",
      }, translation: PropertyTranslation({
        "firstName": "first",
        "lastName": "last",
      })),
      exceptionStartsWith("Exception: Type converter function not registered for type 'Status'.")
    );
  });

  test("Assert that a unregistered property types that don't need conversion work", () {
    XWidget.registerModel<TestModel>(TestModel.new, const [
      PropertyTransformer<String>("first"),
      PropertyTransformer<String?>("last"),
      PropertyTransformer<Status>("status"),
    ]);

    final model = TestModel({
      "firstName": "Mike",
      "lastName": "Jones",
      "status": Status.active,
    }, translation: PropertyTranslation({
      "firstName": "first",
      "lastName": "last",
    }));

    expect(model, {
      'first': 'Mike',
      'last': 'Jones',
      'status': Status.active
    });
  });

  test('Assert default value is returned when the transformed value is null', () {
    XWidget.registerModel<TestModel>(TestModel.new, const [
      PropertyTransformer<String>("first"),
      PropertyTransformer<String?>("last"),
      PropertyTransformer<String?>("status", defaultValue: "active"),
    ]);

    final model = TestModel({
        "firstName": "Mike",
        "lastName": "Jones",
      }, translation: PropertyTranslation({
        "firstName": "first",
        "lastName": "last",
      })
    );

    expect(model, {
      'first': 'Mike',
      'last': 'Jones',
      'status': 'active'
    });
  });

  test('Assert default value is returned and no errors when non-nullable transformed value is null', () {
    XWidget.registerModel<TestModel>(TestModel.new, const [
      PropertyTransformer<String>("first"),
      PropertyTransformer<String?>("last"),
      PropertyTransformer<String>("status", defaultValue: "active"),
    ]);

    final model = TestModel({
        "firstName": "Mike",
        "lastName": "Jones",
      }, translation: PropertyTranslation({
        "firstName": "first",
        "lastName": "last",
      })
    );

    expect(model.errors, {});
    expect(model, {
      'first': 'Mike',
      'last': 'Jones',
      'status': 'active'
    });
  });

  test('Assert properties with same name in different objects are mapped correctly w/o translation', () {
    XWidget.registerModel<TestModel>(TestModel.new, const [
      PropertyTransformer<String>("title"),
      PropertyTransformer<String?>("url"),
      PropertyTransformer<Image>("image"),
    ]);

    final model = TestModel({
      "title": "Happy World",
      "url": "https://www.example.com",
    });

    expect(model, {
      'title': 'Happy World',
      'url': 'https://www.example.com',
    });
  });

  test('Assert immutable models', () {
    XWidget.registerModel<TestModel>(TestModel.new, const [
      PropertyTransformer<String>("title"),
      PropertyTransformer<Image>("image"),
    ]);

    final model = TestModel({
        "title": "Happy World",
        "url": "https://www.example.com",
      }, translation: PropertyTranslation({
        "url": "image.url"
      }), immutable: true
    );

    expect(model, {
      'title': 'Happy World',
      'image': {'url': 'https://www.example.com'}
    });
    expect(model.immutable, true);
    expect(model["image"].immutable, true);
  });

  test('Assert immutable list', () {
    XWidget.registerModel<TestModel>(TestModel.new, const [
      PropertyTransformer<String>("title"),
      PropertyTransformer<List<Image>>("images"),
    ]);

    final model = TestModel({
        "title": "Happy World",
        "url": "https://www.example.com",
      }, translation: PropertyTranslation({
        "url": "images.url"
      }), immutable: true
    );

    expect(model, {
      'title': 'Happy World',
      'images': [{'url': 'https://www.example.com'}]
    });
    expect(model.immutable, true);
    expect(model["images"][0].immutable, true);

    try {
      model["images"].add(Image({}));
    } catch (e) {
      expect(e, isUnsupportedError);
    }
  });

  test('Assert immutable set', () {
    XWidget.registerModel<TestModel>(TestModel.new, const [
      PropertyTransformer<String>("title"),
      PropertyTransformer<Set<Image>>("images"),
    ]);

    final model = TestModel({
        "title": "Happy World",
        "url": "https://www.example.com",
      }, translation: PropertyTranslation({
        "url": "images.url"
      }), immutable: true
    );

    expect(model, {
      'title': 'Happy World',
      'images': [{'url': 'https://www.example.com'}]
    });
    expect(model.immutable, true);
    expect(model["images"].elementAt(0).immutable, true);

    try {
      model["images"].add(Image({}));
    } catch (e) {
      expect(e, isUnsupportedError);
    }
  });

  test('Assert dynamic property returns String when data is String', () {
    XWidget.registerModel<TestModel>(TestModel.new, const [
      PropertyTransformer<String>("title"),
      PropertyTransformer("image"),
    ]);

    final model = TestModel({
      "title": "Happy World",
      "image": "https://www.example.com",
    });

    expect(model, {
      'title': 'Happy World',
      'image': 'https://www.example.com'
    });
  });

  test('Assert dynamic property returns int when data is int', () {
    XWidget.registerModel<TestModel>(TestModel.new, const [
      PropertyTransformer<String>("title"),
      PropertyTransformer("count"),
    ]);

    final model = TestModel({
      "title": "Happy World",
      "count": 5,
    });

    expect(model, {
      'title': 'Happy World',
      'count': 5
    });
  });

  test('Assert dynamic property returns whatever object is in the data', () {
    XWidget.registerModel<TestModel>(TestModel.new, const [
      PropertyTransformer<String>("title"),
      PropertyTransformer("something"),
    ]);

    final something = Unregistered("a");
    final model = TestModel({
      "title": "Happy World",
      "something": something,
    });

    expect(model, {
      'title': 'Happy World',
      'something': something
    });
  });

  test('Assert simple map transformation', () {
    XWidget.registerModel<TestModel>(TestModel.new, const [
      PropertyTransformer<String>("title"),
      PropertyTransformer<Map<String, int>>("map"),
    ]);

    final model = TestModel({
      "title": "Happy World",
      "map": {
        "a": "1",
        "b": 2
      }
    });

    expect(model, {
      'title': 'Happy World',
      'map': { "a": 1, "b": 2 }
    });
  });

  test('Assert list of Strings to map transformation', () {
    XWidget.registerModel<TestModel>(TestModel.new, const [
      PropertyTransformer<String>("title"),
      PropertyTransformer<Map<String, int>>("map"),
    ]);

    final model = TestModel({
      "title": "Happy World",
      "list": [ "1", "2" ]
    }, translation: PropertyTranslation({
      "list": "map"
    }));

    expect(model, {
      'title': 'Happy World',
      'map': { "0": 1, "1": 2 }
    });
  });

  test('Assert can add list of models with keys to map', () {
    XWidget.registerModel<TestModel>(TestModel.new, const [
      PropertyTransformer<String>("title"),
      PropertyTransformer<Map<String, Image>>("map"),
    ]);

    final model = TestModel({
      "title": "Happy World",
      "list": [
        { "imageUrl": "www.example.com/img1.png" },
        { "imageUrl": "www.example.com/img2.png" }
      ]
    }, translation: PropertyTranslation({
      "list": "map",
      "list.imageUrl": "map.url",
    }));

    expect(model, {
      'title': 'Happy World',
      'map': {
        'www.example.com/img1.png': {'url': 'www.example.com/img1.png'},
        'www.example.com/img2.png': {'url': 'www.example.com/img2.png'}
      }
    });
  });

  test('Assert can add list of models with keys to map', () {
    XWidget.registerModel<TestModel>(TestModel.new, const [
      PropertyTransformer<String>("title"),
      PropertyTransformer<Map<String, Image>>("map"),
    ]);

    final model = TestModel({
      "title": "Happy World",
      "list": [
        { "imageUrl": "www.example.com/img1.png" },
        { "imageUrl": "www.example.com/img2.png" }
      ]
    }, translation: PropertyTranslation({
      "list": "map",
      "list.imageUrl": "map.url",
    }));

    expect(model, {
      'title': 'Happy World',
      'map': {
        'www.example.com/img1.png': {'url': 'www.example.com/img1.png'},
        'www.example.com/img2.png': {'url': 'www.example.com/img2.png'}
      }
    });
  });

  test('Assert empty model does not throw an exception', () {
    XWidget.registerModel<TestModel>(TestModel.new, const [
      PropertyTransformer<String>("title"),
      PropertyTransformer<Image?>("image"),
    ]);

    final model = TestModel({
      "title": "Happy World",
      "image": ""
    });

    expect(model, {
      'title': 'Happy World',
    });
  });

  test('Assert transform function defined in PropertyTransformer is called', () {

    String? upperCase(dynamic value) {
      if (value == null) return null;
      if (value is String) return value.toUpperCase();
      return value.toString().toUpperCase();
    }

    XWidget.registerModel<TestModel>(TestModel.new, [
      PropertyTransformer<String>("name", converter: upperCase),
      const PropertyTransformer<String>("email"),
    ]);

    final model = TestModel({
      "name": "Mike",
      "email": "mike@example.com",
    });

    expect(model, {
      'name': "MIKE",
      'email': 'mike@example.com',
    });
  });
}

enum Status {
  active, inactive
}

class TestModel extends Model {
  TestModel(super.data, {super.translation, super.immutable});
}

class Person extends Model {
  Person(super.data, {super.translation, super.immutable});
}

class Image extends Model {
  Image(super.data, {super.translation, super.immutable});
}

class Profile extends Model {
  String get username => getValue("username");
  String get email => getValue("email");
  String? get name => getValue("name");
  DateTime? get lastLogin => getValue("lastLogin");

  Profile({
    required String username,
    required String email,
    String? name,
    DateTime? lastLogin,
  }): super({
    "username": username,
    "email": email,
    "name": name,
    "lastLogin": lastLogin,
  });

  Profile.import(super.data, {super.translation, super.immutable});
}

class Unregistered {
  final String id;

  Unregistered(this.id);
}