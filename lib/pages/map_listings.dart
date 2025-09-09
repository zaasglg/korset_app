import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
// import 'package:korset_app/models/listing.dart';
// import 'package:korset_app/widgets/listing_card.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

class MapListingsPage extends StatefulWidget {
  const MapListingsPage({super.key});

  @override
  State<MapListingsPage> createState() => _MapListingsPageState();
}

class _MapListingsPageState extends State<MapListingsPage> {
  String selectedFilter = 'Все';
  final List<String> filters = ['Все', 'Недвижимость', 'Авто', 'Электроника', 'Мода'];
  
  // Контроллер для карты
  late YandexMapController _mapController;
  
  // Контроллер для DraggableScrollableSheet
  final DraggableScrollableController _scrollController = DraggableScrollableController();
  
  // Начальная позиция камеры (Алматы)
  static const Point _defaultLocation = Point(latitude: 43.2220, longitude: 76.8512);
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(IconlyBroken.arrowLeft, color: Color(0xff183B4E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Объявления на карте',
          style: TextStyle(
            color: Color(0xff183B4E),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(IconlyBroken.filter, color: Color(0xff183B4E)),
            onPressed: () => _showFilterModal(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Карта на весь экран
          YandexMap(
            onMapCreated: (YandexMapController controller) {
              _mapController = controller;
              _moveToInitialLocation();
            },
            mapObjects: _buildMapObjects(),
          ),
          
          // Фильтры вверху
          // Positioned(
          //   top: 16,
          //   left: 0,
          //   right: 0,
          //   child: Container(
          //     height: 50,
          //     padding: const EdgeInsets.symmetric(vertical: 8),
          //     child: ListView.builder(
          //       scrollDirection: Axis.horizontal,
          //       padding: const EdgeInsets.symmetric(horizontal: 16),
          //       itemCount: filters.length,
          //       itemBuilder: (context, index) {
          //         final filter = filters[index];
          //         final isSelected = filter == selectedFilter;
          //         return GestureDetector(
          //           onTap: () {
          //             setState(() {
          //               selectedFilter = filter;
          //             });
          //           },
          //           child: Container(
          //             margin: const EdgeInsets.only(right: 12),
          //             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          //             decoration: BoxDecoration(
          //               color: isSelected ? const Color(0xFFF7B84B) : Colors.white,
          //               borderRadius: BorderRadius.circular(20),
          //               boxShadow: [
          //                 BoxShadow(
          //                   color: Colors.black.withValues(alpha: 0.05),
          //                   blurRadius: 5,
          //                   offset: const Offset(0, 2),
          //                 ),
          //               ],
          //             ),
          //             child: Text(
          //               filter,
          //               style: TextStyle(
          //                 color: isSelected ? Colors.white : const Color(0xff183B4E),
          //                 fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          //                 fontSize: 14,
          //               ),
          //             ),
          //           ),
          //         );
          //       },
          //     ),
          //   ),
          // ),
          
          // DraggableScrollableSheet с объявлениями
          // DraggableScrollableSheet(
          //   controller: _scrollController,
          //   initialChildSize: 0.3,
          //   minChildSize: 0.15,
          //   maxChildSize: 0.8,
          //   builder: (context, scrollController) {
          //     return Container(
          //       decoration: const BoxDecoration(
          //         color: Colors.white,
          //         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          //         boxShadow: [
          //           BoxShadow(
          //             color: Colors.black12,
          //             blurRadius: 10,
          //             spreadRadius: 2,
          //           ),
          //         ],
          //       ),
          //       child: Column(
          //         children: [
          //           // Индикатор перетаскивания
          //           Container(
          //             margin: const EdgeInsets.only(top: 10, bottom: 10),
          //             width: 40,
          //             height: 4,
          //             decoration: BoxDecoration(
          //               color: Colors.grey[300],
          //               borderRadius: BorderRadius.circular(10),
          //             ),
          //           ),
                    
          //           // Заголовок и количество объявлений
          //           Padding(
          //             padding: const EdgeInsets.symmetric(horizontal: 16),
          //             child: Row(
          //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //               children: [
          //                 const Text(
          //                   'Найденные объявления',
          //                   style: TextStyle(
          //                     fontSize: 18,
          //                     fontWeight: FontWeight.w700,
          //                     color: Color(0xff183B4E),
          //                   ),
          //                 ),
          //                 Container(
          //                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          //                   decoration: BoxDecoration(
          //                     color: const Color(0xFFF7B84B).withValues(alpha: 0.1),
          //                     borderRadius: BorderRadius.circular(12),
          //                   ),
          //                   child: const Text(
          //                     '24 объявления',
          //                     style: TextStyle(
          //                       fontSize: 12,
          //                       fontWeight: FontWeight.w600,
          //                       color: Color(0xFFF7B84B),
          //                     ),
          //                   ),
          //                 ),
          //           ],
          //         ),
          //         const SizedBox(height: 16),
          //         Expanded(
          //           child: ListView.builder(
          //             controller: scrollController,
          //             padding: const EdgeInsets.all(16),
          //             itemCount: 3,
          //             itemBuilder: (context, index) {
          //               return _buildListingCard(index);
          //             },
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
        ],
      ),
      
      // Кнопка поиска в текущей области
      // floatingActionButton: Padding(
      //   padding: const EdgeInsets.only(bottom: 100.0),
      //   child: FloatingActionButton.extended(
      //     onPressed: () {
      //       ScaffoldMessenger.of(context).showSnackBar(
      //         const SnackBar(
      //           content: Text('Функция поиска в разработке'),
      //           backgroundColor: Color(0xFFF7B84B),
      //         ),
      //       );
      //     },
      //     backgroundColor: const Color(0xFFF7B84B),
      //     label: const Text(
      //       'Поиск в этой области',
      //       style: TextStyle(
      //         color: Colors.white,
      //         fontWeight: FontWeight.w600,
      //       ),
      //     ),
      //     icon: const Icon(IconlyBold.search, color: Colors.white),
      //   ),
      // ),
    );
  }

  // Перемещение карты на начальное местоположение
  void _moveToInitialLocation() {
    _mapController.moveCamera(
      animation: const MapAnimation(type: MapAnimationType.linear, duration: 0.5),
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _defaultLocation,
          zoom: 12,
        ),
      ),
    );
  }

  // Создание объектов на карте (маркеры для объявлений)
  List<MapObject> _buildMapObjects() {
    final listings = [
      {
        'id': '1',
        'title': 'Продам 3к квартиру в центре',
        'price': '12 000 000 ₸',
        'location': 'ул. Абая, 15',
        'distance': '0.5 км',
        'latitude': 43.2220 + 0.005,
        'longitude': 76.8512 + 0.008,
      },
      {
        'id': '2',
        'title': 'Toyota Camry 2020',
        'price': '8 500 000 ₸',
        'location': 'пр. Достык, 89',
        'distance': '1.2 км',
        'latitude': 43.2220 - 0.003,
        'longitude': 76.8512 + 0.004,
      },
      {
        'id': '3',
        'title': 'iPhone 14 Pro Max',
        'price': '650 000 ₸',
        'location': 'ТРЦ Мега',
        'distance': '2.1 км',
        'latitude': 43.2220 + 0.007,
        'longitude': 76.8512 - 0.006,
      },
    ];
    
    List<MapObject> mapObjects = [];
    
    for (var listing in listings) {
      // mapObjects.add(
        // PlacemarkMapObject(
        //   mapId: MapObjectId('listing_${listing['id']}'),
        //   point: Point(
        //     latitude: listing['latitude'] as double,
        //     longitude: listing['longitude'] as double,
        //   ),
        //   icon: PlacemarkIcon.single(
        //     PlacemarkIconStyle(
        //       image: BitmapDescriptor.fromAssetImage('assets/icons/map.png'),
        //       scale: 1.5,
        //     ),
        //   ),
        //   text: PlacemarkText(
        //     text: listing['price'] as String,
        //     style: const PlacemarkTextStyle(
        //       placement: TextStylePlacement.bottom,
        //       color: Color(0xff183B4E),
        //       outlineColor: Colors.white,
        //     ),
        //   ),
        //   onTap: (_, __) {
        //     // При нажатии на маркер, открываем нижний лист на большую высоту
        //     _scrollController.animateTo(
        //       0.5,
        //       duration: const Duration(milliseconds: 300),
        //       curve: Curves.easeInOut,
        //     );
        //   },
        // ),
      // );
    }
    
    return mapObjects;
  }

  Widget _buildMapPin(String price, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF7B84B) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? const Color(0xFFF7B84B) : Colors.grey.shade300,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        price,
        style: TextStyle(
          color: isSelected ? Colors.white : const Color(0xff183B4E),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildListingCard(int index) {
    final listings = [
      {
        'title': 'Продам 3к квартиру в центре',
        'price': '12 000 000 ₸',
        'location': 'ул. Абая, 15',
        'distance': '0.5 км',
        'image': 'assets/images/image.webp',
      },
      {
        'title': 'Toyota Camry 2020',
        'price': '8 500 000 ₸',
        'location': 'пр. Достык, 89',
        'distance': '1.2 км',
        'image': 'assets/images/image.webp',
      },
      {
        'title': 'iPhone 14 Pro Max',
        'price': '650 000 ₸',
        'location': 'ТРЦ Мега',
        'distance': '2.1 км',
        'image': 'assets/images/image.webp',
      },
    ];

    final listing = listings[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              listing['image']!,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing['title']!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff183B4E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  listing['price']!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF7B84B),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      IconlyBroken.location,
                      size: 12,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${listing['location']} • ${listing['distance']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            IconlyBroken.arrowRight2,
            size: 16,
            color: Colors.grey[400],
          ),
        ],
      ),
    );
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Фильтры',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xff183B4E),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Радиус поиска',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xff183B4E),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: ['1 км', '5 км', '10 км', '25 км'].map((radius) {
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7B84B).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          radius,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFF7B84B),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF7B84B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Применить фильтры',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
