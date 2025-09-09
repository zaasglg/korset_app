import 'package:flutter/material.dart';

import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../navigation.dart';
import 'change_password.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isUploadingAvatar = false;
  String? _errorMessage;
  String? _currentAvatarUrl;
  File? _selectedImage;

  var phoneMaskFormatter = MaskTextInputFormatter(
    mask: '+7 (###) ###-##-##',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await AuthService.getUser();
      if (user != null) {
        _nameController.text = user['name'] ?? '';
        _emailController.text = user['email'] ?? '';
        _phoneController.text = user['phone_number'] ?? '';

        String? avatarUrl = user['avatar'];
        debugPrint('Исходный URL аватара из данных: $avatarUrl');

        if (avatarUrl != null && avatarUrl.isNotEmpty && avatarUrl != 'null') {
          if (!avatarUrl.startsWith('http')) {
            // Добавляем базовый URL с /storage/ и слеш если нужно
            avatarUrl = avatarUrl.startsWith('/')
                ? 'https://videopokaz.kz/storage$avatarUrl'
                : 'https://videopokaz.kz/storage/$avatarUrl';
          }

          // Дополнительная проверка валидности URL
          final uri = Uri.tryParse(avatarUrl);
          if (uri != null && uri.hasScheme && uri.hasAuthority) {
            _currentAvatarUrl = avatarUrl;
          } else {
            debugPrint('Невалидный URL аватара: $avatarUrl');
            _currentAvatarUrl = null;
          }
        } else {
          _currentAvatarUrl = null;
        }

        debugPrint('Обработанный URL аватара: $_currentAvatarUrl');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка загрузки данных: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshUserDataFromServer() async {
    try {
      final apiService = ApiService();
      final response = await apiService.get('/api/user', requiresAuth: true);

      if (response != null && response['user'] != null) {
        await AuthService.saveUser(response['user']);
        debugPrint('Данные пользователя обновлены с сервера');

        // Обновляем UI с новыми данными
        final user = response['user'];
        setState(() {
          _nameController.text = user['name'] ?? '';
          _emailController.text = user['email'] ?? '';
          _phoneController.text = user['phone_number'] ?? '';

          // Обрабатываем URL аватара
          String? avatarUrl = user['avatar'];
          debugPrint('URL аватара с сервера: $avatarUrl');

          if (avatarUrl != null &&
              avatarUrl.isNotEmpty &&
              avatarUrl != 'null') {
            if (!avatarUrl.startsWith('http')) {
              // Добавляем базовый URL и слеш если нужно
              avatarUrl = avatarUrl.startsWith('/')
                  ? 'https://videopokaz.kz/storage/$avatarUrl'
                  : 'https://videopokaz.kz/storage/$avatarUrl';
            }

            // Дополнительная проверка валидности URL
            final uri = Uri.tryParse(avatarUrl);
            if (uri != null && uri.hasScheme && uri.hasAuthority) {
              _currentAvatarUrl = avatarUrl;
            } else {
              debugPrint('Невалидный URL аватара с сервера: $avatarUrl');
              _currentAvatarUrl = null;
            }
          } else {
            _currentAvatarUrl = null;
          }

          debugPrint('Финальный URL аватара: $_currentAvatarUrl');
          _selectedImage = null;
        });
      }
    } catch (e) {
      debugPrint('Ошибка обновления данных пользователя: $e');
      // Не выбрасываем ошибку, чтобы не прерывать процесс
    }
  }

  Future<void> _selectImageWithoutAutoUpload() async {
    try {
      final ImagePicker picker = ImagePicker();

      // Показываем диалог выбора источника
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              "Выберите источник",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading:
                      const Icon(Icons.camera_alt, color: Color(0xff183B4E)),
                  title: const Text("Камера"),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading:
                      const Icon(Icons.photo_library, color: Color(0xff183B4E)),
                  title: const Text("Галерея"),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          );
        },
      );

      if (source != null) {
        final XFile? image = await picker.pickImage(
          source: source,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 85,
        );

        if (image != null) {
          debugPrint('Изображение выбрано: ${image.path}');

          setState(() {
            _selectedImage = File(image.path);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка выбора изображения: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadAvatar() async {
    if (_selectedImage == null) return;

    setState(() {
      _isUploadingAvatar = true;
      _errorMessage = null;
    });

    try {
      final apiService = ApiService();

      debugPrint('Загружаем аватар: ${_selectedImage!.path}');

      final response = await apiService.postMultipart(
        '/api/update-avatar',
        fields: {},
        fileField: 'avatar',
        file: _selectedImage!,
        requiresAuth: true,
        filename: 'avatar.jpg',
        contentType: 'image/jpeg',
      );

      debugPrint('Ответ сервера: $response');

      if (response != null) {
        // Проверяем, что это успешный ответ
        final message = response['message']?.toString() ?? '';
        final isSuccess = response['success'] == true ||
            message.toLowerCase().contains('successfully') ||
            message.toLowerCase().contains('успешно') ||
            response['avatar_url'] != null ||
            response['url'] != null ||
            response['avatar'] != null;

        if (isSuccess) {
          print('SETTINGS: Avatar upload successful');
          // Обновляем URL аватара - сначала ищем в user объекте, затем на верхнем уровне
          String? newAvatarUrl;

          if (response['user'] != null && response['user']['avatar'] != null) {
            newAvatarUrl = response['user']['avatar'];
            print('SETTINGS: Found avatar in user object: $newAvatarUrl');
          } else {
            newAvatarUrl =
                response['avatar_url'] ?? response['url'] ?? response['avatar'];
            print('SETTINGS: Found avatar at top level: $newAvatarUrl');
          }

          print('SETTINGS: newAvatarUrl from response: $newAvatarUrl');

          // Если URL относительный, добавляем базовый URL
          if (newAvatarUrl != null &&
              newAvatarUrl.isNotEmpty &&
              !newAvatarUrl.startsWith('http')) {
            newAvatarUrl = newAvatarUrl.startsWith('/')
                ? 'https://videopokaz.kz/storage/$newAvatarUrl'
                : 'https://videopokaz.kz/storage/$newAvatarUrl';
            print('SETTINGS: newAvatarUrl after URL fix: $newAvatarUrl');
          }

          // Если URL не получен из ответа, попробуем перезагрузить данные пользователя
          if (newAvatarUrl == null || newAvatarUrl.isEmpty) {
            debugPrint(
                'URL аватара не получен, перезагружаем данные пользователя...');
            await _refreshUserDataFromServer();
          } else {
            // Дополнительная проверка валидности URL перед сохранением
            print('SETTINGS: Проверяем валидность URL: $newAvatarUrl');
            final uri = Uri.tryParse(newAvatarUrl);
            print('SETTINGS: URI parsed: $uri');
            print(
                'SETTINGS: hasScheme: ${uri?.hasScheme}, hasAuthority: ${uri?.hasAuthority}');

            if (uri != null && uri.hasScheme && uri.hasAuthority) {
              debugPrint('Новый URL аватара: $newAvatarUrl');
              print('SETTINGS: URL валидный, начинаем обновление...');

              setState(() {
                _currentAvatarUrl = newAvatarUrl;
                _selectedImage = null; // Очищаем только после успешной загрузки
              });

              // Обновляем данные пользователя в локальном хранилище
              print('SETTINGS: Обновляем локальное хранилище...');
              final user = await AuthService.getUser();
              if (user != null) {
                user['avatar'] = newAvatarUrl;
                await AuthService.saveUser(user);
                print('SETTINGS: Локальное хранилище обновлено');
              }

              // Принудительно обновляем данные пользователя с сервера
              print('SETTINGS: Вызываем refreshUserFromApi...');
              await AuthService.refreshUserFromApi();
              print('SETTINGS: refreshUserFromApi завершен');

              // Также обновляем UI локально
              print('SETTINGS: Вызываем _loadUserData...');
              await _loadUserData();
              print('SETTINGS: _loadUserData завершен');
            } else {
              print('SETTINGS: URL невалидный: $newAvatarUrl');
              debugPrint('Получен невалидный URL аватара: $newAvatarUrl');
              await _refreshUserDataFromServer();
            }
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Аватар успешно обновлен'),
                backgroundColor: Color(0xff183B4E),
              ),
            );
          }
        } else {
          // Сервер вернул ошибку
          final errorMsg = response['message'] ?? 'Неизвестная ошибка сервера';
          throw Exception(errorMsg);
        }
      } else {
        throw Exception('Сервер не вернул ответ');
      }
    } catch (e) {
      debugPrint('Ошибка загрузки аватара: $e');

      if (mounted) {
        setState(() {
          _errorMessage = 'Ошибка загрузки аватара: ${e.toString()}';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки аватара: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
        });
      }
    }
  }

  Future<void> _saveUserData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      // Format phone number - remove all non-digit characters
      final phoneNumber = _phoneController.text.replaceAll(RegExp(r'\D'), '');

      // TODO: Implement update user API call
      // For now, we'll just save locally
      final updatedUser = {
        'name': _nameController.text,
        'email': _emailController.text,
        'phone_number': phoneNumber,
      };

      await AuthService.saveUser(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Данные успешно сохранены'),
            backgroundColor: Color(0xff183B4E),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка сохранения: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_outlined,
                color: Colors.red.shade700,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                "Удалить аккаунт",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Вы уверены, что хотите удалить свой аккаунт?",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 12),
              Text(
                "Это действие нельзя отменить. Все ваши данные, объявления и история будут безвозвратно удалены.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.4,
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
                "Отмена",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showFinalDeleteConfirmation();
              },
              child: Text(
                "Удалить",
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showFinalDeleteConfirmation() {
    final TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Подтвердите удаление",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.red.shade700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Для подтверждения введите ваш пароль:",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "Введите пароль",
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: Colors.grey.shade600,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.red.shade400),
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
                "Отмена",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                final password = passwordController.text.trim();
                if (password.isNotEmpty) {
                  Navigator.of(context).pop();
                  // Add small delay to ensure dialog is properly closed
                  Future.delayed(const Duration(milliseconds: 100), () {
                    if (mounted) {
                      _deleteAccount(password);
                    }
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Введите пароль для подтверждения'),
                      backgroundColor: Colors.red.shade700,
                    ),
                  );
                }
              },
              child: Text(
                "Подтвердить удаление",
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAccount(String password) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Call the actual delete account API with password
      final success = await AuthService.deleteAccount(password);

      if (!mounted) return;

      if (success) {
        // Account deleted successfully - ensure clean state and navigation
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const NavigationMenu(initialIndex: 0),
          ),
          (route) => false,
        );
        return; // Немедленно завершить выполнение метода после навигации
      } else {
        // Show error if deletion failed
        setState(() {
          _errorMessage =
              'Не удалось удалить аккаунт. Проверьте пароль и попробуйте еще раз.';
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  const Text('Неверный пароль или ошибка удаления аккаунта'),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Ошибка при удалении аккаунта: ${e.toString()}';
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при удалении аккаунта: ${e.toString()}'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(IconlyBroken.arrowLeft, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Настройки профиля",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile avatar section
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F5F5),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    width: 2,
                                  ),
                                ),
                                child: ClipOval(
                                  child: _selectedImage != null
                                      ? Image.file(
                                          _selectedImage!,
                                          fit: BoxFit.cover,
                                          width: 100,
                                          height: 100,
                                        )
                                      : _currentAvatarUrl != null &&
                                              _currentAvatarUrl!.isNotEmpty &&
                                              _currentAvatarUrl!
                                                  .startsWith('http') &&
                                              Uri.tryParse(
                                                      _currentAvatarUrl!) !=
                                                  null
                                          ? Image.network(
                                              _currentAvatarUrl!,
                                              fit: BoxFit.cover,
                                              width: 100,
                                              height: 100,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                debugPrint(
                                                    'Ошибка загрузки аватара: $error');
                                                return const Image(
                                                  image: AssetImage(
                                                      'assets/icons/no_avatar.png'),
                                                  fit: BoxFit.cover,
                                                );
                                              },
                                            )
                                          : const Image(
                                              image: AssetImage(
                                                  'assets/icons/no_avatar.png'),
                                              fit: BoxFit.cover,
                                            ),
                                ),
                              ),
                              if (_isUploadingAvatar)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.black.withValues(alpha: 0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_selectedImage != null && !_isUploadingAvatar)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedImage = null;
                                    });
                                  },
                                  child: const Text(
                                    "Отмена",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                ElevatedButton(
                                  onPressed: _uploadAvatar,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xff183B4E),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text("Сохранить"),
                                ),
                              ],
                            )
                          else
                            TextButton(
                              onPressed: _isUploadingAvatar
                                  ? null
                                  : _selectImageWithoutAutoUpload,
                              child: Text(
                                _isUploadingAvatar
                                    ? "Загрузка..."
                                    : "Изменить фото",
                                style: TextStyle(
                                  color: _isUploadingAvatar
                                      ? Colors.grey
                                      : const Color(0xff183B4E),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Form fields - minimalist style
                    const Text(
                      "Личная информация",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Name field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Имя",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: "Введите ваше имя",
                            filled: true,
                            fillColor: const Color(0xFFF8F9FA),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 16.0, horizontal: 16.0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: const BorderSide(
                                color: Color(0xff183B4E),
                                width: 2,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Пожалуйста, введите ваше имя';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Email field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Email",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            hintText: "Введите ваш email",
                            filled: true,
                            fillColor: const Color(0xFFF8F9FA),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 16.0, horizontal: 16.0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: const BorderSide(
                                color: Color(0xff183B4E),
                                width: 2,
                              ),
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Пожалуйста, введите ваш email';
                            }
                            if (!value.contains('@')) {
                              return 'Введите корректный email';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Phone field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Телефон",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            hintText: "+77__ ___ __ __",
                            filled: true,
                            fillColor: const Color(0xFFF8F9FA),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 16.0, horizontal: 16.0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: const BorderSide(
                                color: Color(0xff183B4E),
                                width: 2,
                              ),
                            ),
                          ),
                          keyboardType: TextInputType.phone,
                          inputFormatters: [phoneMaskFormatter],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Пожалуйста, введите ваш телефон';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // Security section - simplified
                    const Text(
                      "Безопасность",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Change password option - simplified
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChangePasswordPage(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 20, horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              IconlyBroken.lock,
                              color: Color(0xff183B4E),
                              size: 24,
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Изменить пароль",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "Обновите ваш пароль",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              IconlyBroken.arrowRight2,
                              size: 20,
                              color: Colors.black54,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Delete account option
                    InkWell(
                      onTap: () {
                        _showDeleteAccountDialog();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 20, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              IconlyBroken.delete,
                              color: Colors.red.shade700,
                              size: 24,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Удалить аккаунт",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Безвозвратно удалить ваш аккаунт",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.red.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              IconlyBroken.arrowRight2,
                              size: 20,
                              color: Colors.red.shade600,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Error message
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 48),

                    // Save button - simplified
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff183B4E),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isSaving ? null : _saveUserData,
                        child: _isSaving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "Сохранить изменения",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
