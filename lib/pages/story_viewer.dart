import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';

class StoryViewerPage extends StatefulWidget {
  final List<Map<String, dynamic>> stories;
  final int initialIndex;

  const StoryViewerPage({
    super.key,
    required this.stories,
    this.initialIndex = 0,
  });

  @override
  State<StoryViewerPage> createState() => _StoryViewerPageState();
}

class _StoryViewerPageState extends State<StoryViewerPage>
    with TickerProviderStateMixin {
  VideoPlayerController? _videoController;
  String? _lastVideoUrl;
  late PageController _pageController;
  late AnimationController _progressController;
  int _currentStoryIndex = 0;
  int _currentUserIndex = 0;
  bool _isPaused = false;
  bool _isVideoLoading = false;
  bool _isCurrentStoryVideo = false;

  @override
  void initState() {
    super.initState();
    _currentUserIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _progressController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    _startStoryTimer();

    // Hide status bar for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();

    // Restore status bar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _startStoryTimer() {
    _progressController.reset();

    // Проверяем, является ли текущая история видео
    final currentUser = widget.stories[_currentUserIndex];
    final userStories = currentUser['stories'] as List;
    final currentStory = userStories[_currentStoryIndex];
    final imageUrl = currentStory['image'] as String;

    _isCurrentStoryVideo = imageUrl.toLowerCase().endsWith('.mp4') ||
        imageUrl.toLowerCase().endsWith('.mov');

    if (_isCurrentStoryVideo) {
      // Для видео не запускаем таймер пока не загрузится
      _isVideoLoading = true;
    } else {
      // Для изображений запускаем обычный таймер
      _isVideoLoading = false;
      _progressController.forward().then((_) {
        if (!_isPaused && mounted) {
          _nextStory();
        }
      });
    }
  }

  void _startVideoProgressTimer(Duration videoDuration) {
    // Проверяем что длительность валидна
    if (videoDuration.inMilliseconds <= 0) {
      videoDuration = const Duration(seconds: 8); // fallback
    }

    // Устанавливаем длительность анимации равной длительности видео
    _progressController.duration = videoDuration;
    _progressController.reset();
    _isVideoLoading = false;

    if (!_isPaused) {
      _progressController.forward().then((_) {
        if (!_isPaused && mounted) {
          _nextStory();
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant StoryViewerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _disposeVideoController();
  }

  @override
  void deactivate() {
    _disposeVideoController();
    super.deactivate();
  }

  void _disposeVideoController() {
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    _videoController = null;
    _lastVideoUrl = null;
  }

  void _videoListener() {
    if (_videoController != null &&
        _videoController!.value.isInitialized &&
        _videoController!.value.position >= _videoController!.value.duration &&
        _videoController!.value.duration.inMilliseconds > 0) {
      if (mounted && !_isPaused) {
        _nextStory();
      }
    }
  }

  void _nextStory() {
    // Останавливаем видео если оно играет
    if (_videoController != null && _videoController!.value.isPlaying) {
      _videoController!.pause();
    }

    final currentUser = widget.stories[_currentUserIndex];
    final userStories = currentUser['stories'] as List;

    if (_currentStoryIndex < userStories.length - 1) {
      // Next story for same user
      setState(() {
        _currentStoryIndex++;
      });
      _startStoryTimer();
    } else {
      // Next user
      if (_currentUserIndex < widget.stories.length - 1) {
        setState(() {
          _currentUserIndex++;
          _currentStoryIndex = 0;
        });
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        _startStoryTimer();
      } else {
        // End of all stories
        Navigator.of(context).pop();
      }
    }
  }

  void _previousStory() {
    // Останавливаем видео если оно играет
    if (_videoController != null && _videoController!.value.isPlaying) {
      _videoController!.pause();
    }

    if (_currentStoryIndex > 0) {
      // Previous story for same user
      setState(() {
        _currentStoryIndex--;
      });
      _startStoryTimer();
    } else {
      // Previous user
      if (_currentUserIndex > 0) {
        setState(() {
          _currentUserIndex--;
          final prevUser = widget.stories[_currentUserIndex];
          final prevUserStories = prevUser['stories'] as List;
          _currentStoryIndex = prevUserStories.length - 1;
        });
        _pageController.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        _startStoryTimer();
      }
    }
  }

  void _pauseStory() {
    setState(() {
      _isPaused = true;
    });
    _progressController.stop();

    // Паузим видео если оно играет
    if (_videoController != null && _videoController!.value.isPlaying) {
      _videoController!.pause();
    }
  }

  void _resumeStory() {
    setState(() {
      _isPaused = false;
    });

    if (!_isVideoLoading) {
      _progressController.forward();
    }

    // Возобновляем видео если оно на паузе
    if (_videoController != null &&
        !_videoController!.value.isPlaying &&
        _videoController!.value.isInitialized) {
      _videoController!.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.stories.length,
        onPageChanged: (index) {
          // Останавливаем предыдущее видео
          if (_videoController != null && _videoController!.value.isPlaying) {
            _videoController!.pause();
          }

          setState(() {
            _currentUserIndex = index;
            _currentStoryIndex = 0;
            _isVideoLoading = false;
          });
          _startStoryTimer();
        },
        itemBuilder: (context, userIndex) {
          final user = widget.stories[userIndex];
          final userStories = user['stories'] as List;
          final currentStory = userStories[_currentStoryIndex];

          return GestureDetector(
            onTapDown: (details) => _pauseStory(),
            onTapUp: (details) {
              _resumeStory();
              final screenWidth = MediaQuery.of(context).size.width;
              if (details.localPosition.dx < screenWidth / 2) {
                _previousStory();
              } else {
                _nextStory();
              }
            },
            onTapCancel: () => _resumeStory(),
            child: Stack(
              children: [
                // Story Content
                Positioned.fill(
                  child: _buildStoryImage(currentStory['image']),
                ),

                // Gradient overlay at top
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 120,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.6),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Progress indicators
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 16,
                  right: 16,
                  child: Row(
                    children: userStories.asMap().entries.map((entry) {
                      int index = entry.key;
                      return Expanded(
                        child: Container(
                          height: 3,
                          margin: EdgeInsets.only(
                            right: index < userStories.length - 1 ? 4 : 0,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(1.5),
                          ),
                          child: AnimatedBuilder(
                            animation: _progressController,
                            builder: (context, child) {
                              double progress = 0.0;
                              if (index < _currentStoryIndex) {
                                progress = 1.0;
                              } else if (index == _currentStoryIndex) {
                                if (_isVideoLoading) {
                                  // Показываем пульсирующую анимацию пока видео загружается
                                  progress = 0.0;
                                } else {
                                  progress = _progressController.value;
                                }
                              }

                              return FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: progress,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _isVideoLoading &&
                                            index == _currentStoryIndex
                                        ? Colors.white.withOpacity(0.5)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(1.5),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // User info and close button
                Positioned(
                  top: MediaQuery.of(context).padding.top + 32,
                  left: 16,
                  right: 16,
                  child: Row(
                    children: [
                      // User avatar
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: _buildAvatarImage(user['avatar']),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // User name and time
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user['name'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              currentStory['time'] ?? '1ч',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Close button
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Story text (if any)
                if (currentStory['text'] != null)
                  Positioned(
                    bottom: 100,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        currentStory['text'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                // Pause indicator
                if (_isPaused)
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Center(
                      child: Icon(
                        Icons.pause_circle_filled,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                  ),

                // Video loading indicator
                if (_isVideoLoading && _isCurrentStoryVideo)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 60,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Загрузка видео...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStoryImage(String imageUrl) {
    // Автоматически меняем старый домен на новый
    if (imageUrl.contains('korset.dnmc.kz')) {
      imageUrl = imageUrl.replaceAll('korset.dnmc.kz', 'videopokaz.kz');
    }

    // Исправляем двойные слеши в URL
    imageUrl = imageUrl.replaceAll(RegExp(r'(?<!:)//+'), '/');

    // Исправляем двойной storage в URL
    final originalUrl = imageUrl;
    imageUrl = imageUrl.replaceAll('/storage/storage/', '/storage/');

    if (originalUrl != imageUrl) {
      print('🔧 Fixed URL: $originalUrl -> $imageUrl');
    } else {
      print('📱 Loading story image: $imageUrl');
    }

    // Проверяем, является ли это видео
    final isVideo = imageUrl.toLowerCase().endsWith('.mp4') ||
        imageUrl.toLowerCase().endsWith('.mov');
    if (isVideo) {
      // Если контроллер уже создан для этого видео, не пересоздаём
      if (_videoController == null || _lastVideoUrl != imageUrl) {
        _disposeVideoController();

        // Устанавливаем состояние загрузки без setState во время build
        if (!_isVideoLoading) {
          _isVideoLoading = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {});
            }
          });
        }

        _videoController = VideoPlayerController.networkUrl(Uri.parse(imageUrl))
          ..initialize().then((_) {
            if (mounted) {
              setState(() {
                _isVideoLoading = false;
              });

              // Запускаем прогресс-бар с длительностью видео
              final videoDuration = _videoController!.value.duration;
              if (videoDuration.inMilliseconds > 0) {
                _startVideoProgressTimer(videoDuration);
              } else {
                // Fallback к стандартному времени если длительность неизвестна
                _startVideoProgressTimer(const Duration(seconds: 8));
              }

              // Запускаем видео
              _videoController?.play();

              // Слушаем окончание видео
              _videoController?.addListener(_videoListener);
            }
          }).catchError((error) {
            if (mounted) {
              setState(() {
                _isVideoLoading = false;
              });
              print('Error initializing video: $error');
            }
          });
        _lastVideoUrl = imageUrl;
      }

      if (_videoController != null && _videoController!.value.isInitialized) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black,
          child: Center(
            child: AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
          ),
        );
      } else {
        return Container(
          color: Colors.black,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 16),
                Text(
                  'Загрузка видео...',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        );
      }
    }

    // Проверяем, является ли это URL или asset (фото)
    if (imageUrl.startsWith('http')) {
      // Это сетевое изображение
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }
            return Container(
              color: Colors.black,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Загрузка... ${((loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)) * 100).toInt()}%',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            print('Error loading story image: $imageUrl');
            print('Error details: $error');
            print('Stack trace: $stackTrace');

            return Container(
              color: Colors.black,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.image_not_supported,
                      color: Colors.white,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Не удалось загрузить изображение',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'URL:',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            imageUrl,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        // Попытка перезагрузки (пока просто показываем сообщение)
                        print('Attempting to reload image: $imageUrl');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Попробовать снова'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    } else {
      // Это asset изображение
      return Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(imageUrl),
            fit: BoxFit.cover,
            onError: (error, stackTrace) {
              print('Error loading asset image: $imageUrl - $error');
            },
          ),
        ),
      );
    }
  }

  Widget _buildAvatarImage(String imageUrl) {
    if (imageUrl.startsWith('http')) {
      // Исправляем URL аватара
      if (imageUrl.contains('korset.dnmc.kz')) {
        imageUrl = imageUrl.replaceAll('korset.dnmc.kz', 'videopokaz.kz');
      }
      imageUrl = imageUrl.replaceAll(RegExp(r'(?<!:)//+'), '/');
      imageUrl = imageUrl.replaceAll('/storage/storage/', '/storage/');

      // Сетевое изображение
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        width: 32,
        height: 32,
        placeholder: (context, url) => Container(
          color: Colors.grey[400],
          child: const Icon(
            Icons.person,
            color: Colors.white,
            size: 20,
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[400],
          child: const Icon(
            Icons.person,
            color: Colors.white,
            size: 20,
          ),
        ),
      );
    } else {
      // Asset изображение
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        width: 32,
        height: 32,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[400],
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 20,
            ),
          );
        },
      );
    }
  }
}
