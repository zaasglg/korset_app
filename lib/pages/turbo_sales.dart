import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';

class TurboSalesPage extends StatefulWidget {
  const TurboSalesPage({super.key});

  @override
  State<TurboSalesPage> createState() => _TurboSalesPageState();
}

class _TurboSalesPageState extends State<TurboSalesPage> {
  String selectedPlan = 'basic';
  
  final List<Map<String, dynamic>> plans = [
    {
      'id': 'basic',
      'name': 'Базовый',
      'price': '2 990',
      'duration': '3 дня',
      'color': const Color(0xFFD16DD2),
      'features': [
        'Поднятие в топ 3 раза в день',
        'Выделение цветом',
        'Значок "Турбо"',
        'Статистика просмотров',
      ],
    },
    {
      'id': 'premium',
      'name': 'Премиум',
      'price': '4 990',
      'duration': '7 дней',
      'color': const Color(0xFFB83DBA),
      'features': [
        'Поднятие в топ 5 раз в день',
        'Выделение цветом',
        'Значок "Турбо Премиум"',
        'Детальная статистика',
        'Приоритет в поиске',
        'Показ в рекомендациях',
      ],
    },
    {
      'id': 'vip',
      'name': 'VIP',
      'price': '9 990',
      'duration': '14 дней',
      'color': const Color(0xFF9B59B6),
      'features': [
        'Поднятие в топ 8 раз в день',
        'Золотое выделение',
        'Значок "VIP"',
        'Полная аналитика',
        'Максимальный приоритет',
        'Показ на главной странице',
        'Персональный менеджер',
      ],
    },
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
          'Турбо продажа',
          style: TextStyle(
            color: Color(0xff183B4E),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFD16DD2), Color(0xFFB83DBA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD16DD2).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      IconlyBold.star,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Турбо продажа',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ваше объявление увидит максимум покупателей',
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

            // Statistics
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Больше просмотров',
                    value: '15x',
                    subtitle: 'чем обычно',
                    color: const Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Быстрее продажа',
                    value: '3x',
                    subtitle: 'в среднем',
                    color: const Color(0xFF2196F3),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Plans Section
            const Text(
              'Выберите тариф',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xff183B4E),
              ),
            ),
            const SizedBox(height: 16),

            Column(
              children: plans.map((plan) => _buildPlanCard(plan)).toList(),
            ),

            const SizedBox(height: 30),

            // How it works
            const Text(
              'Как работает Турбо',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xff183B4E),
              ),
            ),
            const SizedBox(height: 16),

            _buildHowItWorksItem(
              icon: Icons.trending_up,
              title: 'Поднятие в топ',
              description: 'Ваше объявление автоматически поднимается в начало списка несколько раз в день',
            ),
            
            _buildHowItWorksItem(
              icon: IconlyBold.star,
              title: 'Выделение',
              description: 'Объявление выделяется специальным цветом и значком среди других',
            ),
            
            _buildHowItWorksItem(
              icon: Icons.bar_chart,
              title: 'Приоритет в поиске',
              description: 'Ваше объявление показывается первым в результатах поиска',
            ),

            const SizedBox(height: 30),

            // CTA Button
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFD16DD2), Color(0xFFB83DBA)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD16DD2).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _showPaymentDialog(),
                  child: Center(
                    child: Text(
                      'Активировать за ${plans.firstWhere((p) => p['id'] == selectedPlan)['price']} ₸',
                      style: const TextStyle(
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
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final isSelected = plan['id'] == selectedPlan;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPlan = plan['id'];
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? plan['color'] : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? plan['color'].withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
              blurRadius: isSelected ? 15 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan['name'],
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? plan['color'] : const Color(0xff183B4E),
                      ),
                    ),
                    Text(
                      plan['duration'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${plan['price']} ₸',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? plan['color'] : const Color(0xff183B4E),
                      ),
                    ),
                    if (isSelected)
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: plan['color'],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...plan['features'].map<Widget>((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.check,
                    size: 16,
                    color: isSelected ? plan['color'] : Colors.grey[400],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feature,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xff183B4E),
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHowItWorksItem({
    required IconData icon,
    required String title,
    required String description,
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
              color: const Color(0xFFD16DD2).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFFD16DD2),
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

  void _showPaymentDialog() {
    final selectedPlanData = plans.firstWhere((p) => p['id'] == selectedPlan);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Подтверждение покупки',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xff183B4E),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Тариф: ${selectedPlanData['name']}'),
            Text('Срок: ${selectedPlanData['duration']}'),
            Text('Стоимость: ${selectedPlanData['price']} ₸'),
            const SizedBox(height: 16),
            const Text(
              'После активации ваше объявление получит максимальную видимость.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Турбо продажа активирована!'),
                  backgroundColor: Color(0xFFD16DD2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: selectedPlanData['color'],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Активировать',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
