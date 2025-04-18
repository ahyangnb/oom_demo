import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class VapViewForIos extends StatelessWidget {
  final Map<String, dynamic> creationParams;

  const VapViewForIos({
    Key? key,
    this.creationParams = const <String, dynamic>{},
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print(creationParams);
    return UiKitView(
      viewType: "flutter_vap",
      layoutDirection: TextDirection.ltr,
      creationParams: creationParams,
      creationParamsCodec: StandardMessageCodec(),
    );
  }
}
