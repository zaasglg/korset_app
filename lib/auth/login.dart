import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  Future<void> _showForgotPasswordBottomSheet() async {
    final TextEditingController phoneController = TextEditingController();
    var phoneMaskFormatter = MaskTextInputFormatter(
      mask: '+7 (###) ###-##-##',
      filter: {"#": RegExp(r'[0-9]')},
      type: MaskAutoCompletionType.lazy,
    );
    String? errorText;
    bool isLoading = false;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Сброс пароля',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [phoneMaskFormatter],
                    decoration: InputDecoration(
                      labelText: 'Телефон',
                      hintText: '+7 (___) ___-__-__',
                      errorText: errorText,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff183B4E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isLoading
                          ? null
                          : () async {
                              final phone = phoneController.text.replaceAll(RegExp(r'\D'), '');
                              if (phone.length != 11) {
                                setState(() => errorText = 'Введите корректный номер');
                                return;
                              }
                              setState(() {
                                isLoading = true;
                                errorText = null;
                              });
                              try {
                                print('Отправляем запрос на сброс пароля для номера: +$phone');
                                final resp = await AuthService.resetPassword('+$phone');
                                print('Ответ сервера: $resp');
                                
                                // Проверяем различные варианты успешного ответа
                                if (resp['success'] == true || resp['status'] == 'success' || resp != null) {
                                  if (mounted) {
                                    Navigator.of(context).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(resp['message'] ?? resp['data']?['message'] ?? 'Новый пароль отправлен на ваш номер телефона!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } else {
                                  setState(() => errorText = resp['error'] ?? resp['message'] ?? 'Ошибка сброса пароля');
                                }
                              } catch (e) {
                                print('Ошибка при сбросе пароля: $e');
                                setState(() => errorText = 'Ошибка: ${e.toString()}');
                              } finally {
                                setState(() => isLoading = false);
                              }
                            },
                      child: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Сбросить', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  var phoneMaskFormatter = MaskTextInputFormatter(
    mask: '+7 (###) ###-##-##',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  void _showErrorDialog(String title, String message) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10.0,
                  offset: Offset(0.0, 10.0),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    color: Colors.red.shade600,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff183B4E),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Проверяем состояние перед выполнением действий
                      if (mounted) {
                        // Очистить поле пароля для повторного ввода
                        _passwordController.clear();
                        // Фокус на поле пароля через небольшую задержку
                        Future.delayed(const Duration(milliseconds: 300), () {
                          if (mounted) {
                            _passwordFocusNode.requestFocus();
                          }
                        });
                      }
                    },
                    child: const Text(
                      "Повторить попытку",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Future<void> _login() async {
    // Reset error message
    setState(() {
      _errorMessage = null;
    });
    
    // Validate inputs
    if (_phoneController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Пожалуйста, заполните все поля';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Format phone number - remove all non-digit characters
      final phoneNumber = _phoneController.text.replaceAll(RegExp(r'\D'), '');
      
      // Use the AuthService.login method
      await AuthService.login(
        phoneNumber: phoneNumber,
        password: _passwordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Вход выполнен успешно')),
        );
        // Возвращаемся на предыдущую страницу с результатом об успешной авторизации
        Navigator.of(context).pop(true); // Передаем true как результат успешной авторизации
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString().toLowerCase();
        
        // Проверяем, является ли ошибка связанной с неправильным паролем/данными
        if (errorMessage.contains('password') || 
            errorMessage.contains('пароль') || 
            errorMessage.contains('unauthorized') ||
            errorMessage.contains('invalid credentials') ||
            errorMessage.contains('неверный') ||
            errorMessage.contains('401') ||
            errorMessage.contains('403') ||
            errorMessage.contains('неправильный') ||
            errorMessage.contains('authentication failed') ||
            errorMessage.contains('login failed')) {
          // Показываем красивую модальку для ошибки пароля только если контекст доступен
          if (mounted) {
            _showErrorDialog(
              "Неверный пароль",
              "Пароль, который вы ввели, не соответствует номеру телефона. Пожалуйста, проверьте правильность ввода и повторите попытку."
            );
          }
        } else {
          // Для других ошибок показываем обычное сообщение
          setState(() {
            _errorMessage = 'Ошибка входа. Проверьте подключение к интернету или попробуйте позже.';
          });
        }
      }
    } finally {
      if (mounted) {
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
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(IconlyBroken.arrowLeft, color: Color(0xff183B4E)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text(
          "Авторизация",
          style: TextStyle(
            fontFamily: "avenir",
            fontWeight: FontWeight.w500,
            color: Color(0xff183B4E),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 32),
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    hintText: "+77__ ___ __ __",
                    hintStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                    fillColor: Colors.grey[100],
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 20.0, horizontal: 18.0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [phoneMaskFormatter],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: "Пароль",
                    hintStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                    fillColor: Colors.grey[100],
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 20.0, horizontal: 18.0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.0),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey),
                      onPressed: () {
                        if (mounted) {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        }
                      },
                    ),
                  ),
                ),
                // Error message
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff183B4E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Продолжить",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 14),
                TextButton(
                  onPressed: _showForgotPasswordBottomSheet,
                  child: const Text(
                    "Забыли пароль?",
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: Color(0xff183B4E),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text.rich(
                    TextSpan(
                      text: "Авторизуясь на сайте, Вы принимаете условия ",
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                        height: 1.3,
                      ),
                      children: [
                        TextSpan(
                          text: "пользовательского соглашения",
                          style: TextStyle(
                            color: Color(0xff183B4E),
                            decoration: TextDecoration.underline,
                          ),
                          // Add recognizer if you want to handle tap
                        ),
                        TextSpan(text: " и "),
                        TextSpan(
                          text: "политики конфиденциальности",
                          style: TextStyle(
                            color: Color(0xff183B4E),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Dispose всех ресурсов
    _phoneController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }
}
