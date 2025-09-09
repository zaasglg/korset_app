import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../services/auth_service.dart';
import 'verify_code_page.dart';

class MultiStepRegisterPage extends StatefulWidget {
  const MultiStepRegisterPage({super.key});

  @override
  State<MultiStepRegisterPage> createState() => _MultiStepRegisterPageState();
}

class _MultiStepRegisterPageState extends State<MultiStepRegisterPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;
  bool _isCheckingPhone = false; // Отдельное состояние для проверки телефона
  String? _errorMessage;

  // Controllers for all steps
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _referralController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  var phoneMaskFormatter = MaskTextInputFormatter(
    mask: '+7 (###) ###-##-##',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  final List<String> _stepTitles = [
    "Номер телефона",
    "Личная информация",
    "Создание пароля",
    "Подтверждение"
  ];

  final List<String> _stepSubtitles = [
    "Введите ваш номер телефона",
    "Расскажите немного о себе",
    "Придумайте надежный пароль",
    "Осталось совсем немного"
  ];

  void _nextStep() async {
    if (_validateCurrentStep()) {
      if (_currentStep == 0) {
        // Проверяем номер телефона на первом шаге
        await _checkPhoneNumber();
      } else if (_currentStep < 2) {
        setState(() {
          _currentStep++;
          _errorMessage = null;
        });
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _submitRegistration();
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _errorMessage = null;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateCurrentStep() {
    setState(() {
      _errorMessage = null;
    });

    switch (_currentStep) {
      case 0: // Phone validation
        if (_phoneController.text.isEmpty) {
          setState(() {
            _errorMessage = 'Введите номер телефона';
          });
          return false;
        }

        String phoneDigits =
            _phoneController.text.replaceAll(RegExp(r'\D'), '');
        if (phoneDigits.length < 11) {
          setState(() {
            _errorMessage = 'Введите корректный номер телефона';
          });
          return false;
        }

        // Дополнительная проверка для казахстанских номеров
        if (!phoneDigits.startsWith('7') && !phoneDigits.startsWith('8')) {
          setState(() {
            _errorMessage = 'Номер должен начинаться с +7 или 8';
          });
          return false;
        }

        // Проверка на корректность казахстанского номера
        if (phoneDigits.startsWith('7') && phoneDigits.length == 11) {
          String operatorCode = phoneDigits.substring(1, 4);
          List<String> validCodes = [
            '701',
            '702',
            '705',
            '707',
            '708',
            '747',
            '771',
            '775',
            '776',
            '777',
            '778'
          ];
          if (!validCodes.contains(operatorCode)) {
            setState(() {
              _errorMessage = 'Введите действующий казахстанский номер';
            });
            return false;
          }
        }
        break;

      case 1: // Personal info validation
        if (_nameController.text.isEmpty) {
          setState(() {
            _errorMessage = 'Введите ваше имя';
          });
          return false;
        }
        if (_emailController.text.isEmpty) {
          setState(() {
            _errorMessage = 'Введите email адрес';
          });
          return false;
        }
        if (!_emailController.text.contains('@')) {
          setState(() {
            _errorMessage = 'Введите корректный email адрес';
          });
          return false;
        }
        break;

      case 2: // Password validation
        if (_passwordController.text.isEmpty) {
          setState(() {
            _errorMessage = 'Введите пароль';
          });
          return false;
        }
        if (_passwordController.text.length < 8) {
          setState(() {
            _errorMessage = 'Пароль должен содержать минимум 8 символов';
          });
          return false;
        }
        if (_confirmPasswordController.text.isEmpty) {
          setState(() {
            _errorMessage = 'Подтвердите пароль';
          });
          return false;
        }
        if (_passwordController.text != _confirmPasswordController.text) {
          setState(() {
            _errorMessage = 'Пароли не совпадают';
          });
          return false;
        }
        break;
    }
    return true;
  }

  Future<void> _checkPhoneNumber() async {
    setState(() {
      _isCheckingPhone = true;
      _errorMessage = null;
    });

    try {
      // Format phone number for API call
      String phoneNumber = _phoneController.text.replaceAll(RegExp(r'\D'), '');
      if (phoneNumber.startsWith('7')) {
        phoneNumber = '+$phoneNumber';
      } else if (phoneNumber.startsWith('8')) {
        phoneNumber = '+7${phoneNumber.substring(1)}';
      } else {
        phoneNumber = '+7$phoneNumber';
      }

      // Check if phone number is available
      bool isAvailable = await AuthService.checkPhoneNumber(phoneNumber);

      if (isAvailable && mounted) {
        // Phone number is available, proceed to next step
        setState(() {
          _currentStep++;
          _errorMessage = null;
        });
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Handle phone number check error
          String errorMessage = 'Ошибка при проверке номера телефона';

          // Extract the actual error message
          String errorString = e.toString();

          if (errorString.contains('ApiException: [')) {
            // Extract message from ApiException format: "ApiException: [statusCode] message"
            int bracketIndex = errorString.indexOf('] ');
            if (bracketIndex != -1) {
              errorMessage = errorString.substring(bracketIndex + 2);
            }
          } else if (errorString.contains('Exception: ')) {
            // Extract message from regular Exception
            int index = errorString.indexOf('Exception: ');
            if (index != -1) {
              errorMessage =
                  errorString.substring(index + 'Exception: '.length);
            }
          } else if (errorString.contains('уже зарегистрирован') ||
              errorString.contains('already registered')) {
            errorMessage = 'Этот номер телефона уже зарегистрирован в системе';
          }

          _errorMessage = errorMessage;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingPhone = false;
        });
      }
    }
  }

  Future<void> _submitRegistration() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Format phone number
      String phoneNumber = _phoneController.text.replaceAll(RegExp(r'\D'), '');
      if (phoneNumber.startsWith('7')) {
        phoneNumber = '+$phoneNumber';
      } else if (phoneNumber.startsWith('8')) {
        phoneNumber = '+7${phoneNumber.substring(1)}';
      } else {
        phoneNumber = '+7$phoneNumber';
      }

      // Submit registration
      await AuthService.registerStep1(
        name: _nameController.text,
        email: _emailController.text,
        phoneNumber: phoneNumber,
        password: _passwordController.text,
        passwordConfirmation: _confirmPasswordController.text,
        referralCode: _referralController.text.isNotEmpty
            ? _referralController.text
            : null,
      );

      if (mounted) {
        // Navigate to verification page
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VerifyCodePage(phoneNumber: phoneNumber),
          ),
        );

        if (mounted && result == true) {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Улучшенная обработка ошибок
          if (e.toString().contains('ApiException')) {
            // Извлекаем сообщение из ApiException
            String errorMsg = e.toString();
            if (errorMsg.contains('] ')) {
              _errorMessage = errorMsg.split('] ').last;
            } else {
              _errorMessage =
                  'Произошла ошибка при регистрации. Попробуйте еще раз.';
            }
          } else {
            _errorMessage =
                'Произошла ошибка при регистрации. Проверьте подключение к интернету.';
          }
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

  @override
  Widget build(BuildContext context) {
    // Check if keyboard is open
    bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(IconlyBroken.arrowLeft, color: Color(0xff183B4E)),
            onPressed: () {
              if (_currentStep > 0) {
                _previousStep();
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
          centerTitle: true,
          title: const Text(
            "Регистрация",
            style: TextStyle(
              fontFamily: "avenir",
              fontWeight: FontWeight.w500,
              fontSize: 18,
              letterSpacing: 0.5,
            ),
          ),
        ),
        body: SafeArea(
          child: GestureDetector(
            onTap: () {
              // Закрыть клавиатуру при нажатии на любое место
              FocusScope.of(context).unfocus();
            },
            child: Column(
              children: [
                // Progress indicator
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    children: [
                      Row(
                        children: List.generate(3, (index) {
                          return Expanded(
                            child: Container(
                              margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                              height: 4,
                              decoration: BoxDecoration(
                                color: index <= _currentStep
                                    ? const Color(0xff183B4E)
                                    : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Шаг ${_currentStep + 1} из 3",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildPhoneStep(),
                      _buildPersonalInfoStep(),
                      _buildPasswordStep(),
                    ],
                  ),
                ),

                // Bottom section with error and button - hidden when keyboard is open
                if (!isKeyboardOpen)
                  Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Error message
                        if (_errorMessage != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.red.shade400,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Continue button
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
                            onPressed: (_isLoading || _isCheckingPhone)
                                ? null
                                : _nextStep,
                            child: (_isLoading ||
                                    (_isCheckingPhone && _currentStep == 0))
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _currentStep == 0
                                        ? "Проверить номер"
                                        : _currentStep < 2
                                            ? "Продолжить"
                                            : "Завершить регистрацию",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                          ),
                        ),

                        // Back to login
                        if (_currentStep == 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: TextButton(
                              onPressed: () => Navigator.of(context).pop(),
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
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ));
  }

  Widget _buildPhoneStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text(
            _stepTitles[0],
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Color(0xff183B4E),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _stepSubtitles[0],
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 48),
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
                  const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.0),
                borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.0),
                borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.0),
                borderSide:
                    const BorderSide(color: Color(0xff183B4E), width: 2),
              ),
              prefixIcon: const Icon(IconlyBroken.call,
                  color: Colors.black45, size: 22),
            ),
            keyboardType: TextInputType.phone,
            inputFormatters: [phoneMaskFormatter],
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          const Text(
            "Мы проверим доступность номера для регистрации",
            style: TextStyle(
              fontSize: 13,
              color: Colors.black54,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text(
            _stepTitles[1],
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Color(0xff183B4E),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _stepSubtitles[1],
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 48),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: "Ваше имя",
              hintStyle: const TextStyle(
                fontFamily: "avenir",
                fontWeight: FontWeight.w500,
                color: Colors.black38,
              ),
              fillColor: Colors.grey[50],
              filled: true,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.0),
                borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.0),
                borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.0),
                borderSide:
                    const BorderSide(color: Color(0xff183B4E), width: 2),
              ),
              prefixIcon: const Icon(IconlyBroken.profile,
                  color: Colors.black45, size: 22),
            ),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              hintText: "Email адрес",
              hintStyle: const TextStyle(
                fontFamily: "avenir",
                fontWeight: FontWeight.w500,
                color: Colors.black38,
              ),
              fillColor: Colors.grey[50],
              filled: true,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.0),
                borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.0),
                borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.0),
                borderSide:
                    const BorderSide(color: Color(0xff183B4E), width: 2),
              ),
              prefixIcon: const Icon(IconlyBroken.message,
                  color: Colors.black45, size: 22),
            ),
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text(
            _stepTitles[2],
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Color(0xff183B4E),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _stepSubtitles[2],
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 48),
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
                  const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.0),
                borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.0),
                borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.0),
                borderSide:
                    const BorderSide(color: Color(0xff183B4E), width: 2),
              ),
              prefixIcon: const Icon(IconlyBroken.lock,
                  color: Colors.black45, size: 22),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                  size: 22,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),
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
                  const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.0),
                borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.0),
                borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.0),
                borderSide:
                    const BorderSide(color: Color(0xff183B4E), width: 2),
              ),
              prefixIcon: const Icon(IconlyBroken.lock,
                  color: Colors.black45, size: 22),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: Colors.grey,
                  size: 22,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
            ),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),
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
                  const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.0),
                borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.0),
                borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.0),
                borderSide:
                    const BorderSide(color: Color(0xff183B4E), width: 2),
              ),
              prefixIcon: const Icon(IconlyBroken.ticket,
                  color: Colors.black45, size: 22),
            ),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _phoneController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _referralController.dispose();
    super.dispose();
  }
}
