import 'package:flutter_test/flutter_test.dart';

import '../../../../lib/xwidget.dart';

main() {

  setUpAll(() {
    XWidget.registerModel<TestModel>(TestModel.new, const [
      PropertyTransformer<String>("key", isKey: true),
      PropertyTransformer<String>("name"),
    ]);
  });

  test('Assert import without translation', () {
    final model1 = TestModel.keyedInstance("t1", {
      "key": "t1",
      "name": "t1"
    });
    final model2 = TestModel.keyedInstance("t1", {
      "key": "t1",
      "name": "t2"
    });

    expect(
        identical(model1, model2),
        true,
        reason: "Expected model1 and model2 to be the same object, aka identical"
    );
  });
}

class TestModel extends Model {
  TestModel(super.data, {super.translation, super.immutable});

  factory TestModel.keyedInstance(
    String keyProperty, [
    Map<String, dynamic>? data,
    PropertyTranslation? translation
  ]) {
    return Model.keyedInstance<TestModel>(
      data: data,
      factory: TestModel.new,
      translation: translation
    );
  }

  factory TestModel.singleInstance([
    Map<String, dynamic>? data,
    PropertyTranslation? translation
  ]) {
    return Model.singleInstance<TestModel>(
      data: data,
      factory: TestModel.new,
      translation: translation
    );
  }
}