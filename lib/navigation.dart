import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:korset_app/pages/catalog.dart';
import 'package:korset_app/pages/home.dart';
import 'package:korset_app/pages/profile.dart';
import 'package:korset_app/pages/publish_ad.dart'; // Using improved version
import 'package:korset_app/pages/chat.dart';
import 'package:korset_app/auth/login.dart';
import 'package:korset_app/auth/multi_step_register.dart';
import 'package:korset_app/services/auth_service.dart';
import 'package:korset_app/services/image_url_helper.dart';

class NavigationMenu extends StatefulWidget {
  final int initialIndex;

  const NavigationMenu({super.key, this.initialIndex = 0});

  @override
  State<NavigationMenu> createState() => _NavigationMenuState();
}

class _NavigationMenuState extends State<NavigationMenu> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    // Принудительно обновляем user из API при запуске
    AuthService.refreshUserFromApi().then((_) {
      setState(() {});
    });
  }

  // List of widget screens for each tab
  final List<Widget> _pages = const [
    HomePage(),
    CatalogPage(),
    PublishAdPage(),
    // ChatPage(),
    ChatPage(),
    ProfilePage()
  ];

  // Method to handle item taps
  void _onItemTapped(int index) async {
    // Проверяем авторизацию для страницы "Продать" (индекс 2)
    if (index == 2) {
      final user = await AuthService.getUser();
      if (user == null) {
        // Показываем BottomSheet с просьбой авторизоваться
        _showAuthBottomSheet();
        return;
      }
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  void _showAuthBottomSheet() {
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
            const Text(
              "Авторизация требуется",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Пожалуйста, авторизуйтесь для размещения объявлений",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff183B4E),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginPage(),
                    ),
                  );
                  // Если авторизация прошла успешно, обновляем состояние
                  if (result == true) {
                    // Можно добавить обновление состояния здесь, если нужно
                    // Например, через setState или другой механизм
                  }
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
                      const Color(0xff183B4E).withValues(alpha: 0.1),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MultiStepRegisterPage(),
                    ),
                  );
                },
                child: const Text(
                  "Зарегистрироваться",
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(
                color: Colors.black26,
                width: 0.5,
              ),
            ),
          ),
          padding: const EdgeInsets.only(top: 9),
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            items: <BottomNavigationBarItem>[
              const BottomNavigationBarItem(
                icon: Icon(
                  IconlyBroken.home,
                ),
                label: 'Главная',
              ),
              const BottomNavigationBarItem(
                icon: Icon(IconlyBroken.category),
                label: 'Каталог',
              ),
              const BottomNavigationBarItem(
                icon: Icon(IconlyBroken.plus),
                label: 'Продать',
              ),
              BottomNavigationBarItem(
                icon: Stack(
                  children: <Widget>[
                    const Icon(IconlyBroken.chat), // Main icon
                    Positioned(
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: const Color(0xff183B4E),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 15,
                          minHeight: 15,
                        ),
                        child: const Text(
                          '0', // The badge count
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  ],
                ),
                label: 'Чат',
              ),
              BottomNavigationBarItem(
                icon: FutureBuilder<Map<String, dynamic>?>(
                  future: AuthService.getUser(),
                  builder: (context, snapshot) {
                    // Default icon while loading or if no user
                    if (!snapshot.hasData || snapshot.data == null) {
                      return const Icon(IconlyBroken.profile);
                    }

                    final user = snapshot.data!;
                    print("USer: $user");
                    final raw = user['avatar']?.toString();
                    print('NAV: user["avatar"] = $raw');
                    // Build absolute URL if needed and validate
                    final url = ImageUrlHelper.getImageUrl(raw);
                    print('NAV: avatar url = $url');

                    if (url.isEmpty) {
                      return Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: AssetImage('assets/icons/no_avatar.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    }

                    // Render avatar only for valid http(s) URLs
                    final isHttp =
                        url.startsWith('http://') || url.startsWith('https://');
                    if (!isHttp) {
                      return Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: AssetImage('assets/icons/no_avatar.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    }

                    // Show avatar from network with graceful fallback
                    return Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Image.asset('assets/icons/no_avatar.png',
                                fit: BoxFit.cover),
                      ),
                    );
                  },
                ),
                label: 'Профиль',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: const Color(0xff183B4E),
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
          ),
        ),
      ),
    );
  }
}
