import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:korset_app/auth/multi_step_register.dart';
import 'package:korset_app/components/product_image_widget.dart';
import 'package:korset_app/pages/turbo_sales.dart';
import 'package:korset_app/services/image_url_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:korset_app/auth/login.dart';
import 'package:korset_app/pages/publish_ad.dart';
import 'package:korset_app/pages/favorites.dart';
import 'package:korset_app/pages/referral.dart';
import 'package:korset_app/pages/settings.dart';
import 'package:korset_app/pages/privacy_policy.dart';
import 'package:korset_app/pages/about_us.dart';
import 'package:korset_app/pages/detail.dart';
import 'package:korset_app/pages/edit_ad.dart';
import 'package:korset_app/services/auth_service.dart';
import 'package:korset_app/services/product_service.dart';
import 'package:korset_app/services/wallet_service.dart';
import 'package:korset_app/models/product.dart';
import 'package:korset_app/models/wallet.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = false;
  bool? _isAuthenticated;
  final ProductService _productService = ProductService();
  int _refreshKey = 0;
  int _userRefreshKey = 0;

  // Упрощенные переменные для кошелька
  Wallet? _wallet;
  bool _isWalletLoading = false;
  String? _walletError;
  bool _hasInitializedWallet =
      false; // Флаг для предотвращения двойной инициализации

  // Метод для обновления списка продуктов
  void _refreshProducts() {
    if (mounted) {
      setState(() {
        _refreshKey++;
      });
    }
  }

  // Объединенный метод для обновления продуктов и баланса
  Future<void> _refreshAllData() async {
    debugPrint('PROFILE: Начинаем объединенное обновление данных...');

    // Обновляем продукты
    _refreshProducts();

    // Если пользователь авторизован, обновляем его данные
    if (_isAuthenticated == true) {
      await _refreshUserData();

      // Обновляем кошелек только если он не загружается уже
      if (!_isWalletLoading) {
        _refreshWalletData();
      }
    }

    debugPrint('PROFILE: Объединенное обновление завершено');
  }

  // Метод для обновления состояния профиля
  void _refreshProfile() {
    if (mounted) {
      setState(() {
        // Просто обновляем состояние
      });
    }
  }

  // Метод для обновления данных пользователя с сервера
  Future<void> _refreshUserData() async {
    try {
      debugPrint('PROFILE: Обновляем данные пользователя...');
      await AuthService.refreshUserFromApi();
      debugPrint('PROFILE: Данные пользователя обновлены');

      if (mounted) {
        setState(() {
          // Обновляем ключ для принудительного обновления FutureBuilder с данными пользователя
          _userRefreshKey++;
        });
      }
    } catch (e) {
      debugPrint('PROFILE: Ошибка обновления данных пользователя: $e');
    }
  }

  // Простой метод для загрузки данных кошелька
  Future<void> _loadWallet() async {
    if (!mounted || _isAuthenticated != true) return;

    // Предотвращаем множественные одновременные запросы
    if (_isWalletLoading) return;

    setState(() {
      _isWalletLoading = true;
      _walletError = null;
    });

    try {
      final wallet = await WalletService.getWallet();
      if (mounted) {
        setState(() {
          _wallet = wallet;
          _isWalletLoading = false;
          _hasInitializedWallet = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _walletError = e.toString();
          _isWalletLoading = false;
          _hasInitializedWallet = true;
        });
      }
    }
  }

  // Метод для обновления данных кошелька
  void _refreshWalletData() {
    // Предотвращаем множественные одновременные обновления
    if (!_isWalletLoading) {
      debugPrint('PROFILE: Начинаем обновление кошелька...');
      _loadWallet();
    } else {
      debugPrint('PROFILE: Кошелек уже обновляется, пропускаем...');
    }
  }

  // Метод для показа диалога пополнения баланса
  void _showTopUpDialog() {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Пополнить баланс',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xff183B4E),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Введите сумму пополнения:',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: 'Например: 1000',
                  suffixText: '₸',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Описание (необязательно):',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  hintText: 'Пополнение баланса',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Отмена',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final amountText = amountController.text.trim();
                if (amountText.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Введите сумму пополнения'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final amount = double.tryParse(amountText);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Введите корректную сумму'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.of(context).pop();
                _processTopUp(
                  amount,
                  descriptionController.text.trim().isEmpty
                      ? null
                      : descriptionController.text.trim(),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff183B4E),
                foregroundColor: Colors.white,
              ),
              child: const Text('Пополнить'),
            ),
          ],
        );
      },
    );
  }

  // Метод для обработки пополнения баланса
  Future<void> _processTopUp(double amount, String? description) async {
    try {
      // Показываем индикатор загрузки
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Создаем платеж...'),
              ],
            ),
          );
        },
      );

      // Вызываем API для создания платежа
      final paymentData = await WalletService.topUpBalance(
        amount: amount,
        description: description,
      );

      // Закрываем диалог загрузки
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (paymentData != null && paymentData['payment_url'] != null) {
        // Показываем успешный диалог с кнопкой перехода к оплате
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text(
                  'Платеж создан',
                  style: TextStyle(
                    color: Color(0xff183B4E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                content: Text(
                  'Платеж на сумму ${amount.toStringAsFixed(2)} ₸ успешно создан.\n\nВы будете перенаправлены на страницу оплаты.',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Отмена'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      // Открываем URL для оплаты
                      final url = paymentData['payment_url'] as String;
                      if (await canLaunchUrl(Uri.parse(url))) {
                        await launchUrl(
                          Uri.parse(url),
                          mode: LaunchMode.externalApplication,
                        );
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Не удалось открыть страницу оплаты'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff183B4E),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Перейти к оплате'),
                  ),
                ],
              );
            },
          );
        }
      } else {
        // Показываем ошибку
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Не удалось создать платеж'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Закрываем диалог загрузки, если он открыт
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Показываем ошибку
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Метод для обновления состояния аутентификации
  Future<void> _updateAuthenticationStatus() async {
    final isAuth = await AuthService.checkAuthenticationStatus();
    if (mounted) {
      setState(() {
        _isAuthenticated = isAuth;
      });
    }
  }

  Future<void> _logout() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await AuthService.logout();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        await _updateAuthenticationStatus(); // Обновляем состояние
        _refreshProfile(); // Используем новый метод
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при выходе: ${e.toString()}')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  // Единый метод инициализации
  Future<void> _initializeData() async {
    await _updateAuthenticationStatus();
    if (_isAuthenticated == true && !_hasInitializedWallet) {
      _loadWallet();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Только обновляем статус аутентификации, без дублирования загрузки
    // Не вызываем загрузку данных здесь, чтобы избежать двойного обновления
    _updateAuthenticationStatus();
  }

  // Методы для работы с контактами
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        throw 'Could not launch $phoneUri';
      }
    } catch (e) {
      print('Error making phone call: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удается совершить звонок')),
        );
      }
    }
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    final Uri whatsappUri = Uri.parse('https://wa.me/$phoneNumber');
    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $whatsappUri';
      }
    } catch (e) {
      print('Error opening WhatsApp: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удается открыть WhatsApp')),
        );
      }
    }
  }

  Future<void> _openTelegram(String username) async {
    final Uri telegramUri = Uri.parse('https://t.me/$username');
    try {
      if (await canLaunchUrl(telegramUri)) {
        await launchUrl(telegramUri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $telegramUri';
      }
    } catch (e) {
      print('Error opening Telegram: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удается открыть Telegram')),
        );
      }
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query:
          'subject=Поддержка Korset.kz&body=Здравствуйте,%20у%20меня%20есть%20вопрос...',
    );
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        throw 'Could not launch $emailUri';
      }
    } catch (e) {
      print('Error sending email: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удается отправить email')),
        );
      }
    }
  }

  void _showContactModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            const Text(
              "Свяжитесь с нами",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xff183B4E),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Мы всегда готовы помочь вам",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),

            // Contact Options
            _buildContactOption(
              icon: IconlyBroken.call,
              title: "Позвонить",
              subtitle: "+7 (777) 123-45-67",
              onTap: () async {
                Navigator.pop(context);
                await _makePhoneCall("+77771234567");
              },
            ),
            const SizedBox(height: 16),

            _buildContactOption(
              icon: IconlyBroken.chat,
              title: "WhatsApp",
              subtitle: "+7 (777) 123-45-67",
              onTap: () async {
                Navigator.pop(context);
                await _openWhatsApp("+77771234567");
              },
            ),
            const SizedBox(height: 16),

            _buildContactOption(
              icon: IconlyBroken.message,
              title: "Telegram",
              subtitle: "@korset_support",
              onTap: () async {
                Navigator.pop(context);
                await _openTelegram("korset_support");
              },
            ),
            const SizedBox(height: 16),

            _buildContactOption(
              icon: IconlyBroken.message,
              title: "Электронная почта",
              subtitle: "support@korset.kz",
              onTap: () async {
                Navigator.pop(context);
                await _sendEmail("support@korset.kz");
              },
            ),
            const SizedBox(height: 32),

            // Working hours
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Часы работы",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff183B4E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Понедельник - Пятница: 09:00 - 18:00",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Суббота: 10:00 - 16:00",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Воскресенье: Выходной",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildContactOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[200]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xff183B4E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xff183B4E),
                  size: 20,
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
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                IconlyBroken.arrowRight2,
                color: Colors.grey,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductGridCard(Product product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailPage(productId: product.id),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(1)),
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      child: ProductImageWidget(
                        imageUrl: ImageUrlHelper.isValidPath(product.mainPhoto)
                            ? ImageUrlHelper.getImageUrl(product.mainPhoto)
                            : null,
                        videoUrl: ImageUrlHelper.isValidPath(product.videoUrl)
                            ? ImageUrlHelper.getVideoUrl(product.videoUrl)
                            : null,
                        videoPath: ImageUrlHelper.isValidPath(product.video)
                            ? ImageUrlHelper.getVideoUrl(product.video)
                            : null,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        fallbackAsset: 'assets/images/image.webp',
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
                      ),
                    ),
                  ),
                  // Status badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: product.status == 'active'
                            ? Colors.green[600]
                            : Colors.orange[600],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        product.status == 'active' ? 'Активно' : 'Неактивно',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  // More options button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          _showProductOptionsBottomSheet(context, product);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            IconlyBroken.moreCircle,
                            color: Colors.grey[700],
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Product Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${product.price} ₸",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff183B4E),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          IconlyBroken.location,
                          size: 12,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            product.city.name,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProductOptionsBottomSheet(BuildContext context, Product product) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              product.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            _buildProductOption(
              icon: IconlyBroken.show,
              title: "Просмотреть",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailPage(productId: product.id),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildProductOption(
              icon: IconlyBroken.edit,
              title: "Редактировать",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditAdPage(product: product),
                  ),
                ).then((result) {
                  // Если редактирование прошло успешно, обновляем список
                  if (result == true) {
                    _refreshProducts();
                  }
                });
              },
            ),
            const SizedBox(height: 12),
            _buildProductOption(
              icon: IconlyBroken.delete,
              title: "Удалить",
              isDestructive: true,
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, product);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProductOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[200]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color:
                    isDestructive ? Colors.red[600] : const Color(0xff183B4E),
                size: 20,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDestructive ? Colors.red[600] : Colors.black87,
                  ),
                ),
              ),
              Icon(
                IconlyBroken.arrowRight2,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Удалить объявление"),
        content: Text(
            "Вы уверены, что хотите удалить объявление \"${product.name}\"?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Отмена"),
          ),
          TextButton(
            onPressed: () async {
              // Закрываем диалог подтверждения
              Navigator.pop(context);
              
              // Показываем единственный диалог загрузки
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const AlertDialog(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Удаляем объявление...'),
                    ],
                  ),
                ),
              );

              try {
                print('Starting delete operation for product ID: ${product.id}');
                
                final success = await _productService.deleteProduct(product.id)
                    .timeout(
                      const Duration(seconds: 30),
                      onTimeout: () {
                        print('Delete operation timed out');
                        throw Exception('Операция удаления превысила время ожидания');
                      },
                    );

                print('Delete operation completed with success: $success');

                // Безопасно закрываем диалог загрузки
                if (mounted) {
                  // Небольшая задержка для стабилизации состояния
                  await Future.delayed(const Duration(milliseconds: 100));
                  
                  try {
                    // Пытаемся закрыть диалог
                    Navigator.of(context, rootNavigator: true).pop();
                    print('Loading dialog closed successfully');
                  } catch (e) {
                    print('Error closing loading dialog: $e');
                    // Резервный способ - попытка через обычный navigator
                    try {
                      Navigator.of(context).pop();
                      print('Loading dialog closed via regular navigator');
                    } catch (e2) {
                      print('Error closing via regular navigator: $e2');
                    }
                  }
                }

                if (success) {
                  _refreshProducts(); // Обновляем список
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Объявление успешно удалено"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Не удалось удалить объявление"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } catch (e) {
                print('Error during delete operation: $e');
                
                // Безопасно закрываем диалог загрузки в случае ошибки
                if (mounted) {
                  // Небольшая задержка для стабилизации состояния
                  await Future.delayed(const Duration(milliseconds: 100));
                  
                  try {
                    // Пытаемся закрыть диалог
                    Navigator.of(context, rootNavigator: true).pop();
                    print('Loading dialog closed after error');
                  } catch (e2) {
                    print('Error closing loading dialog after error: $e2');
                    // Резервный способ - попытка через обычный navigator
                    try {
                      Navigator.of(context).pop();
                      print('Loading dialog closed via regular navigator after error');
                    } catch (e3) {
                      print('Error closing via regular navigator after error: $e3');
                    }
                  }
                }
                
                if (mounted) {
                  String errorMessage = "Ошибка при удалении";
                  if (e.toString().contains('TimeoutException') || 
                      e.toString().contains('время ожидания')) {
                    errorMessage = "Превышено время ожидания. Попробуйте еще раз.";
                  } else if (e.toString().contains('ApiException')) {
                    errorMessage = "Ошибка сервера. Попробуйте позже.";
                  } else {
                    errorMessage = "Ошибка при удалении: ${e.toString()}";
                  }
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(errorMessage),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(
              "Удалить",
              style: TextStyle(color: Colors.red[600]),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "Профиль",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        elevation: 0,
      ),
      body: _isAuthenticated == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                debugPrint('PROFILE: Обновление по pull-to-refresh...');
                await _refreshAllData();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 13.0),
                  child: Column(
                    children: [
                      if (_isAuthenticated == false) ...[
                        // MARK: - Must Auth
                        Center(
                          child: Column(
                            children: [
                              const Text(
                                "Добро пожаловать в Korset.kz",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20.0,
                                ),
                              ),
                              const SizedBox(
                                height: 10.0,
                              ),
                              const Text(
                                "Войдите чтобы сохранить адрес доставки и историб заказов",
                                style: TextStyle(
                                  fontSize: 16.0,
                                  height: 1,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(
                                height: 15.0,
                              ),
                              SizedBox(
                                height: 50.0,
                                width: double.infinity,
                                child: Material(
                                  color: const Color(0xff183B4E),
                                  borderRadius: BorderRadius.circular(16.0),
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16.0),
                                    onTap: () {
                                      showModalBottomSheet(
                                        context: context,
                                        backgroundColor: Colors.white,
                                        isScrollControlled: true,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(24),
                                          ),
                                        ),
                                        builder: (context) => Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 24.0, vertical: 32.0),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 40,
                                                height: 4,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[300],
                                                  borderRadius:
                                                      BorderRadius.circular(2),
                                                ),
                                              ),
                                              const SizedBox(height: 24),
                                              const Text(
                                                "Добро пожаловать",
                                                style: TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              const Text(
                                                "Выберите способ входа",
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              const SizedBox(height: 32),
                                              SizedBox(
                                                width: double.infinity,
                                                height: 60,
                                                child: ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        const Color(0xff183B4E),
                                                    elevation: 0,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              16),
                                                    ),
                                                  ),
                                                  onPressed: () async {
                                                    Navigator.pop(context);
                                                    final result =
                                                        await Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            const LoginPage(),
                                                      ),
                                                    );
                                                    // Если авторизация прошла успешно, обновляем состояние
                                                    if (result == true) {
                                                      // Даем время для сохранения токена
                                                      await Future.delayed(
                                                          Duration(
                                                              milliseconds:
                                                                  100));
                                                      await _updateAuthenticationStatus(); // Обновляем состояние
                                                      _refreshProfile(); // Используем новый метод
                                                    }
                                                  },
                                                  child: const Text(
                                                    "Войти через телефон",
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              SizedBox(
                                                width: double.infinity,
                                                height: 60,
                                                child: ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        const Color(0xff183B4E)
                                                            .withOpacity(0.1),
                                                    elevation: 0,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              16),
                                                    ),
                                                  ),
                                                  onPressed: () async {
                                                    Navigator.pop(context);
                                                    final result =
                                                        await Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            const MultiStepRegisterPage(),
                                                      ),
                                                    );
                                                    // Если регистрация прошла успешно, обновляем состояние
                                                    if (result == true) {
                                                      // Даем время для сохранения токена
                                                      await Future.delayed(
                                                          Duration(
                                                              milliseconds:
                                                                  100));
                                                      await _updateAuthenticationStatus(); // Обновляем состояние
                                                      _refreshProfile(); // Используем новый метод
                                                    }
                                                  },
                                                  child: const Text(
                                                    "Зарегестрироваться",
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color(0xff183B4E),
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 24),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Center(
                                      child: Text(
                                        "Войти в профиль",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // MARK: - User Info
                        FutureBuilder<Map<String, dynamic>?>(
                          key: ValueKey(_userRefreshKey),
                          future: AuthService.getUser(),
                          builder: (context, snapshot) {
                            debugPrint(
                                'PROFILE: FutureBuilder для данных пользователя - состояние: ${snapshot.connectionState}');

                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }

                            final user = snapshot.data;
                            debugPrint(
                                'PROFILE: Данные пользователя получены: ${user?['name']}, avatar: ${user?['avatar']}');
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Привет, ${user?['name'] ?? 'пользователь'}!",
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xff183B4E),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                // Секция кошелька
                                Builder(
                                  builder: (context) {
                                    debugPrint(
                                        'PROFILE: Wallet Builder - loading: $_isWalletLoading, error: $_walletError');

                                    if (_isWalletLoading) {
                                      return Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[50],
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Row(
                                          children: [
                                            SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2),
                                            ),
                                            SizedBox(width: 12),
                                            Text("Загрузка данных кошелька..."),
                                          ],
                                        ),
                                      );
                                    }

                                    final hasError = _walletError != null;

                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Ваш кошелек:",
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                hasError
                                                    ? "Ошибка загрузки"
                                                    : "${_wallet?.currentBalance.toStringAsFixed(2) ?? '0,00'} ₸",
                                                style: TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                  color: hasError
                                                      ? Colors.red[600]
                                                      : const Color(0xff183B4E),
                                                ),
                                              ),
                                            ),
                                            if (hasError)
                                              Tooltip(
                                                message:
                                                    'Ошибка: $_walletError\nНажмите для обновления всех данных',
                                                child: GestureDetector(
                                                  onTap: () {
                                                    _refreshAllData();
                                                  },
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[100],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    child: Icon(
                                                      Icons.refresh,
                                                      size: 20,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                "Бонусы: 0,00 Бонусы",
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                _showTopUpDialog();
                                              },
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xff183B4E),
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                                child: const Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.add,
                                                      size: 16,
                                                      color: Colors.white,
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      "Пополнить",
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (hasError)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 8),
                                            child: Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.red[50],
                                                border: Border.all(
                                                    color: Colors.red[200]!),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.error_outline,
                                                        size: 16,
                                                        color: Colors.red[600],
                                                      ),
                                                      const SizedBox(width: 8),
                                                      const Text(
                                                        "Не удалось загрузить баланс",
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    (_walletError?.length ??
                                                                0) >
                                                            100
                                                        ? '${_walletError!.substring(0, 100)}...'
                                                        : _walletError ?? '',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.red[700],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 24),
                                InkWell(
                                  onTap: () async {
                                    final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const PublishAdPage()));
                                    // Если объявление было создано, обновляем все данные
                                    if (result == true && mounted) {
                                      _refreshAllData();
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFFBE6),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16, horizontal: 20),
                                    child: const Row(
                                      children: [
                                        Icon(IconlyBroken.plus,
                                            color: Color(0xff183B4E)),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            "Создать объявление",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xff183B4E),
                                            ),
                                          ),
                                        ),
                                        Icon(IconlyBroken.arrowRight2,
                                            color: Color(0xff183B4E)),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                InkWell(
                                  onTap: () {
                                    Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const TurboSalesPage()));
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE6F6FF),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16, horizontal: 20),
                                    child: const Row(
                                      children: [
                                        Icon(IconlyBroken.buy,
                                            color: Color(0xff183B4E)),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            "Купить пакет",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xff183B4E),
                                            ),
                                          ),
                                        ),
                                        Icon(IconlyBroken.arrowRight2,
                                            color: Color(0xff183B4E)),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  "Ваши объявления",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xff183B4E),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                FutureBuilder<List<Product>>(
                                  key: ValueKey(_refreshKey),
                                  future:
                                      _productService.getUserProducts(limit: 5),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(20.0),
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    }

                                    if (snapshot.hasError) {
                                      return Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.red[50],
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: Colors.red[200]!),
                                        ),
                                        child: Column(
                                          children: [
                                            Icon(
                                              IconlyBroken.danger,
                                              color: Colors.red[600],
                                              size: 32,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              "Ошибка загрузки объявлений",
                                              style: TextStyle(
                                                color: Colors.red[800],
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              snapshot.error.toString(),
                                              style: TextStyle(
                                                color: Colors.red[600],
                                                fontSize: 12,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      );
                                    }

                                    final products = snapshot.data ?? [];

                                    if (products.isEmpty) {
                                      return Container(
                                        padding: const EdgeInsets.all(24),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[50],
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: Colors.grey[200]!),
                                        ),
                                        child: Column(
                                          children: [
                                            Icon(
                                              IconlyBroken.document,
                                              color: Colors.grey[400],
                                              size: 48,
                                            ),
                                            const SizedBox(height: 12),
                                            const Text(
                                              "У вас пока нет объявлений",
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              "Создайте свое первое объявление",
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      const Color(0xff183B4E),
                                                  elevation: 0,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                ),
                                                onPressed: () async {
                                                  final result =
                                                      await Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          const PublishAdPage(),
                                                    ),
                                                  );
                                                  // Если объявление было создано, обновляем список
                                                  if (result == true &&
                                                      mounted) {
                                                    _refreshAllData();
                                                  }
                                                },
                                                child: const Text(
                                                  "Создать объявление",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }

                                    return Column(
                                      children: [
                                        GridView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          gridDelegate:
                                              const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2,
                                            crossAxisSpacing: 12,
                                            mainAxisSpacing: 12,
                                            childAspectRatio: 0.75,
                                          ),
                                          itemCount: products.length > 4
                                              ? 4
                                              : products.length,
                                          itemBuilder: (context, index) {
                                            return _buildProductGridCard(
                                                products[index]);
                                          },
                                        ),
                                        if (products.length > 4)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 16),
                                            child: TextButton(
                                              onPressed: () {
                                                // TODO: Navigate to full products list
                                                // Пока что просто показываем сообщение
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                        "Страница со всеми объявлениями будет добавлена"),
                                                  ),
                                                );
                                              },
                                              child: Text(
                                                "Показать все (${products.length})",
                                                style: const TextStyle(
                                                  color: Color(0xff183B4E),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                      CupertinoListSection(
                        backgroundColor: Colors.white,
                        children: <CupertinoListTile>[
                          if (_isAuthenticated!) ...[
                            CupertinoListTile(
                              leading: const Icon(IconlyBroken.setting),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 13.0),
                              title: const Text('Настройки профиля'),
                              trailing: const CupertinoListTileChevron(),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SettingsPage(),
                                  ),
                                );

                                // После возврата из настроек обновляем данные пользователя
                                debugPrint(
                                    'PROFILE: Возврат из настроек, обновляем данные...');
                                await _refreshUserData();
                              },
                            ),
                            CupertinoListTile(
                              leading: const Icon(IconlyBroken.heart),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 13.0),
                              title: const Text('Избранное'),
                              trailing: const CupertinoListTileChevron(),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const FavoritesPage(),
                                  ),
                                );
                              },
                            ),
                            CupertinoListTile(
                              leading: const Icon(IconlyBroken.user2),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 13.0),
                              title: const Text('Реферальная ссылка'),
                              trailing: const CupertinoListTileChevron(),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ReferralPage(),
                                  ),
                                );
                              },
                            ),
                          ],
                          CupertinoListTile(
                            leading: const Icon(IconlyBroken.call),
                            padding: const EdgeInsets.symmetric(vertical: 13.0),
                            title: const Text('Свяжитесь с нами'),
                            trailing: const CupertinoListTileChevron(),
                            onTap: () {
                              _showContactModal(context);
                            },
                          ),
                          CupertinoListTile(
                            leading: const Icon(IconlyBroken.document),
                            padding: const EdgeInsets.symmetric(vertical: 13.0),
                            title: const Text('Политика конфидецианльности'),
                            trailing: const CupertinoListTileChevron(),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const PrivacyPolicyPage(),
                                ),
                              );
                            },
                          ),
                          CupertinoListTile(
                            leading: const Icon(IconlyBroken.profile),
                            padding: const EdgeInsets.symmetric(vertical: 13.0),
                            title: const Text('О нас'),
                            trailing: const CupertinoListTileChevron(),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AboutUsPage(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 10.0,
                      ),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Версия 1.0.0 (1)"),
                      ),
                      if (_isAuthenticated!) ...[
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: _isLoading ? null : _logout,
                              child: Container(
                                alignment: Alignment.center,
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Выйти",
                                            style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                                color: Colors.black,
                                                letterSpacing: 0.5,
                                                decoration:
                                                    TextDecoration.underline),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
