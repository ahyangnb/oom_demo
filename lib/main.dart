import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui';
import 'dart:math';
// The pure flutter official widget.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  PaintingBinding.instance.imageCache.maximumSizeBytes = 300 << 20;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Gallery Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const GalleryPage(),
    );
  }
}

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage>
    with TickerProviderStateMixin {
  final List<String> _imageUrls = List.generate(50, getRandomImg);
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreImages();
    }
  }

  Future<void> _loadMoreImages() async {
    if (!_isLoading) {
      setState(() {
        _isLoading = true;
      });

      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _imageUrls.addAll(List.generate(10, getRandomImg));
        _isLoading = false;
      });
    }
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _imageUrls.shuffle();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Gallery'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Top Image Carousel
            SliverToBoxAdapter(
              child: ImageCarousel(imageUrls: _imageUrls.take(7).toList()),
            ),
            // Grid of Images
            SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  final imgUrl = _imageUrls[index];
                  return InkWell(
                    child: Stack(
                      children: [
                        Image.network(imgUrl, width: 200, height: 200),
                        Positioned(
                          bottom: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Image $index',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (context) => ImageViewPage(imageUrl: imgUrl),
                        ),
                      );
                    },
                  );
                },
                childCount: _imageUrls.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8.0,
                crossAxisSpacing: 8.0,
                childAspectRatio: 1.0,
              ),
            ),
            if (_isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ImageCarousel extends StatefulWidget {
  final List<String> imageUrls;

  const ImageCarousel({super.key, required this.imageUrls});

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  void _startAutoPlay() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        final nextPage = (_currentPage + 1) % widget.imageUrls.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        _startAutoPlay();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: widget.imageUrls.length,
            itemBuilder: (context, index) {
              return Image.network(
                widget.imageUrls[index],
                fit: BoxFit.cover,
              );
            },
          ),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.imageUrls.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        _currentPage == index ? Colors.white : Colors.white54,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ImageViewPage extends StatelessWidget {
  final String imageUrl;

  const ImageViewPage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Image.network(
          imageUrl,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

// Image list for demo
const imagesList = [
  'https://dynamic-media-cdn.tripadvisor.com/media/photo-o/15/61/8a/53/my-pup.jpg?w=1400&h=800&s=1',
  'https://dynamic-media-cdn.tripadvisor.com/media/photo-o/2e/95/59/ab/edit.jpg?w=1100&h=600&s=1',
  'https://dynamic-media-cdn.tripadvisor.com/media/photo-o/1b/01/bd/a3/see-two-for-the-price.jpg?w=1400&h=800&s=1',
  'https://dynamic-media-cdn.tripadvisor.com/media/photo-o/13/f8/5c/05/picture-lake.jpg?w=900&h=500&s=1',
  'https://dynamic-media-cdn.tripadvisor.com/media/photo-o/19/c2/d2/63/photo0jpg.jpg?w=1400&h=800&s=1',
  'https://dynamic-media-cdn.tripadvisor.com/media/photo-o/18/d7/88/98/picture-lake-5.jpg?w=1100&h=600&s=1',
  'https://dynamic-media-cdn.tripadvisor.com/media/photo-o/18/d7/88/62/picture-lake-4.jpg?w=1400&h=800&s=1',
];

String getRandomImg(int index) {
  final img = imagesList[index % imagesList.length];
  if (img.endsWith('.jpg')) {
    return '$img?hahahahah=${DateTime.now()}';
  } else {
    return '$img&hahahahah=${DateTime.now()}';
  }
}
