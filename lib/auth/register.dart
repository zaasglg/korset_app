import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/auth_service.dart';
import 'verify_code_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _referralController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  // Состояние многоэтапной регистрации
  int _currentStep = 1; // 1 - номер телефона, 2 - остальные данные
  String? _validatedPhoneNumber;

  var phoneMaskFormatter = MaskTextInputFormatter(
    mask: '+7 (###) ###-##-##',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  void _showErrorToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 3,
      backgroundColor: Colors.red.shade600,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  Future<void> _checkPhoneNumber() async {
    // Validate phone input
    if (_phoneController.text.isEmpty) {
      _showErrorToast('Пожалуйста, введите номер телефона');
      return;
    }

    // Format phone number - remove all non-digit characters and add +7
    String phoneNumber = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (phoneNumber.startsWith('7')) {
      phoneNumber = '+$phoneNumber';
    } else if (phoneNumber.startsWith('8')) {
      phoneNumber = '+7${phoneNumber.substring(1)}';
    } else {
      phoneNumber = '+7$phoneNumber';
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Проверяем, не зарегистрирован ли уже этот номер
      print('Проверяем номер телефона: $phoneNumber');
      await AuthService.checkPhoneNumber(phoneNumber);

      // Номер доступен - переходим ко второму шагу
      setState(() {
        _validatedPhoneNumber = phoneNumber;
        _currentStep = 2;
      });
    } catch (e) {
      // ВАЖНО: если есть ошибка (в том числе зарегистрированный номер),
      // НЕ переходим на второй шаг, остаемся на первом
      if (mounted) {
        String errorMessage = e.toString();

        // Убираем префикс "Exception: " если он есть
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(11);
        }

        // Проверяем на специфические ошибки и показываем toast
        if (errorMessage.contains('зарегистрирован') ||
            errorMessage.contains('registered')) {
          _showErrorToast(errorMessage);
        } else if (errorMessage.contains('network') ||
            errorMessage.contains('connection')) {
          _showErrorToast('Проблемы с подключением к интернету');
        } else if (errorMessage.contains('timeout')) {
          _showErrorToast('Превышено время ожидания. Попробуйте еще раз');
        } else {
          _showErrorToast('Произошла ошибка: $errorMessage');
        }

        // Убеждаемся, что остаемся на первом шаге
        setState(() {
          _currentStep = 1;
          _validatedPhoneNumber = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _register() async {
    // Validate inputs
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showErrorToast('Пожалуйста, заполните все поля');
      return;
    }

    if (_passwordController.text.length < 8) {
      _showErrorToast('Пароль должен содержать минимум 8 символов');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showErrorToast('Пароли не совпадают');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Первый этап регистрации - отправка данных
      await AuthService.registerStep1(
        name: _nameController.text,
        email: _emailController.text,
        phoneNumber: _validatedPhoneNumber!,
        password: _passwordController.text,
        passwordConfirmation: _confirmPasswordController.text,
        referralCode: _referralController.text.isNotEmpty
            ? _referralController.text
            : null,
      );

      if (mounted) {
        // Переходим на страницу подтверждения кода
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                VerifyCodePage(phoneNumber: _validatedPhoneNumber!),
          ),
        );

        // Если регистрация завершена успешно, возвращаемся с результатом
        if (mounted && result == true) {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();

        // Убираем префикс "Exception: " если он есть
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(11);
        }

        // Проверяем на специфические ошибки и показываем toast
        if (errorMessage.contains('network') ||
            errorMessage.contains('connection')) {
          _showErrorToast('Проблемы с подключением к интернету');
        } else if (errorMessage.contains('timeout')) {
          _showErrorToast('Превышено время ожидания. Попробуйте еще раз');
        } else {
          _showErrorToast('Произошла ошибка: $errorMessage');
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

  void _goBackToStep1() {
    setState(() {
      _currentStep = 1;
      _validatedPhoneNumber = null;
      // Дополнительно сбрасываем loading состояние
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Проверяем, открыта ли клавиатура
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset:
          true, // Автоматически изменяет размер при появлении клавиатуры
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(IconlyBroken.arrowLeft, color: Color(0xff183B4E)),
          onPressed: () {
            if (_currentStep == 2) {
              _goBackToStep1();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        centerTitle: true,
        title: Text(
          _currentStep == 1 ? "Регистрация" : "Завершите регистрацию",
          style: const TextStyle(
            fontFamily: "avenir",
            fontWeight: FontWeight.w500,
            fontSize: 18,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior
              .onDrag, // Скрывает клавиатуру при скролле
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                if (_currentStep == 1) ..._buildStep1(isKeyboardVisible),
                if (_currentStep == 2) ..._buildStep2(isKeyboardVisible),
                // Добавляем дополнительный отступ внизу, когда клавиатура открыта
                SizedBox(height: isKeyboardVisible ? 50 : 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildStep1(bool isKeyboardVisible) {
    return [
      // Скрываем заголовки когда клавиатура открыта для экономии места
      if (!isKeyboardVisible) ...[
        const Text(
          "Введите номер телефона",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Color(0xff183B4E),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Мы проверим, доступен ли этот номер для регистрации",
          style: TextStyle(
            fontSize: 14,
            color: Colors.black54,
            letterSpacing: 0.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
      ] else ...[
        // Показываем только краткий заголовок когда клавиатура открыта
        const SizedBox(height: 16),
      ],
      TextField(
        controller: _phoneController,
        decoration: InputDecoration(
          hintText: "+77__ ___ __ __",
          hintStyle: const TextStyle(
            fontFamily: "avenir",
            fontWeight: FontWeight.w500,
            color: Colors.black38,
          ),
          fillColor: Colors.grey[50],
          filled: true,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 18.0, horizontal: 20.0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Color(0xff183B4E), width: 1),
          ),
          prefixIcon:
              const Icon(IconlyBroken.call, color: Colors.black45, size: 20),
        ),
        keyboardType: TextInputType.phone,
        inputFormatters: [phoneMaskFormatter],
      ),
      // Показываем кнопки только если клавиатура закрыта
      if (!isKeyboardVisible) ...[
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff183B4E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            onPressed: _isLoading ? null : _checkPhoneNumber,
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    "Продолжить",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Уже есть аккаунт? ",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              Text(
                "Войти",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xff183B4E),
                ),
              ),
            ],
          ),
        ),
      ],
    ];
  }

  List<Widget> _buildStep2(bool isKeyboardVisible) {
    // Дополнительная защита: если нет валидированного номера, не показываем шаг 2
    if (_validatedPhoneNumber == null) {
      // Принудительно возвращаем на шаг 1
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _goBackToStep1();
      });
      return [];
    }

    return [
      // Информация о номере всегда видна
      Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Номер ${_validatedPhoneNumber} доступен",
              style: const TextStyle(
                fontSize: 14,
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      // Скрываем заголовки когда клавиатура открыта для экономии места
      if (!isKeyboardVisible) ...[
        const SizedBox(height: 24),
        const Text(
          "Заполните данные",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Color(0xff183B4E),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Осталось заполнить данные для завершения регистрации",
          style: TextStyle(
            fontSize: 14,
            color: Colors.black54,
            letterSpacing: 0.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
      ] else ...[
        const SizedBox(height: 16),
      ],
      TextField(
        controller: _nameController,
        decoration: InputDecoration(
          hintText: "Имя",
          hintStyle: const TextStyle(
            fontFamily: "avenir",
            fontWeight: FontWeight.w500,
            color: Colors.black38,
          ),
          fillColor: Colors.grey[50],
          filled: true,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 18.0, horizontal: 20.0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Color(0xff183B4E), width: 1),
          ),
          prefixIcon:
              const Icon(IconlyBroken.profile, color: Colors.black45, size: 20),
        ),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _emailController,
        decoration: InputDecoration(
          hintText: "Email",
          hintStyle: const TextStyle(
            fontFamily: "avenir",
            fontWeight: FontWeight.w500,
            color: Colors.black38,
          ),
          fillColor: Colors.grey[50],
          filled: true,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 18.0, horizontal: 20.0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Color(0xff183B4E), width: 1),
          ),
          prefixIcon:
              const Icon(IconlyBroken.message, color: Colors.black45, size: 20),
        ),
        keyboardType: TextInputType.emailAddress,
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        decoration: InputDecoration(
          hintText: "Пароль",
          hintStyle: const TextStyle(
            fontFamily: "avenir",
            fontWeight: FontWeight.w500,
            color: Colors.black38,
          ),
          fillColor: Colors.grey[50],
          filled: true,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 18.0, horizontal: 20.0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Color(0xff183B4E), width: 1),
          ),
          prefixIcon:
              const Icon(IconlyBroken.lock, color: Colors.black45, size: 20),
          suffixIcon: IconButton(
            icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
                size: 20),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
        ),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _confirmPasswordController,
        obscureText: _obscureConfirmPassword,
        decoration: InputDecoration(
          hintText: "Подтвердите пароль",
          hintStyle: const TextStyle(
            fontFamily: "avenir",
            fontWeight: FontWeight.w500,
            color: Colors.black38,
          ),
          fillColor: Colors.grey[50],
          filled: true,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 18.0, horizontal: 20.0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Color(0xff183B4E), width: 1),
          ),
          prefixIcon:
              const Icon(IconlyBroken.lock, color: Colors.black45, size: 20),
          suffixIcon: IconButton(
            icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: Colors.grey,
                size: 20),
            onPressed: () {
              setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              });
            },
          ),
        ),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _referralController,
        decoration: InputDecoration(
          hintText: "Реферальный код (необязательно)",
          hintStyle: const TextStyle(
            fontFamily: "avenir",
            fontWeight: FontWeight.w500,
            color: Colors.black38,
          ),
          fillColor: Colors.grey[50],
          filled: true,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 18.0, horizontal: 20.0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Color(0xff183B4E), width: 1),
          ),
          prefixIcon:
              const Icon(IconlyBroken.ticket, color: Colors.black45, size: 20),
        ),
      ),
      // Показываем кнопки и текст только если клавиатура закрыта
      if (!isKeyboardVisible) ...[
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff183B4E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            onPressed: _isLoading ? null : _register,
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    "Зарегистрироваться",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 40),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text.rich(
            TextSpan(
              text: "Регистрируясь, Вы принимаете ",
              style: TextStyle(
                fontFamily: "avenir",
                color: Colors.black45,
                fontSize: 13,
                height: 1.5,
              ),
              children: [
                TextSpan(
                  text: "пользовательское соглашение",
                  style: TextStyle(
                    color: Color(0xff183B4E),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextSpan(text: " и "),
                TextSpan(
                  text: "политику конфиденциальности",
                  style: TextStyle(
                    color: Color(0xff183B4E),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    ];
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _referralController.dispose();
    super.dispose();
  }
}
