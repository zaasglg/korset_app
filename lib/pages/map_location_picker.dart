import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import '../models/city.dart';

class MapLocationPicker extends StatefulWidget {
  final City? selectedCity;
  final String? selectedAddress;

  const MapLocationPicker({
    super.key,
    this.selectedCity,
    this.selectedAddress,
  });

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  late YandexMapController _controller;
  final TextEditingController _searchController = TextEditingController();
  
  Point? _selectedPoint;
  String? _selectedAddress;
  bool _isLoading = false;
  
  // Default location (Almaty center)
  static const Point _defaultLocation = Point(latitude: 43.2220, longitude: 76.8512);

  @override
  void initState() {
    super.initState();
    _selectedAddress = widget.selectedAddress;
    
    // Set initial location based on selected city or default
    if (widget.selectedCity != null) {
      // You can set coordinates based on city here
      // For now using default location
      _selectedPoint = _defaultLocation;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(IconlyBroken.arrowLeft, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Выберите местоположение',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_selectedPoint != null)
            TextButton(
              onPressed: _confirmLocation,
              child: const Text(
                'Готово',
                style: TextStyle(
                  color: Color(0xFF3366FF),
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          YandexMap(
            onMapCreated: (YandexMapController controller) {
              _controller = controller;
              _moveToInitialLocation();
            },
            onMapTap: _onMapTap,
            mapObjects: _buildMapObjects(),
            onCameraPositionChanged: _onCameraPositionChanged,
          ),
          
          // Search bar
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Поиск адреса...',
                  hintStyle: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 15,
                  ),
                  prefixIcon: const Icon(
                    IconlyBroken.search,
                    color: Color(0xff183B4E),
                    size: 20,
                  ),
                  suffixIcon: _isLoading
                    ? Container(
                        width: 20,
                        height: 20,
                        padding: const EdgeInsets.all(12),
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xff183B4E),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(IconlyBroken.location),
                        color: const Color(0xff183B4E),
                        onPressed: _searchAddress,
                      ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                onSubmitted: (_) => _searchAddress(),
              ),
            ),
          ),
          
          // Selected location info
          if (_selectedPoint != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          IconlyBroken.location,
                          color: const Color(0xFF3366FF),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Выбранное местоположение',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedAddress ?? 'Координаты: ${_selectedPoint!.latitude.toStringAsFixed(6)}, ${_selectedPoint!.longitude.toStringAsFixed(6)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _confirmLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3366FF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Подтвердить местоположение',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<MapObject> _buildMapObjects() {
    if (_selectedPoint == null) return [];
    
    return [
      PlacemarkMapObject(
        mapId: const MapObjectId('selected_location'),
        point: _selectedPoint!,
        icon: PlacemarkIcon.single(
          PlacemarkIconStyle(
            image: BitmapDescriptor.fromAssetImage('assets/icons/map.png'),
            scale: 0.5,
          ),
        ),
        onTap: (PlacemarkMapObject placemark, Point point) {
          _showLocationDetails();
        },
      ),
    ];
  }

  void _moveToInitialLocation() {
    final targetPoint = _selectedPoint ?? _defaultLocation;
    _controller.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: targetPoint,
          zoom: 15.0,
        ),
      ),
      animation: const MapAnimation(type: MapAnimationType.smooth, duration: 1.0),
    );
  }

  void _onMapTap(Point point) {
    setState(() {
      _selectedPoint = point;
      _selectedAddress = null; // Clear address, will be fetched
    });
    
    // Get address from coordinates (reverse geocoding)
    _getAddressFromCoordinates(point);
  }

  void _onCameraPositionChanged(CameraPosition position, CameraUpdateReason updateReason, bool finished) {
    // You can add logic here if needed
  }

  Future<void> _searchAddress() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // In a real app, you would use Yandex Geocoder or another geocoding service
      // For now, we'll simulate the search
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock search result - in reality you'd parse the geocoding response
      const searchResult = Point(latitude: 43.2380, longitude: 76.9452);
      
      setState(() {
        _selectedPoint = searchResult;
        _selectedAddress = query;
      });
      
      _controller.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: searchResult,
            zoom: 16.0,
          ),
        ),
        animation: const MapAnimation(type: MapAnimationType.smooth, duration: 1.0),
      );
      
    } catch (e) {
      _showErrorSnackBar('Ошибка поиска адреса');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getAddressFromCoordinates(Point point) async {
    try {
      // In a real app, you would use reverse geocoding here
      // For now, we'll just show coordinates
      setState(() {
        _selectedAddress = 'Координаты: ${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}';
      });
    } catch (e) {
      print('Error getting address: $e');
    }
  }

  void _showLocationDetails() {
    if (_selectedPoint == null) return;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Информация о местоположении',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoRow('Широта', _selectedPoint!.latitude.toStringAsFixed(6)),
              _buildInfoRow('Долгота', _selectedPoint!.longitude.toStringAsFixed(6)),
              if (_selectedAddress != null)
                _buildInfoRow('Адрес', _selectedAddress!),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1A1A1A),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLocation() {
    if (_selectedPoint == null) return;
    
    Navigator.of(context).pop({
      'point': _selectedPoint,
      'address': _selectedAddress,
      'coordinates': {
        'latitude': _selectedPoint!.latitude,
        'longitude': _selectedPoint!.longitude,
      },
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
