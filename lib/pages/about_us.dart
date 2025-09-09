import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(IconlyBroken.arrowLeft, color: Color(0xff183B4E)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text(
          "О нас",
          style: TextStyle(
            fontFamily: "avenir",
            fontWeight: FontWeight.w600,
            color: Color(0xff183B4E),
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo section
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xff183B4E).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    IconlyBroken.buy,
                    size: 50,
                    color: Color(0xff183B4E),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Company name
              const Center(
                child: Text(
                  "Korset.kz",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff183B4E),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              
              const Center(
                child: Text(
                  "Ведущая платформа объявлений в Казахстане",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Mission section
              const Text(
                "Наша миссия",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff183B4E),
                ),
              ),
              const SizedBox(height: 16),
              
              const Text(
                "Мы стремимся создать лучшую платформу для покупки и продажи товаров в Казахстане, где каждый пользователь может легко найти то, что ищет, или продать свои товары быстро и безопасно.",
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // What we offer section
              const Text(
                "Что мы предлагаем",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff183B4E),
                ),
              ),
              const SizedBox(height: 16),
              
              _buildFeatureItem(
                icon: IconlyBroken.search,
                title: "Удобный поиск",
                description: "Найдите нужный товар среди тысяч объявлений с помощью умного поиска и фильтров",
              ),
              
              _buildFeatureItem(
                icon: IconlyBroken.shieldDone,
                title: "Безопасность",
                description: "Мы обеспечиваем безопасные сделки и защищаем данные наших пользователей",
              ),
              
              _buildFeatureItem(
                icon: IconlyBroken.heart,
                title: "Избранное",
                description: "Сохраняйте интересные объявления в избранном для быстрого доступа",
              ),
              
              _buildFeatureItem(
                icon: IconlyBroken.call,
                title: "Поддержка 24/7",
                description: "Наша команда поддержки всегда готова помочь вам решить любые вопросы",
              ),
              
              const SizedBox(height: 32),
              
              
              const SizedBox(height: 32),
              
              // Team section
              const Text(
                "Наша команда",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff183B4E),
                ),
              ),
              const SizedBox(height: 16),
              
              const Text(
                "Мы - команда опытных специалистов, которые работают над тем, чтобы сделать процесс покупки и продажи максимально простым и удобным для всех пользователей.",
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Contact section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Свяжитесь с нами",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xff183B4E),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    _buildContactInfo(
                      icon: IconlyBroken.message,
                      title: "Email",
                      info: "info@korset.kz",
                    ),
                    
                    _buildContactInfo(
                      icon: IconlyBroken.call,
                      title: "Телефон",
                      info: "+7 (777) 123-45-67",
                    ),
                    
                    _buildContactInfo(
                      icon: IconlyBroken.location,
                      title: "Адрес",
                      info: "г. Алматы, ул. Абая 150/230",
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Version info
              const Center(
                child: Text(
                  "Версия приложения: 1.0.0",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              const Center(
                child: Text(
                  "© 2024 Korset.kz. Все права защищены.",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xff183B4E).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xff183B4E),
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
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(String number, String label) {
    return Column(
      children: [
        Text(
          number,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xff183B4E),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  Widget _buildContactInfo({
    required IconData icon,
    required String title,
    required String info,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xff183B4E),
            size: 20,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                info,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
