import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'vap_dio_utils.dart';

typedef QueneCallback = Function(dynamic data,dynamic data1);

class QueueUtil {
  static Map<String, QueueUtil> _instance = Map<String, QueueUtil>();

  static QueueUtil? get(String key) => _instance[key];

  static init(String key) {
    if (_instance[key] == null) {
      _instance[key] = QueueUtil.add(key);
      print("initKey $key");
    }
  }

  static remove(String key) {
    print("remove $key");
    _instance.remove(key);
  }

  QueueUtil.add(String key) {
    _key = key;
    _channel = MethodChannel('flutter_vap_controller_$_key');
  }

  String _key = "";
  late MethodChannel _channel;

  static Directory? _vapDownloadDir; //vap下载目录
  var prePlayVapEntityList = <PlayVapEntity>[].obs; //Vap播放队列
  Map<String, DateTime> _lastAddedTimeMap = {}; // 新增的时间记录
  static const Duration _addGiftCooldown =
      Duration(milliseconds: 2000); // 时间窗口，秒内只允许添加一个相同的礼物

  /// 单独播放路径
  /// return: play error:       {"status": "failure", "errorMsg": ""}
  ///         play complete:    {"status": "complete"}
  Future<Map<dynamic, dynamic>?> playPath(String path, String vapInfo,
      {String fill = "1"}) async {
    try {
      return _channel.invokeMethod(
          'playPath', {"path": path, "vapInfo": vapInfo, "fill": fill});
    } catch (e) {
      print("Error in playPath: $e");
      return {};
    }
  }

  Future<Map<dynamic, dynamic>?> playAsset(String asset, String vapInfo,
      {String fill = "1"}) async {
    try {
      return _channel.invokeMethod(
          'playAsset', {"asset": asset, "vapInfo": vapInfo, "fill": fill});
    } catch (e) {
      return {};
    }
  }

  /// 停止播放
  _stop() async {
    print('调用停止$_key');
    try {
      print("停止播放开始$_key");
      await _channel.invokeMethod('stop');
      print("停止播放结束$_key");
    } catch (e) {
      print("停止播放 $_key $e");
    }
  }

  ///添加本地Vap队列
  addLocalTask(String assets, String? vapInfo,
      {GiftType giftType = GiftType.vap,
        String fill = "1",
        QueneCallback? callBack,
        dynamic extra,
        dynamic extra1}) async {
    var entity = PlayVapEntity(
      assets,
      vapInfo ?? "",
      fill: fill,
      callBack: callBack,
      giftType: giftType,
      playEmptyMillisecond: 0,
      extra: extra,
      extra1: extra1,
      local: true,
    );
    if(prePlayVapEntityList.isEmpty){
      prePlayVapEntityList.add(entity);
      print("❤️ 本地动画队列个数只有一个 ${prePlayVapEntityList.length}");
    }else{
      prePlayVapEntityList.value.add(entity);
      print("❤️ 本地动画队列个数不止只有一个 ${prePlayVapEntityList.length}");
    }
    // 如果队列中只有一个礼物，开始播放
    if (prePlayVapEntityList.length == 1) {
      _downloadVap(prePlayVapEntityList.first);
    }
  }

  /// 添加动画播放队列
  addTask(
    String url, {
    String fill = "1",
    String? vapInfo,
    QueneCallback? callBack,
    GiftType giftType = GiftType.vap,
    int? playEmptyMillisecond, //等待空白播放时长ms
    Map? extra,
    int? price,
  }) {
    print("❤️ 添加动画队列 $url");
    String giftKey = "$url|$giftType"; // 用url和giftType作为唯一标识符
    if (prePlayVapEntityList.isEmpty) {
      _addGiftToQueue(url, vapInfo, giftType, playEmptyMillisecond, extra,
          callBack, price, fill);
      return;
    }
    // 检查是否冷却时间未过
    if (_lastAddedTimeMap.containsKey(giftKey) &&
        DateTime.now().difference(_lastAddedTimeMap[giftKey]!) <
            _addGiftCooldown) {
      return;
    }
    _lastAddedTimeMap[giftKey] = DateTime.now();
    _addGiftToQueue(url, vapInfo, giftType, playEmptyMillisecond, extra,
        callBack, price, fill);
  }

  // 封装礼物添加到队列的逻辑
  _addGiftToQueue(
    String url,
    String? vapInfo,
    GiftType giftType,
    int? playEmptyMillisecond,
    Map? extra,
    QueneCallback? callBack,
    int? price,
    String? fill,
  ) {
    var entity = PlayVapEntity(url, vapInfo ?? "",
        giftType: giftType,
        playEmptyMillisecond: playEmptyMillisecond,
        extra: extra,
        fill: fill,
        callBack: callBack,
        price: price);
    if(prePlayVapEntityList.isEmpty){
      prePlayVapEntityList.add(entity);
      print("❤️ 网络动画队列个数只有一个 ${prePlayVapEntityList.length}");
    }else{
      prePlayVapEntityList.value.add(entity);
      print("❤️ 网络动画队列个数不止只有一个 ${prePlayVapEntityList.length}");
    }
    if (prePlayVapEntityList.value.length == 1) {
      _downloadVap(prePlayVapEntityList.first);
    } else {

    }
  }

  /// 清空vap队列 并停止播放
  clear({bool canStop = true}) async {
    print('$_key clear $canStop');
    _stop();
    stopSvga?.call();
    prePlayVapEntityList.clear();
    _lastAddedTimeMap.clear();
  }

  /// 清空vap队列
  clearAnimQueue() {
    print("清空队列");
    prePlayVapEntityList.clear();
  }

  /// 预缓存
  /// Exception: 不影响主流程。
  static Future<void> preCacheAnimation(String url) async {
    try {
      // Check network connectivity first
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none) ||
          connectivityResult.isEmpty) {
        log("[预加载] No network connection available");
        return;
      }

      if (url.isEmpty) {
        log("[预加载] the url is empty.");
        return;
      }
      final String animPath = await getAnimPathByUrl(url);
      log("[预加载] preCacheAnimation animPath ==> $animPath");
      if (await isGiftCached(url)) {
        log("[预加载] File already exists and file is completed");
        return;
      }

      // Download with smaller chunks
      await VapDioUtils().downloadGeneral(url, animPath,
          onReceiveProgress: (count, total) {
        log("[预加载] Downloaded: $count/$total, url ==> $url");
      }, onCompletion: (data) {
        log("[预加载] Download completed, url ==> $url");

        /// 在downloadGeneral里面会自动设置DownloadRecordDb.insert(url);
      }, onError: (String code, String msg) {
        log("[预加载] Download failed, url ==> $url, code: $code, msg: $msg");
      });
    } catch (e, s) {
      log("[预加载] Error: $e, StackTrace: $s");
    }
  }

  static Future<String> getAnimPathByUrl(String url) async {
    var directory = await getGiftDownloadDir();
    return "${directory.path}/$url";
  }

  static Future<String> getAnimPath(PlayVapEntity entity) async {
    /// Check if the animation without file and md5.
    if (entity.url.isEmpty) {
      return '';
    }
    if (entity.giftType == GiftType.vap || entity.giftType == GiftType.svga) {
      /// update: 使用url作为文件名后缀会自带".mp4"或".svga"后缀，所以不需要再添加后缀。
      return getAnimPathByUrl(entity.url);
    } else if (entity.giftType == GiftType.empty) {
      return "";
    }
    throw Exception("UnHandle `GiftType`.");
  }

  /// 下载vap
  _downloadVap(PlayVapEntity entity) async {
    if (entity.local == true) {
      entity.status = VapStatus.completion;
      _playVap();
      return;
    }
    if (entity.status == VapStatus.undownload) {
      String animPath = await getAnimPath(entity);
      if (animPath.isEmpty) {
        entity.status = VapStatus.completion;
        _playVap();
        return;
      }
      if (await isGiftCached(entity.url)) {
        entity.localPath = animPath;
        entity.status = VapStatus.completion;
        _playVap();
      } else {
        entity.status = VapStatus.downloading;
        VapDioUtils().downloadGeneral(entity.url, animPath,
            onReceiveProgress: (int count, int total) {
          if (kDebugMode) {
            print("${entity.url}下载进度 $count/$total");
          }
        }, onCompletion: (res) {
          /// 在downloadGeneral里面会自动设置DownloadRecordDb.insert(url);
          entity.localPath = animPath;
          entity.status = VapStatus.completion;
          _playVap();
        }, onError: (code, msg) {
          entity.status = VapStatus.failure;
          _playVap();
        });
      }
    } else {
      _playVap();
    }
  }

  Function(PlayVapEntity entity)? playSvga;
  Function()? stopSvga;

  StreamController<PlayVapEntity?> playController =
      StreamController<PlayVapEntity?>.broadcast();

  /// 播放vap
  _playVap() async {
    if (prePlayVapEntityList.isEmpty) {
      return;
    }
    PlayVapEntity first = prePlayVapEntityList.first;
    if (first.status == VapStatus.completion) {
      first.status = VapStatus.playing;
      playController.sink.add(first);
      if (first.giftType == GiftType.vap) {
        try {
          if (prePlayVapEntityList.isEmpty) {
            return;
          }
          if (Platform.isIOS && prePlayVapEntityList.length == 1) {
            await Future.delayed(const Duration(milliseconds: 100), () {});
          }
          if (prePlayVapEntityList.isEmpty) {
            return;
          }
          print("开始播放vap ${first.local == true ? "本地" : "网络"} ${first.url}");
          if (first.local == true) {
            var map = await playAsset(first.url, first.vapInfo,
                fill: first.fill ?? "1");
            if (prePlayVapEntityList.isEmpty) {
              print("prePlayVapEntityList has empty");
              if (first.callBack != null) {
                first.callBack!(first.extra,first.extra1);
              }
              return;
            }
            print("播放结果 $map");
          } else {
            var map = await playPath(first.localPath!, first.vapInfo,
                fill: first.fill ?? "1");
            if (prePlayVapEntityList.isEmpty) {
              print("prePlayVapEntityList has empty");
              if (first.callBack != null) {
                first.callBack!(first.extra,first.extra1);
              }
              return;
            }
            print("播放结果 $map");
          }
          playComplete(first);
        } catch (e) {
          print("播放异常 ${e.toString()}");
          playComplete(first);
        }
      } else if (first.giftType == GiftType.svga) {
        print("开始播放svga");
        if (playSvga != null) {
          playSvga!.call(first);
        } else {
          playComplete(first);
        }
      } else if (first.giftType == GiftType.empty) {}
      if (prePlayVapEntityList.length > 1 &&
          prePlayVapEntityList[1].status == VapStatus.undownload) {
        _downloadVap(prePlayVapEntityList[1]);
      }
    } else if (first.status == VapStatus.failure) {
      prePlayVapEntityList.remove(first);
      if (prePlayVapEntityList.isNotEmpty) {
        _downloadVap(prePlayVapEntityList.first);
      }
    }
  }

  playComplete(PlayVapEntity? entity) {
    playController.sink.add(null);
    bool isExist = false;
    if (entity?.callBack != null) {
      entity?.callBack!(entity.extra,entity.extra1);
    }
    if (entity != null && prePlayVapEntityList.value.contains(entity)) {
      isExist = true;
      prePlayVapEntityList.value.remove(entity);
    }
    if (prePlayVapEntityList.isNotEmpty) {
      _downloadVap(prePlayVapEntityList.first);
    }else{
      prePlayVapEntityList.refresh();
    }
  }

  /// 获取Vap下载文件目录
  static Future<Directory> getGiftDownloadDir() async {
    try {
      if (_vapDownloadDir != null && _vapDownloadDir!.existsSync()) {
        return _vapDownloadDir!;
      }
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      String downloadPath = "${documentsDirectory.path}/vap";
      _vapDownloadDir = Directory(downloadPath);
      if (!_vapDownloadDir!.existsSync()) {
        await _vapDownloadDir!.create(recursive: true);
      }
      return _vapDownloadDir!;
    } catch (e) {
      log('Failed to get/create download directory: $e');
      rethrow;
    }
  }

  /// @return null: 不需要处理
  ///
  /// 使用场景：
  /// 检测当前文件没有cached时开始走cache逻辑。
  static Future<bool> isGiftCached(String url) async {
    try {
      final String animPath = await getAnimPathByUrl(url);
      return File(animPath).existsSync();
    } catch (e) {
      log("[Cache Check] Exception: $e");
      return false;
    }
  }
}

enum VapStatus {
  undownload,
  downloading,
  completion,
  playing,
  failure,
}

enum GiftType {
  vap,
  svga,
  empty,
}

class PlayVapEntity {
  final String url;
  final String vapInfo;
  String? localPath;
  VapStatus status;
  GiftType giftType;
  bool? local;
  int? playEmptyMillisecond; //等待空白播放时长ms
  dynamic extra;
  dynamic extra1;
  String? fill;
  QueneCallback? callBack;
  int? price;

  PlayVapEntity(
    this.url,
    this.vapInfo, {
    this.localPath,
    this.callBack,
    this.status = VapStatus.undownload,
    this.giftType = GiftType.vap,
    this.local = false,
    this.fill = "1",
    this.playEmptyMillisecond,
    this.extra, this.extra1,
    this.price,
  });
}

/// 预加载的礼物id列表【第一队列，因为这些是常用的】，除了这一批后面的都可以后续再加载。
const List<String> precacheGiftIdList = [
  "60724",
  "60612",
  "60731",
  "60615",
  "60730",
  "60732",
  "60695",
  "60614",
  "60739",
  "60686",
  "60733",
  "60735",
  "60685",
  "60725",
  "60734",
  "60694",
  "60740",
  "60737",
  "60738",
  "60616",
  "60693",
  "60619",
  "60687",
  "60617",
  "60622",
  "60692",
  "60620",
  "60696",
  "60618",
  "60613",
  "60691",
  "60690",
  "60689",
  "60621",
  "60639"
];
