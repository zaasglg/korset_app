import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';

class OnlineStoresPage extends StatefulWidget {
  const OnlineStoresPage({super.key});

  @override
  State<OnlineStoresPage> createState() => _OnlineStoresPageState();
}

class _OnlineStoresPageState extends State<OnlineStoresPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String selectedCategory = 'Все';
  
  final List<String> categories = ['Все', 'Мода', 'Электроника', 'Дом', 'Красота', 'Спорт'];
  
  final List<Map<String, dynamic>> stores = [
    {
      'name': 'TechnoStore',
      'category': 'Электроника',
      'rating': 4.8,
      'products': 2847,
      'image': 'assets/images/image.webp',
      'verified': true,
      'description': 'Официальный дилер Apple, Samsung, Xiaomi',
      'discount': '20%',
    },
    {
      'name': 'FashionHub',
      'category': 'Мода',
      'rating': 4.6,
      'products': 1205,
      'image': 'assets/images/image.webp',
      'verified': true,
      'description': 'Стильная одежда для всей семьи',
      'discount': null,
    },
    {
      'name': 'BeautyWorld',
      'category': 'Красота',
      'rating': 4.9,
      'products': 890,
      'image': 'assets/images/image.webp',
      'verified': false,
      'description': 'Косметика и уход премиум класса',
      'discount': '15%',
    },
    {
      'name': 'SportZone',
      'category': 'Спорт',
      'rating': 4.7,
      'products': 1456,
      'image': 'assets/images/image.webp',
      'verified': true,
      'description': 'Все для активного образа жизни',
      'discount': '30%',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
          'Онлайн-магазины',
          style: TextStyle(
            color: Color(0xff183B4E),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(IconlyBroken.search, color: Color(0xff183B4E)),
            onPressed: () => _showSearchModal(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF5DBB6B),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF5DBB6B),
          tabs: const [
            Tab(text: 'Магазины'),
            Tab(text: 'Создать'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStoresTab(),
          _buildCreateStoreTab(),
        ],
      ),
    );
  }

  Widget _buildStoresTab() {
    final filteredStores = selectedCategory == 'Все' 
        ? stores 
        : stores.where((store) => store['category'] == selectedCategory).toList();

    return Column(
      children: [
        // Hero Section
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF5DBB6B), Color(0xFF4CAF50)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5DBB6B).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Онлайн-магазины',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Найдите лучшие предложения от проверенных продавцов',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '${124} магазинов',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  IconlyBold.buy,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        // Category Filter
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = category == selectedCategory;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedCategory = category;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF5DBB6B) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xff183B4E),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Stores List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filteredStores.length,
            itemBuilder: (context, index) {
              return _buildStoreCard(filteredStores[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCreateStoreTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Section for Create Store
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5DBB6B), Color(0xFF4CAF50)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [                  const Icon(
                    IconlyBold.plus,
                    size: 60,
                    color: Colors.white,
                  ),
                const SizedBox(height: 16),
                const Text(
                  'Создайте свой магазин',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Превратите свой профиль в полноценный интернет-магазин',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Benefits
          const Text(
            'Преимущества онлайн-магазина',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xff183B4E),
            ),
          ),
          const SizedBox(height: 16),

          _buildBenefitItem(
            icon: Icons.bar_chart,
            title: 'Увеличьте продажи',
            description: 'Привлекайте больше покупателей с профессиональным магазином',
            color: const Color(0xFF2196F3),
          ),
          
          _buildBenefitItem(
            icon: IconlyBold.star,
            title: 'Повысьте доверие',
            description: 'Верифицированный магазин вызывает больше доверия у покупателей',
            color: const Color(0xFFFF9800),
          ),
          
          _buildBenefitItem(
            icon: Icons.settings,
            title: 'Управляйте легко',
            description: 'Простые инструменты для управления товарами и заказами',
            color: const Color(0xFF9C27B0),
          ),

          const SizedBox(height: 30),

          // Steps to create
          const Text(
            'Как создать магазин',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xff183B4E),
            ),
          ),
          const SizedBox(height: 16),

          _buildStepCard('1', 'Заполните информацию', 'Название, описание, категория товаров'),
          _buildStepCard('2', 'Добавьте товары', 'Загрузите фото и описания ваших товаров'),
          _buildStepCard('3', 'Настройте доставку', 'Укажите способы доставки и оплаты'),
          _buildStepCard('4', 'Запустите магазин', 'Начните принимать заказы от покупателей'),

          const SizedBox(height: 30),

          // CTA Button
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5DBB6B), Color(0xFF4CAF50)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5DBB6B).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Функция создания магазина в разработке'),
                      backgroundColor: Color(0xFF5DBB6B),
                    ),
                  );
                },
                child: const Center(
                  child: Text(
                    'Создать магазин бесплатно',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreCard(Map<String, dynamic> store) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  store['image'],
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          store['name'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xff183B4E),
                          ),
                        ),
                        if (store['verified']) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.check,
                            size: 16,
                            color: Color(0xFF5DBB6B),
                          ),
                        ],
                        if (store['discount'] != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF4757),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '-${store['discount']}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      store['description'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Row(
                          children: [
                            const Icon(
                              IconlyBold.star,
                              size: 14,
                              color: Color(0xFFFFB800),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${store['rating']}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xff183B4E),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '${store['products']} товаров',
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
        ],
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff183B4E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard(String stepNumber, String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5DBB6B), Color(0xFF4CAF50)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                stepNumber,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff183B4E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSearchModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const Text(
                'Поиск магазинов',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff183B4E),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Введите название магазина или категорию',
                  prefixIcon: const Icon(IconlyBroken.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: stores.length,
                  itemBuilder: (context, index) {
                    return _buildStoreCard(stores[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
