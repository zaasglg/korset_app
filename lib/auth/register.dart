import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../services/auth_service.dart';

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
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  var phoneMaskFormatter = MaskTextInputFormatter(
    mask: '+7 (###) ###-##-##',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  Future<void> _register() async {
    // Reset error message
    setState(() {
      _errorMessage = null;
    });
    
    // Validate inputs
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Пожалуйста, заполните все поля';
      });
      return;
    }

    if (_passwordController.text.length < 8) {
      setState(() {
        _errorMessage = 'Пароль должен содержать минимум 8 символов';
      });
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Пароли не совпадают';
      });
      return;
    }

    // Format phone number - remove all non-digit characters
    final phoneNumber = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Use the new AuthService.register method
      await AuthService.register(
        name: _nameController.text,
        email: _emailController.text,
        phoneNumber: phoneNumber,
        password: _passwordController.text,
        passwordConfirmation: _confirmPasswordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Регистрация успешна')),
        );
        Navigator.of(context).pop(); // Return to previous screen
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Ошибка: ${e.toString()}';
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
          "Регистрация",
          style: TextStyle(
            fontFamily: "avenir",
            fontWeight: FontWeight.w500,
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
                      fontFamily: "avenir",
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
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: "Email",
                    hintStyle: const TextStyle(
                      fontFamily: "avenir",
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
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey),
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
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: "Имя",
                    hintStyle: const TextStyle(
                      fontFamily: "avenir",
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
                    onPressed: _isLoading ? null : _register,
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
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xff183B4E).withOpacity(0.08),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      "Войти",
                      style: TextStyle(
                        fontFamily: "avenir",
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xff183B4E),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text.rich(
                    TextSpan(
                      text: "Регистрируясь на сайте, Вы принимаете условия ",
                      style: TextStyle(
                        fontFamily: "avenir",
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
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
