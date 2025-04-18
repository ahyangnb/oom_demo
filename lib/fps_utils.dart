import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:oom_demo/dana_drag.dart';

class FPSOverlay extends StatefulWidget {
  @override
  _FPSOverlayState createState() => _FPSOverlayState();
}

class _FPSOverlayState extends State<FPSOverlay> {
  static const platform = MethodChannel('com.example.fpsoverlay/system');
  int _frameCount = 0;
  int _currentFPS = 0;
  DateTime _startTime = DateTime.now();
  String _cpuUsage = "N/A";
  String _memoryUsage = "N/A";

  @override
  void initState() {
    super.initState();
    _startFPSMonitoring();
    _fetchSystemStats();
  }

  void _startFPSMonitoring() {
    SchedulerBinding.instance.addPersistentFrameCallback((timeStamp) {
      _frameCount++;
      final duration = DateTime.now().difference(_startTime);

      if (duration.inMilliseconds >= 1000) {
        setState(() {
          _currentFPS = _frameCount;
        });
        _fetchSystemStats();
        _frameCount = 0;
        _startTime = DateTime.now();
      }

      SchedulerBinding.instance.scheduleFrame();
    });
  }

  Future<void> _fetchSystemStats() async {
    try {
      final result = await platform.invokeMethod<Map>('getSystemStats');
      setState(() {
        _cpuUsage = result?['cpu'] ?? 'N/A';
        _memoryUsage = result?['memory'] ?? 'N/A';
      });
    } on PlatformException catch (e) {
      print("Failed to get system stats: ${e.message}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 50,
      left: 10,
      child: SFDragWidget(child:RepaintBoundary(child:_buildStatsWidget())),
    );
  }

  Widget _buildStatsWidget() {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 160,
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current FPS: $_currentFPS', style: TextStyle(color: Colors.white, fontSize: 16)),
            SizedBox(height: 8),
            Text('CPU Usage: $_cpuUsage%', style: TextStyle(color: Colors.white, fontSize: 14)),
            SizedBox(height: 4),
            Text('Memory: $_memoryUsage MB', style: TextStyle(color: Colors.white, fontSize: 14)),
            Text('Byte: ${(PaintingBinding.instance.imageCache.currentSizeBytes / (1024 * 1024)).toInt() } mb', style: TextStyle(color: Colors.white, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
