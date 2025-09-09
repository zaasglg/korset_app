import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';

class OnlineStoresPage extends StatefulWidget {
  const OnlineStoresPage({super.key});

  @override
  State<OnlineStoresPage> createState() => _OnlineStoresPageState();
}

class _OnlineStoresPageState extends State<OnlineStoresPage> {
  List<Map<String, dynamic>> stores = [
    {"image": "assets/images/image.webp", "name": "TechnoStore", "rating": 5, "adsCount": 127},
    {"image": "assets/images/image.webp", "name": "FashionHub", "rating": 4, "adsCount": 89},
    {"image": null, "name": "AutoParts KZ", "rating": 5, "adsCount": 156},
    {"image": null, "name": "BeautyWorld", "rating": 4, "adsCount": 73},
    {"image": null, "name": "SportZone", "rating": 5, "adsCount": 94},
    {"image": "assets/images/image.webp", "name": "HomeDecor", "rating": 4, "adsCount": 52},
    {"image": null, "name": "Автосалон Premium", "rating": 5, "adsCount": 120},
    {"image": null, "name": "Риэлтор Алия", "rating": 4, "adsCount": 85},
    {"image": null, "name": "АвтоМаркет", "rating": 5, "adsCount": 150},
  ];

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
          'Магазины',
          style: TextStyle(
            color: Color(0xff183B4E),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
        ),
        itemCount: stores.length,
        itemBuilder: (context, index) {
          final store = stores[index];
          return _buildGridStoreCard(
            image: store["image"] as String?,
            name: store["name"] as String,
            rating: (store["rating"] as num).toInt(),
            adsCount: store["adsCount"] as int,
          );
        },
      ),
    );
  }

  Widget _buildGridStoreCard({
    String? image,
    required String name,
    required int rating,
    required int adsCount,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Store avatar
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xff183B4E).withValues(alpha: 0.1),
                    const Color(0xff56A3E6).withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: image != null
                    ? Image.asset(
                        image,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      )
                    : const Icon(
                        IconlyBold.bag2,
                        size: 30,
                        color: Color(0xff183B4E),
                      ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Store name
            Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Rating and ads count
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      size: 12,
                      color: index < rating 
                        ? const Color(0xFFFFB800) 
                        : Colors.grey[300],
                    );
                  }),
                ),
              ],
            ),
            
            const SizedBox(height: 4),
            
            Text(
              "$adsCount объявлений",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
