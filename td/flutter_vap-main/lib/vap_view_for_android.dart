import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class VapViewForAndroid extends StatelessWidget {
  final Map<String, dynamic> creationParams;

  const VapViewForAndroid({
    Key? key,
    this.creationParams = const <String, dynamic>{},
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AndroidView(
      viewType: "flutter_vap",
      layoutDirection: TextDirection.ltr,
      creationParams: creationParams,
      creationParamsCodec: StandardMessageCodec(),
    );
  }
}
