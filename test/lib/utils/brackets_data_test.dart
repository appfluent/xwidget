import 'package:flutter_test/flutter_test.dart';

import 'package:xwidget/xwidget.dart';


main() {
  test('Assert setValue', () {
    final account = Account({"number": "001", "amount": 99999999999999});
    final user = User({"name": "Chris", "account": account});

    final accountNumber = user.getValue("account.number");
    expect(accountNumber, "001");
  });
}


class User extends Data {
  String get name => this["name"];
  String get account => this["account"];
  User(Map<String, dynamic> params, [bool immutable = true]): super(params, immutable);
}

class Account extends Data {
  String get number => this["number"];
  int get amount => this["amount"];
  Account(Map<String, dynamic> params, [bool immutable = true]): super(params, immutable);
}