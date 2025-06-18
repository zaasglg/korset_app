import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:korset_app/auth/login.dart';
import 'package:korset_app/auth/register.dart';
import 'package:korset_app/pages/publish_ad.dart';
import 'package:korset_app/pages/favorites.dart';
import 'package:korset_app/pages/referral.dart';
import 'package:korset_app/pages/settings.dart';
import 'package:korset_app/services/auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = false;

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
      body: FutureBuilder<bool>(
        future: AuthService.isAuthenticated(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final isAuthenticated = snapshot.data ?? false;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13.0),
              child: Column(
                children: [
                  if (!isAuthenticated) ...[
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
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    const Color(0xff183B4E),
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                              ),
                                              onPressed: () {
                                                Navigator.pop(context);
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        const LoginPage(),
                                                  ),
                                                );
                                              },
                                              child: const Text(
                                                "Войти через телефон",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
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
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    const Color(0xff183B4E)
                                                        .withOpacity(0.1),
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                              ),
                                              onPressed: () {
                                                Navigator.pop(context);
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        const RegisterPage(),
                                                  ),
                                                );
                                              },
                                              child: const Text(
                                                "Зарегестрироваться",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
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
                      future: AuthService.getUser(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final user = snapshot.data;
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Ваш кошелек:",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  "0,00 ₸",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xff183B4E),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Бонусы: 0,00 Бонусы",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            InkWell(
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const PublishAdPage()));
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFFBE6),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                child: const Row(
                                  children: [
                                    Icon(IconlyBroken.plus, color: Color(0xff183B4E)),
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
                                    Icon(IconlyBroken.arrowRight2, color: Color(0xff183B4E)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFE6F6FF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                              child: const Row(
                                children: [
                                  Icon(IconlyBroken.buy, color: Color(0xff183B4E)),
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
                                  Icon(IconlyBroken.arrowRight2, color: Color(0xff183B4E)),
                                ],
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
                            const SizedBox(height: 8),
                            Text(
                              user?['email'] ?? '',
                              style: const TextStyle(
                                fontSize: 16.0,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],

                  CupertinoListSection(
                    backgroundColor: Colors.white,
                    children: <CupertinoListTile>[
                      if (isAuthenticated) ...[
                        CupertinoListTile(
                          leading: const Icon(IconlyBroken.setting),
                          padding: const EdgeInsets.symmetric(vertical: 13.0),
                          title: const Text('Настройки профиля'),
                          trailing: const CupertinoListTileChevron(),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SettingsPage(),
                              ),
                            );
                          },
                        ),
                      ],
                      CupertinoListTile(
                        leading: const Icon(IconlyBroken.heart),
                        padding: const EdgeInsets.symmetric(vertical: 13.0),
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
                        padding: const EdgeInsets.symmetric(vertical: 13.0),
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
                      CupertinoListTile(
                        leading: const Icon(IconlyBroken.call),
                        padding: const EdgeInsets.symmetric(vertical: 13.0),
                        title: const Text('Свяжитесь с нами'),
                        trailing: const CupertinoListTileChevron(),
                        onTap: () {},
                      ),
                      CupertinoListTile(
                        leading: const Icon(IconlyBroken.document),
                        padding: const EdgeInsets.symmetric(vertical: 13.0),
                        title: const Text('Правила публикаии отзыва'),
                        trailing: const CupertinoListTileChevron(),
                        onTap: () {},
                      ),
                      CupertinoListTile(
                        leading: const Icon(IconlyBroken.document),
                        padding: const EdgeInsets.symmetric(vertical: 13.0),
                        title: const Text('Публичная оферта'),
                        trailing: const CupertinoListTileChevron(),
                        onTap: () {},
                      ),
                      CupertinoListTile(
                        leading: const Icon(IconlyBroken.document),
                        padding: const EdgeInsets.symmetric(vertical: 13.0),
                        title: const Text('Политика конфидецианльности'),
                        trailing: const CupertinoListTileChevron(),
                        onTap: () {},
                      ),
                      CupertinoListTile(
                        leading: const Icon(IconlyBroken.profile),
                        padding: const EdgeInsets.symmetric(vertical: 13.0),
                        title: const Text('О нас'),
                        trailing: const CupertinoListTileChevron(),
                        onTap: () {},
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
                  if (isAuthenticated) ...[
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
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Выйти",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          color: Colors.black,
                                          letterSpacing: 0.5,
                                          decoration: TextDecoration.underline
                                        ),
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
          );
        },
      ),
    );
  }
}
