class FavoriteItem {
  final String id;
  final String title;
  final String location;
  final String price;
  final String image;
  final DateTime addedAt;

  const FavoriteItem({
    required this.id,
    required this.title,
    required this.location,
    required this.price,
    required this.image,
    required this.addedAt,
  });

  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    return FavoriteItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      location: json['location'] ?? '',
      price: json['price'] ?? '',
      image: json['image'] ?? '',
      addedAt: DateTime.tryParse(json['added_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'location': location,
      'price': price,
      'image': image,
      'added_at': addedAt.toIso8601String(),
    };
  }
}
