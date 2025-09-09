import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:korset_app/services/favorites_service.dart';

class FavoriteButton extends StatefulWidget {
  final int productId;
  final double? size;
  final Color? activeColor;
  final Color? inactiveColor;

  const FavoriteButton({
    super.key,
    required this.productId,
    this.size = 20,
    this.activeColor = Colors.red,
    this.inactiveColor = Colors.white,
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton>
    with SingleTickerProviderStateMixin {
  bool _isFavorite = false;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    _checkFavoriteStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkFavoriteStatus() async {
    try {
      final isFavorite = await FavoritesService.isFavorite(widget.productId);
      if (mounted) {
        setState(() {
          _isFavorite = isFavorite;
        });
      }
    } catch (e) {
      // Error checking favorite status: $e
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newFavoriteStatus = await FavoritesService.toggleFavorite(
        widget.productId, 
        _isFavorite
      );
      
      if (mounted) {
        setState(() {
          _isFavorite = newFavoriteStatus;
        });
        
        if (newFavoriteStatus) {
          _animationController.forward().then((_) {
            _animationController.reverse();
          });
          _showSnackBar('Добавлено в избранное');
        } else {
          _showSnackBar('Удалено из избранного');
        }
      }
    } catch (e) {
      _showSnackBar('Произошла ошибка: ${e.toString()}');
      // Error toggling favorite: $e
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xff183B4E),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleFavorite,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _isLoading
                  ? SizedBox(
                      width: widget.size,
                      height: widget.size,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          widget.activeColor!,
                        ),
                      ),
                    )
                  : Icon(
                      _isFavorite ? IconlyBold.heart : IconlyBroken.heart,
                      size: widget.size,
                      color: _isFavorite ? widget.activeColor : Colors.grey[600],
                    ),
            ),
          );
        },
      ),
    );
  }
}
