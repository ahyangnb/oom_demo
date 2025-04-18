import 'package:flutter/material.dart';

/// 可拖动容器
class SFDragWidget extends StatefulWidget {
  final Widget child;
  const SFDragWidget({
    super.key,
    required this.child,
  });
  @override
  State<SFDragWidget> createState() => _SFDragWidgetState();
}

class _SFDragWidgetState extends State<SFDragWidget> {
  final GlobalKey _mykey = GlobalKey();
  final _offset = ValueNotifier<Offset>(Offset.zero);
  var _unlimtedOffset = Offset.zero;
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _offset,
      builder:
          (context, offset, widget) => Transform.translate(
        key: _mykey,
        offset: offset,
        child: GestureDetector(
          child: this.widget.child,
          onPanUpdate: (detail) {
            var off = _unlimtedOffset = _unlimtedOffset + detail.delta;
            RenderBox? parentRenderBox = _mykey.currentContext
                ?.findAncestorRenderObjectOfType<RenderObject>() as RenderBox?;
            final screenSize = parentRenderBox?.size;
            final mySize = _mykey.currentContext?.size;
            final renderBox =
            _mykey.currentContext?.findRenderObject() as RenderBox?;
            var originOffset = renderBox?.localToGlobal(Offset.zero);
            if (originOffset != null) {
              originOffset = parentRenderBox?.globalToLocal(originOffset);
            }
            if (screenSize == null || mySize == null || originOffset == null) {
              return;
            }
            if (off.dx < -originOffset.dx) {
              off = Offset(-originOffset.dx, off.dy);
            } else if (off.dx >
                screenSize.width - mySize.width - originOffset.dx) {
              off = Offset(
                screenSize.width - mySize.width - originOffset.dx,
                off.dy,
              );
            }
            if (off.dy < -originOffset.dy) {
              off = Offset(off.dx, -originOffset.dy);
            } else if (off.dy >
                screenSize.height - mySize.height - originOffset.dy) {
              off = Offset(
                off.dx,
                screenSize.height - mySize.height - originOffset.dy,
              );
            }
            //现在活动区域为父控件 --end
            _offset.value = off;
          },
        ),
      ),
    );
  }
}