import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_vap/vap_view_for_android.dart';
import 'package:flutter_vap/vap_view_for_ios.dart';

class VapView extends StatelessWidget {
  final Map<String, dynamic> creationParams;

  const VapView({
    Key? key,
    this.creationParams = const <String, dynamic>{},
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      return VapViewForAndroid(
        creationParams: creationParams,
      );
    } else if (Platform.isIOS) {
      return VapViewForIos(
        creationParams: creationParams,
      );
    }
    return Container();
  }
}
