import 'package:card_swiper/card_swiper.dart';
import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vap/player_view.dart';
import 'package:flutter_vap/queue_util.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:marquee/marquee.dart';
import 'package:oom_demo/fps_utils.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui';
import 'dart:math';

import 'package:webview_flutter/webview_flutter.dart';

class CustomCacheManager {
  static const key = 'customCacheKey';
  static CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 600,
      repo: JsonCacheInfoRepository(databaseName: key),
      fileSystem: IOFileSystem(key),
      fileService: HttpFileService(),
    ),
  );
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  CachedNetworkImage.logLevel = CacheManagerLogLevel.debug;

  PaintingBinding.instance.imageCache.maximumSizeBytes = 300 << 20;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VAP Player Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      builder: (context, child) {
        return Stack(
          children: [
            child!,
            FPSOverlay(),
          ],
        );
      },
      home: const VapDemoPage(playTag: "demo_player"),
    );
  }
}

class VapDemoPage extends StatefulWidget {
  const VapDemoPage({super.key, required this.playTag});

  final String playTag;

  @override
  State<VapDemoPage> createState() => _VapDemoPageState();
}

class _VapDemoPageState extends State<VapDemoPage>
    with TickerProviderStateMixin {
  String get playerTag => widget.playTag;

  // Store multiple VAP players
  // 存储多个 VAP 播放器
  final List<String> _activePlayers = [];

  // Animation related variables
  // 动画相关变量
  List<AnimationGroup> _animationGroups =
      []; // Store multiple groups of animations
  bool _isAnimating = false;

  // Video URLs for demo
  final List<String> videoUrls = [
    'https://img.danachatapp.com/dress/mp4_18_39058f019433edda.mp4',
    'https://img.danachatapp.com/uploads/1744100300835-d6nure.mp4',
  ];

  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  final List<String> _imageUrls = List.generate(1550, getRandomImg);

  static String getRandomImg(int index) {
    final img = imagesList[index % imagesList.length];
    if (img.endsWith('.jpg')) {
      return '$img?hahahahah=${DateTime.now()}';
    } else {
      return '$img&hahahahah=${DateTime.now()}';
    }
  }

  void _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    setState(() {
      _imageUrls.shuffle();
    });
    _refreshController.refreshCompleted();
  }

  void _onLoading() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) {
      setState(() {
        _imageUrls.addAll(
          List.generate(
            10,
            (index) =>
                'https://loremflickr.com/100/100/music?lock=${_imageUrls.length + index}',
          ),
        );
      });
    }
    _refreshController.loadComplete();
  }

  @override
  void initState() {
    super.initState();
    // Initialize base player
    // 初始化基础播放器
    QueueUtil.init(playerTag);
  }

  @override
  void dispose() {
    // Clean up all VAP players
    // 清理所有 VAP 播放器
    for (var tag in _activePlayers) {
      QueueUtil.get(tag)?.clear();
      QueueUtil.remove(tag);
    }
    _activePlayers.clear();

    // Clean up base player
    // 清理基础播放器
    QueueUtil.get(playerTag)?.clear();
    QueueUtil.remove(playerTag);

    // Clean up all animation groups
    // 清理所有动画组
    for (var group in _animationGroups) {
      group.dispose();
    }
    _refreshController.dispose();

    super.dispose();
  }

  // Create explosion animation
  // 创建爆炸动画
  void _createExplosionAnimation() {
    print("Creating new animation group"); // Debug print

    setState(() {
      late final AnimationGroup group;
      group = AnimationGroup(
        vsync: this,
        onComplete: () {
          setState(() {
            // Remove the group when all its animations complete
            // 当所有动画完成时移除该组
            _animationGroups.remove(group);
          });
        },
      );
      _animationGroups.add(group);
    });
  }

  // Play a VAP video with a unique tag
  // 使用唯一标签播放 VAP 视频
  Future<void> _playVideo(String url) async {
    try {
      final uniqueTag = "player_${DateTime.now().millisecondsSinceEpoch}";

      // Initialize queue for this player
      // 初始化此播放器的队列
      QueueUtil.init(uniqueTag);

      // Add to active players after initialization
      // 初始化后添加到活动播放器列表
      setState(() {
        _activePlayers.add(uniqueTag);
      });

      // Wait for widget to build
      // 等待部件构建
      await Future.delayed(const Duration(milliseconds: 100));

      if (!mounted) return;

      // Play the video
      // 播放视频
      await QueueUtil.get(uniqueTag)?.addTask(
        url,
        fill: "1", // 1 for cover mode
        callBack: (data, data1) {
          if (!mounted) return;
          // Remove player when video completes
          // 视频完成时移除播放器
          setState(() {
            _activePlayers.remove(uniqueTag);
          });
          QueueUtil.get(uniqueTag)?.clear();
          QueueUtil.remove(uniqueTag);
          print('Video playback completed for $uniqueTag');
        },
      );
    } catch (e) {
      print('Error playing video: $e');
      // Clean up on error
      // 错误时清理
      final uniqueTag = "player_${DateTime.now().millisecondsSinceEpoch}";
      if (_activePlayers.contains(uniqueTag)) {
        setState(() {
          _activePlayers.remove(uniqueTag);
        });
        QueueUtil.get(uniqueTag)?.clear();
        QueueUtil.remove(uniqueTag);
      }

      // Show error to user
      // 向用户显示错误
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to play video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget buildSwiper(List<String> imageUrls) {
    return SizedBox(
      height: 100,
      child: Swiper(
        itemBuilder: (BuildContext context, int index) {
          return CachedNetworkImage(
            imageUrl: imageUrls[index],
            fit: BoxFit.cover,
          );
        },
        itemCount: imageUrls.length,
        autoplay: true,
        pagination: SwiperPagination(),
        control: SwiperControl(),
      ),
    );
  }

  late final flyImage = getRandomImg(10);

  late final sameImageImage = getRandomImg(19);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VAP Player Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(CupertinoPageRoute(builder: (context) {
                return GameWebViewPage();
              }));
            },
            icon: const Icon(Icons.web),
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(CupertinoPageRoute(builder: (context) {
                return VapDemoPage(playTag: "demo_player${DateTime.now()}");
              }));
            },
            icon: const Icon(Icons.play_circle),
          ),
        ],
      ),
      body: Stack(
        children: [
          SmartRefresher(
            enablePullDown: true,
            enablePullUp: true,
            header: const WaterDropHeader(),
            footer: CustomFooter(
              builder: (context, mode) {
                Widget body;
                if (mode == LoadStatus.idle) {
                  body = const Text("Pull up to load more");
                } else if (mode == LoadStatus.loading) {
                  body = const CupertinoActivityIndicator();
                } else if (mode == LoadStatus.failed) {
                  body = const Text("Load Failed! Click retry!");
                } else if (mode == LoadStatus.canLoading) {
                  body = const Text("Release to load more");
                } else {
                  body = const Text("No more Data");
                }
                return SizedBox(
                  height: 55.0,
                  child: Center(child: body),
                );
              },
            ),
            controller: _refreshController,
            onRefresh: _onRefresh,
            onLoading: _onLoading,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    child: Text("Hello"),
                  ),
                ),
                // Top Swiper
                SliverToBoxAdapter(
                  child: buildSwiper(List.generate(7, getRandomImg)),
                ),
                SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      final selectedImages = List.generate(5, getRandomImg);

                      final imgUrl = _imageUrls[index];
                      return InkWell(
                        /// -------------------------
                        /// 会重新loading
                        child: Stack(
                          children: [
                            CachedNetworkImage(
                              imageUrl: imgUrl,
                              width: 200,
                              height: 200,
                            ),
                            for (var i = 0; i < selectedImages.length; i++)
                              Positioned(
                                left: 40.0 * i,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                  child: ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: selectedImages[i],
                                      width: 20,
                                      height: 20,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            for (var i = 0; i < selectedImages.length; i++)
                              Positioned(
                                left: 40.0 * i,
                                bottom: 10,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                  child: ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: sameImageImage,
                                      width: 20,
                                      height: 20,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            Marquee(
                              text: 'There ',
                            ),
                            ExtendedText(
                              gradientConfig: GradientConfig(
                                gradient: const LinearGradient(
                                  colors: [Colors.red, Colors.black],
                                ),
                                ignoreWidgetSpan: true,
                                renderMode: GradientRenderMode.fullText,
                                blendMode: BlendMode.srcIn,
                              ),
                              "Current Index: $index",
                              style: const TextStyle(
                                  color: Colors.blue, fontSize: 14),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.of(context)
                              .push(CupertinoPageRoute(builder: (context) {
                            return Scaffold(
                              appBar: AppBar(),
                              body: NetworkImageWidget(
                                url: imgUrl,
                                width: MediaQuery.of(context).size.width,
                                height: MediaQuery.of(context).size.height,
                              ),
                            );
                          }));
                        },
                      );
                    },
                    childCount: _imageUrls.length,
                    addRepaintBoundaries: true,
                    addAutomaticKeepAlives: true,
                  ),

                  // cacheExtent: MediaQuery.of(context).size.width * 3,
                  // Cache more items
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8.0,
                    crossAxisSpacing: 8.0,
                    childAspectRatio: 1.0,
                  ),
                ),
                // Bottom Swiper
                SliverToBoxAdapter(
                  child: buildSwiper(List.generate(7, getRandomImg)),
                ),
              ],
            ),
          ),

          // Multiple VAP players
          // 多个 VAP 播放器
          if (_activePlayers.isNotEmpty) ...[
            for (final tag in _activePlayers)
              Positioned.fill(
                child: PlayerView(
                  key: ValueKey(tag), // Add key for better widget management
                  tag: tag,
                  ignoring: true,
                  autoRemove: true,
                ),
              ),
          ],
          // Animated images
          // 动画图片
          ..._animationGroups.map(
            (group) => Positioned.fill(
              child: IgnorePointer(
                child: Stack(
                  children: List.generate(30, (index) {
                    return AnimatedBuilder(
                      animation: group.controllers[index],
                      builder: (context, child) {
                        return Positioned(
                          left: MediaQuery.of(context).size.width / 2 +
                              group.positionAnimations[index].value.dx,
                          top: MediaQuery.of(context).size.height / 2 +
                              group.positionAnimations[index].value.dy,
                          child: Transform.scale(
                            scale: group.scaleAnimations[index].value,
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 5,
                                    spreadRadius: 2,
                                  ),
                                ],
                                image: DecorationImage(
                                  image: CachedNetworkImageProvider(
                                    flyImage,
                                    cacheManager: CustomCacheManager.instance,
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Explosion animation button
          // 爆炸动画按钮
          FloatingActionButton(
            onPressed: _createExplosionAnimation,
            heroTag: 'explode',
            child: const Icon(Icons.auto_awesome),
          ),
          const SizedBox(width: 16),
          // VAP player button
          // VAP 播放器按钮
          FloatingActionButton(
            onPressed: () {
              showDialog(
                context: context,
                barrierColor: Colors.black.withOpacity(0.5),
                builder: (context) {
                  final selectedImages = List.generate(5, getRandomImg);

                  return BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: AlertDialog(
                      backgroundColor: Colors.black.withOpacity(0.8),
                      contentPadding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Stack of circular images
                          SizedBox(
                            height: 120,
                            width: 200,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                for (var i = 0; i < selectedImages.length; i++)
                                  Positioned(
                                    left: 40.0 * i,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 2),
                                      ),
                                      child: ClipOval(
                                        child: CachedNetworkImage(
                                          imageUrl: selectedImages[i],
                                          width: 20,
                                          height: 20,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              const Center(
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Video buttons - now each button starts a new VAP instance
                          // 视频按钮 - 现在每个按钮启动一个新的 VAP 实例
                          for (int i = 0; i < videoUrls.length; i++)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Colors.white.withOpacity(0.2),
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () {
                                  _playVideo(videoUrls[i]);
                                  Navigator.pop(context);
                                },
                                child: Text('Play Video ${i + 1}'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            heroTag: 'vap',
            child: const Icon(Icons.play_circle),
          ),
        ],
      ),
    );
  }
}

class NetworkImageWidget extends StatefulWidget {
  final String url;
  final double? width;
  final double? height;
  final Color? color;
  final BoxFit fit;
  final String? placeHolder;
  final Widget? placeHolderWidget;
  final Widget? errorWidget;
  final int fadeInDuration;
  final bool repain;
  final bool home;
  final int? index;

  const NetworkImageWidget({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.color,
    this.fit = BoxFit.cover,
    this.placeHolder,
    this.placeHolderWidget,
    this.errorWidget,
    this.fadeInDuration = 0,
    this.repain = false,
    this.home = false,
    this.index,
  });

  @override
  State<NetworkImageWidget> createState() => _NetworkImageWidgetState();
}

class _NetworkImageWidgetState extends State<NetworkImageWidget>
    with AutomaticKeepAliveClientMixin {
  static final Map<String, CachedNetworkImageProvider> _imageProviderCache = {};
  ImageProvider? _cachedProvider;
  bool _isLoaded = false;
  bool _didInitialize = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInitialize) {
      _cachedProvider = _getImageProvider(widget.url);
      _precacheImage();
      _didInitialize = true;
    }
  }

  void _precacheImage() {
    if (_cachedProvider != null) {
      precacheImage(_cachedProvider!, context).then((_) {
        if (mounted) {
          setState(() {
            _isLoaded = true;
          });
        }
      });
    }
  }

  CachedNetworkImageProvider _getImageProvider(String url) {
    // Add size parameters to the URL if they're not already present
    final Uri uri = Uri.parse(url);
    final Map<String, String> queryParams =
        Map<String, String>.from(uri.queryParameters);

    if (!queryParams.containsKey('w')) {
      queryParams['w'] = '600';
    }
    if (!queryParams.containsKey('h')) {
      queryParams['h'] = '600';
    }

    final String modifiedUrl =
        uri.replace(queryParameters: queryParams).toString();

    return _imageProviderCache.putIfAbsent(
      modifiedUrl,
      () => CachedNetworkImageProvider(
        modifiedUrl,
        cacheManager: CustomCacheManager.instance,
      ),
    );
  }

  @override
  void dispose() {
    if (widget.index != null) {
      print('Disposing NetworkImageWidget at index: ${widget.index}');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (!widget.url.startsWith("http")) {
      return const SizedBox();
    }

    if (_isLoaded && _cachedProvider != null) {
      Widget imageWidget = Image(
        image: _cachedProvider!,
        width: widget.width ?? 600,
        height: widget.height ?? 600,
        fit: widget.fit,
        gaplessPlayback: true,
        isAntiAlias: true,
      );
      return widget.repain ? RepaintBoundary(child: imageWidget) : imageWidget;
    }

    // Show placeholder while loading
    return widget.placeHolderWidget ??
        (widget.placeHolder != null
            ? Image.asset(
                widget.placeHolder!,
                width: widget.width,
                height: widget.height,
              )
            : const SizedBox(
                width: 200,
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ));
  }
}

const imagesList = [
  'https://dynamic-media-cdn.tripadvisor.com/media/photo-o/15/61/8a/53/my-pup.jpg?w=1400&h=800&s=1',
  'https://dynamic-media-cdn.tripadvisor.com/media/photo-o/2e/95/59/ab/edit.jpg?w=1100&h=600&s=1',
  'https://dynamic-media-cdn.tripadvisor.com/media/photo-o/1b/01/bd/a3/see-two-for-the-price.jpg?w=1400&h=800&s=1',
  'https://dynamic-media-cdn.tripadvisor.com/media/photo-o/13/f8/5c/05/picture-lake.jpg?w=900&h=500&s=1',
  'https://dynamic-media-cdn.tripadvisor.com/media/photo-o/19/c2/d2/63/photo0jpg.jpg?w=1400&h=800&s=1',
  'https://dynamic-media-cdn.tripadvisor.com/media/photo-o/18/d7/88/98/picture-lake-5.jpg?w=1100&h=600&s=1',
  'https://dynamic-media-cdn.tripadvisor.com/media/photo-o/18/d7/88/62/picture-lake-4.jpg?w=1400&h=800&s=1',
  'https://media-cdn.tripadvisor.com/media/attractions-splice-spp-674x446/07/3b/f6/fc.jpg',
  'https://media-cdn.tripadvisor.com/media/attractions-splice-spp-674x446/07/3b/f6/f3.jpg',
  'https://media-cdn.tripadvisor.com/media/attractions-splice-spp-674x446/07/3b/f6/e5.jpg',
  'https://media-cdn.tripadvisor.com/media/attractions-splice-spp-674x446/0f/f6/d6/c2.jpg',
  'https://media-cdn.tripadvisor.com/media/attractions-splice-spp-674x446/0f/f6/d7/6e.jpg',
  'https://media-cdn.tripadvisor.com/media/attractions-splice-spp-674x446/0f/f6/d5/bf.jpg',
  'https://dynamic-media-cdn.tripadvisor.com/media/photo-o/2e/36/8a/5c/caption.jpg?w=600&h=600&s=1',
  'https://dynamic-media-cdn.tripadvisor.com/media/photo-o/2e/36/86/73/caption.jpg?w=600&h=600&s=1',
  'https://dynamic-media-cdn.tripadvisor.com/media/photo-o/2a/f5/23/1f/caption.jpg?w=600&h=600&s=1',
  'https://dynamic-media-cdn.tripadvisor.com/media/photo-o/2a/c1/50/41/caption.jpg?w=600&h=600&s=1',
  'https://dynamic-media-cdn.tripadvisor.com/media/photo-o/27/19/3e/94/caption.jpg?w=600&h=600&s=1',
  'https://dynamic-media-cdn.tripadvisor.com/media/photo-o/2a/f7/f3/38/caption.jpg?w=600&h=600&s=1',
  'https://dynamic-media-cdn.tripadvisor.com/media/photo-o/24/74/91/94/caption.jpg?w=600&h=600&s=1',
  'https://dynamic-media-cdn.tripadvisor.com/media/photo-o/2c/c1/03/41/caption.jpg?w=600&h=600&s=1',
  'https://dynamic-media-cdn.tripadvisor.com/media/photo-o/29/86/68/ef/caption.jpg?w=600&h=600&s=1',
  'https://dynamic-media-cdn.tripadvisor.com/media/photo-o/1c/57/fd/38/caption.jpg?w=600&h=600&s=1',
  'https://dynamic-media-cdn.tripadvisor.com/media/photo-o/2a/17/55/4d/caption.jpg?w=600&h=600&s=1',
];

class GameWebViewPage extends StatefulWidget {
  @override
  _GameWebViewPageState createState() => _GameWebViewPageState();
}

class _GameWebViewPageState extends State<GameWebViewPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('https://www.4399.com/'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('4399 WebView'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(CupertinoPageRoute(builder: (context) {
                return VapDemoPage(playTag: "demo_player${DateTime.now()}");
              }));
            },
            icon: const Icon(Icons.play_circle),
          ),
        ],
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}

// Animation group class to manage a set of related animations
// 动画组类，用于管理一组相关的动画
class AnimationGroup {
  final List<AnimationController> controllers = [];
  final List<Animation<double>> scaleAnimations = [];
  final List<Animation<Offset>> positionAnimations = [];
  final TickerProvider vsync;
  final VoidCallback onComplete;
  int _completedAnimations = 0;

  AnimationGroup({
    required this.vsync,
    required this.onComplete,
  }) {
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Create 30 animations
    // 创建30个动画
    for (var i = 0; i < 30; i++) {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 1500),
        vsync: vsync,
      );

      // Random angle for each image
      // 每个图片的随机角度
      final angle = (i * 12.0) * (3.14159 / 180.0);
      final radius = 300.0; // Maximum distance from center

      // Create position animation
      // 创建位置动画
      final positionAnimation = Tween<Offset>(
        begin: Offset.zero,
        end: Offset(
          radius * cos(angle),
          radius * sin(angle),
        ),
      ).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeOut,
        ),
      );

      // Create scale animation
      // 创建缩放动画
      final scaleAnimation = Tween<double>(
        begin: 1.0,
        end: 0.0,
      ).animate(
        CurvedAnimation(
          parent: controller,
          curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
        ),
      );

      controllers.add(controller);
      positionAnimations.add(positionAnimation);
      scaleAnimations.add(scaleAnimation);

      // Start animation with delay
      // 延迟开始动画
      Future.delayed(Duration(milliseconds: (i * 50)), () {
        controller.forward().then((_) {
          _completedAnimations++;
          if (_completedAnimations == 30) {
            onComplete();
          }
        });
      });
    }
  }

  void dispose() {
    for (var controller in controllers) {
      controller.dispose();
    }
  }
}
