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

class _VapDemoPageState extends State<VapDemoPage> {
  String get playerTag => widget.playTag;

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
    // Initialize the queue utility for this player instance
    QueueUtil.init(playerTag);
  }

  @override
  void dispose() {
    // Clean up resources when disposing
    QueueUtil.get(playerTag)?.clear();
    QueueUtil.remove(playerTag);
    _refreshController.dispose();

    super.dispose();
  }

  // Play a VAP video
  void _playVideo(String url) {
    QueueUtil.get(playerTag)?.addTask(
      url,
      fill: "1", // 1 for cover mode
      callBack: (data, data1) {
        // Callback when video playback completes
        print('Video playback completed');
      },
    );
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
      floatingActionButton: FloatingActionButton(
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
                      // Video buttons
                      for (int i = 0; i < videoUrls.length; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.2),
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
        child: const Icon(Icons.play_circle),
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

          // Player view takes full screen
          Positioned.fill(
            child: PlayerView(
              tag: playerTag,
              ignoring: true, // Ignore touch events
              autoRemove: true, // Auto remove when done
            ),
          ),
          // Control buttons
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
      appBar: AppBar(title: Text('4399 WebView')),
      body: WebViewWidget(controller: _controller),
    );
  }
}
