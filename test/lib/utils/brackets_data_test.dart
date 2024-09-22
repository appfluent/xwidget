import 'package:flutter_test/flutter_test.dart';

import '../../../lib/xwidget.dart';


main() {
  test('Assert can get nested data', () {
    final account = Account({"number": "001", "amount": 99999999999999});
    final user = User({"name": "Chris", "account": account});

    final accountNumber = user.getValue("account.number");
    expect(accountNumber, "001");
  });
}

class User extends Model {
  String get name => this["name"];
  String get account => this["account"];

  User(super.data);
}

class Account extends Model {
  String get number => this["number"];
  int get amount => this["amount"];

  Account(super.data);
}