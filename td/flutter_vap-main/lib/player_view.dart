import 'package:flutter/material.dart';
import 'package:flutter_vap/queue_util.dart';

import 'vap_view.dart';

class PlayerView extends StatefulWidget {
  final String tag;
  final bool ignoring;
  final bool autoRemove;
  const PlayerView({
    Key? key,
    required this.tag,
    this.ignoring = true,
    this.autoRemove = true,
  }) : super(key: key);

  @override
  State<PlayerView> createState() => _PlayerViewState();
}

class _PlayerViewState extends State<PlayerView> with WidgetsBindingObserver {
  @override
  void initState() {
    if (widget.autoRemove) {
      QueueUtil.init(widget.tag);
    }
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    _disposeAction();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  _disposeAction() async {
    print("${widget.tag}被销毁了");
    await QueueUtil.get(widget.tag)?.clear();
    if (widget.autoRemove) {
      print("进入自动清理");
      QueueUtil.remove(widget.tag);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        QueueUtil.get(widget.tag)?.clearAnimQueue();
        break;
      case AppLifecycleState.paused:
        QueueUtil.get(widget.tag)?.clearAnimQueue();
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: widget.ignoring,
      child: VapView(
        creationParams: {"key": widget.tag},
      ),
    );
  }
}
