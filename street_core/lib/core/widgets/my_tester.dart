import 'package:flutter/material.dart';
import 'package:street_core/core/lang/locale_keys.dart';
import 'package:street_core/core/widgets/my_text.dart';

import 'my_container.dart';

// ignore: must_be_immutable
class MyTester extends StatelessWidget {
  MyTester({super.key, this.text});
  String? text;
  @override
  Widget build(BuildContext context) {
    return MyContainer(
      width: 300,
      height: 300,
      color: Theme.of(context).cardColor,
      child: Column(
        children: [const MyText('Hola Mundo', noTranslation: true), MyText(text ?? LocaleKeys.testWidget)],
      ),
    );
  }
}
