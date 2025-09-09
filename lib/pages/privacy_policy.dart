import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

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
          "Политика конфиденциальности",
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
              // Заголовок
              const Text(
                "О персональных данных и их защите",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff183B4E),
                ),
              ),
              const SizedBox(height: 24),
              
              // Основной текст
              const Text(
                "Предоставляя свои персональные данные Пользователь дает согласие на обработку, хранение и использование своих персональных данных на основании Закон РК № 179-VII ",
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
              
              const Text(
                "«О персональных данных и их защите»",
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Color(0xff183B4E),
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              const Text(
                " от 30.12.22 г. в следующих целях:",
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Цели обработки
              const Text(
                "Цели обработки персональных данных:",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xff183B4E),
                ),
              ),
              const SizedBox(height: 16),
              
              _buildBulletPoint("Осуществление клиентской поддержки"),
              _buildBulletPoint("Получения Пользователем информации о маркетинговых событиях"),
              _buildBulletPoint("Проведения аудита и прочих внутренних исследований с целью повышения качества предоставляемых услуг."),
              
              const SizedBox(height: 24),
              
              // Что включают персональные данные
              const Text(
                "Под персональными данными подразумевается любая информация личного характера, позволяющая установить личность Пользователя/Покупателя такая как:",
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
              
              const SizedBox(height: 16),
              
              _buildBulletPoint("Фамилия, Имя, Отчество"),
              _buildBulletPoint("Дата рождения"),
              _buildBulletPoint("Контактный телефон"),
              _buildBulletPoint("Адрес электронной почты"),
              _buildBulletPoint("Почтовый адрес"),
              
              const SizedBox(height: 24),
              
              // Хранение и защита
              const Text(
                "Персональные данные Пользователей хранятся исключительно на электронных носителях и обрабатываются с использованием автоматизированных систем, за исключением случаев, когда неавтоматизированная обработка персональных данных необходима в связи с исполнением требований законодательства.",
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Обязательства компании
              const Text(
                "Компания обязуется не передавать полученные персональные данные третьим лицам, за исключением следующих случаев:",
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
              
              const SizedBox(height: 16),
              
              _buildBulletPoint("По запросам уполномоченных органов государственной власти РК только по основаниям и в порядке, установленным законодательством РК"),
              _buildBulletPoint("Стратегическим партнерам, которые работают с Компанией для предоставления продуктов и услуг, или тем из них, которые помогают Компании реализовывать продукты и услуги потребителям. Мы предоставляем третьим лицам минимальный объем персональных данных, необходимый только для оказания требуемой услуги или проведения необходимой транзакции."),
              
              const SizedBox(height: 24),
              
              // Изменения в политике
              const Text(
                "Компания оставляет за собой право вносить изменения в одностороннем порядке в настоящие правила, при условии, что изменения не противоречат действующему законодательству РК. Изменения условий настоящих правил вступают в силу после их публикации на Сайте.",
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Контактная информация
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Контактная информация",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xff183B4E),
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      "Если у вас есть вопросы относительно данной политики конфиденциальности, пожалуйста, свяжитесь с нами:",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Email: support@korset.kz",
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xff183B4E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Телефон: +7 (777) 123-45-67",
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xff183B4E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "• ",
            style: TextStyle(
              fontSize: 16,
              color: Color(0xff183B4E),
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
