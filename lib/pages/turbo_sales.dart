import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:korset_app/models/tariff.dart';
import 'package:korset_app/models/user_tariff.dart';
import 'package:korset_app/services/tariff_service.dart';
import 'package:korset_app/services/auth_service.dart';

class TurboSalesPage extends StatefulWidget {
  const TurboSalesPage({super.key});

  @override
  State<TurboSalesPage> createState() => _TurboSalesPageState();
}

class _TurboSalesPageState extends State<TurboSalesPage> {
  int? selectedPlanId;
  List<Tariff> tariffs = [];
  List<UserTariff> activeTariffs = [];
  bool isLoading = true;
  bool isLoadingActiveTariffs = false;
  String? errorMessage;
  bool? isAuthenticated;

  @override
  void initState() {
    super.initState();
    _loadTariffs();
    _checkAuthAndLoadActiveTariffs();
  }

  Future<void> _checkAuthAndLoadActiveTariffs() async {
    try {
      final authStatus = await AuthService.checkAuthenticationStatus();
      if (mounted) {
        setState(() {
          isAuthenticated = authStatus;
        });

        if (authStatus) {
          await _loadActiveTariffs();
        }
      }
    } catch (e) {
      // Игнорируем ошибки авторизации
      if (mounted) {
        setState(() {
          isAuthenticated = false;
        });
      }
    }
  }

  Future<void> _loadActiveTariffs() async {
    if (isAuthenticated != true) return;

    try {
      setState(() {
        isLoadingActiveTariffs = true;
      });

      final response = await TariffService.getMyTariffs();

      if (mounted) {
        setState(() {
          isLoadingActiveTariffs = false;
          if (response != null && response.success) {
            activeTariffs = response.data
                .where((userTariff) =>
                    userTariff.isActive && !userTariff.isExpired)
                .toList();
          } else {
            activeTariffs = [];
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingActiveTariffs = false;
          activeTariffs = [];
        });
      }
    }
  }

  Future<void> _loadTariffs() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final loadedTariffs = await TariffService.getTariffs();

      if (mounted) {
        setState(() {
          tariffs = loadedTariffs;
          isLoading = false;
          // Выбираем первый тариф по умолчанию
          if (tariffs.isNotEmpty) {
            selectedPlanId = tariffs.first.id;
          }
        });

        // Перезагружаем активные тарифы
        if (isAuthenticated == true) {
          await _loadActiveTariffs();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = e.toString();
        });
      }
    }
  }

  Tariff? _getSelectedTariff() {
    if (selectedPlanId == null) return null;
    try {
      return tariffs.firstWhere((tariff) => tariff.id == selectedPlanId);
    } catch (e) {
      return null;
    }
  }

  Color _getTariffColor(int index) {
    final colors = [
      const Color(0xFFD16DD2),
      const Color(0xFFB83DBA),
      const Color(0xFF9B59B6),
      const Color(0xFF8E44AD),
      const Color(0xFF6C3483),
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(IconlyBroken.arrowLeft, color: Color(0xff183B4E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Турбо продажа',
          style: TextStyle(
            color: Color(0xff183B4E),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xff183B4E)),
            onPressed: _loadTariffs,
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFFD16DD2),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Загружаем тарифы...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xff183B4E),
                    ),
                  ),
                ],
              ),
            )
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Ошибка загрузки тарифов',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.red[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadTariffs,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD16DD2),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                )
              : tariffs.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Тарифы не найдены',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xff183B4E),
                            ),
                          ),
                          Text(
                            'В данный момент нет доступных тарифов',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Active Tariffs Section
                          if (isAuthenticated == true &&
                              activeTariffs.isNotEmpty) ...[
                            Row(
                              children: [
                                const Text(
                                  'Ваши активные тарифы',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xff183B4E),
                                  ),
                                ),
                                const Spacer(),
                                if (isLoadingActiveTariffs)
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ...activeTariffs
                                .map((userTariff) =>
                                    _buildActiveTariffCard(userTariff))
                                .toList(),
                            const SizedBox(height: 30),
                          ],

                          // Plans Section
                          const Text(
                            'Выберите тариф',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Color(0xff183B4E),
                            ),
                          ),
                          const SizedBox(height: 16),

                          Column(
                            children: tariffs
                                .map((tariff) => _buildPlanCard(tariff))
                                .toList(),
                          ),

                          const SizedBox(height: 30),

                          // How it works
                          const Text(
                            'Как работает Турбо',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Color(0xff183B4E),
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildHowItWorksItem(
                            icon: Icons.trending_up,
                            title: 'Поднятие в топ',
                            description:
                                'Ваше объявление автоматически поднимается в начало списка несколько раз в день',
                          ),

                          _buildHowItWorksItem(
                            icon: IconlyBold.star,
                            title: 'Выделение',
                            description:
                                'Объявление выделяется специальным цветом и значком среди других',
                          ),

                          _buildHowItWorksItem(
                            icon: Icons.bar_chart,
                            title: 'Приоритет в поиске',
                            description:
                                'Ваше объявление показывается первым в результатах поиска',
                          ),

                          const SizedBox(height: 30),

                          // CTA Button
                          if (selectedPlanId != null && tariffs.isNotEmpty)
                            Container(
                              width: double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFD16DD2),
                                    Color(0xFFB83DBA)
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFD16DD2)
                                        .withValues(alpha: 0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => _showPaymentDialog(),
                                  child: Center(
                                    child: Text(
                                      'Активировать за ${_getSelectedTariff()?.effectivePrice.toStringAsFixed(2) ?? '0'} ₸',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildActiveTariffCard(UserTariff userTariff) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green.shade300,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'АКТИВЕН',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userTariff.tariff.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff183B4E),
                      ),
                    ),
                    if (userTariff.tariff.description.isNotEmpty)
                      Text(
                        userTariff.tariff.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${userTariff.paidAmount.toStringAsFixed(2)} ₸',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff183B4E),
                    ),
                  ),
                  Text(
                    'Оплачено',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Остается времени:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      userTariff.timeRemainingFormatted,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Истекает:',
                      style: TextStyle(fontSize: 12),
                    ),
                    Text(
                      _formatDateTime(userTariff.expiresAt.toIso8601String()),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (userTariff.tariff.featuresList.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Включено:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xff183B4E),
              ),
            ),
            const SizedBox(height: 8),
            ...userTariff.tariff.featuresList
                .take(3) // Показываем только первые 3 функции
                .map<Widget>((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              feature,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xff183B4E),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
            if (userTariff.tariff.featuresList.length > 3)
              Text(
                'и еще ${userTariff.tariff.featuresList.length - 3} функций...',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlanCard(Tariff tariff) {
    final isSelected = tariff.id == selectedPlanId;
    final index = tariffs.indexOf(tariff);
    final cardColor = _getTariffColor(index);

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPlanId = tariff.id;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? cardColor : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? cardColor.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: isSelected ? 15 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tariff.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color:
                              isSelected ? cardColor : const Color(0xff183B4E),
                        ),
                      ),
                      if (tariff.description.isNotEmpty)
                        Text(
                          tariff.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (tariff.hasDiscount)
                      Text(
                        '${tariff.priceAsDouble.toStringAsFixed(2)} ₸',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    Text(
                      '${tariff.effectivePrice.toStringAsFixed(2)} ₸',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? cardColor : const Color(0xff183B4E),
                      ),
                    ),
                    if (isSelected)
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: cardColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            if (tariff.featuresList.isNotEmpty) ...[
              const SizedBox(height: 16),
              ...tariff.featuresList
                  .map<Widget>((feature) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check,
                              size: 16,
                              color: isSelected ? cardColor : Colors.grey[400],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                feature,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xff183B4E),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHowItWorksItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFD16DD2).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFFD16DD2),
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
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff183B4E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog() {
    final selectedTariff = _getSelectedTariff();
    if (selectedTariff == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите тариф'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Подтверждение покупки',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xff183B4E),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Тариф: ${selectedTariff.name}'),
            if (selectedTariff.description.isNotEmpty)
              Text('Описание: ${selectedTariff.description}'),
            if (selectedTariff.hasDiscount) ...[
              Text(
                'Обычная цена: ${selectedTariff.priceAsDouble.toStringAsFixed(2)} ₸',
                style: const TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey,
                ),
              ),
              Text(
                'Цена со скидкой: ${selectedTariff.effectivePrice.toStringAsFixed(2)} ₸',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ] else
              Text(
                  'Стоимость: ${selectedTariff.effectivePrice.toStringAsFixed(2)} ₸'),
            const SizedBox(height: 16),
            const Text(
              'После активации ваше объявление получит максимальную видимость.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processTariffPurchase(selectedTariff);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD16DD2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Активировать',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processTariffPurchase(Tariff tariff) async {
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
                Text('Покупка тарифа...'),
              ],
            ),
          );
        },
      );

      // Вызываем API для покупки тарифа
      final response = await TariffService.purchaseTariff(tariff.id);

      // Закрываем диалог загрузки
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Обрабатываем ответ
      if (response['success'] == true) {
        // Успешная покупка - обновляем активные тарифы
        if (isAuthenticated == true) {
          await _loadActiveTariffs();
        }
        await _showSuccessDialog(tariff, response['data']);
      } else {
        // Обрабатываем различные типы ошибок
        await _handlePurchaseError(tariff, response);
      }
    } catch (e) {
      // Закрываем диалог загрузки, если он открыт
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Показываем общую ошибку
      if (mounted) {
        await _showGenericErrorDialog(e.toString());
      }
    }
  }

  Future<void> _showSuccessDialog(
      Tariff tariff, Map<String, dynamic>? data) async {
    if (!mounted) return;

    final newBalance = data?['new_balance'];
    final expiresAt = data?['expires_at'];

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 28,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Тариф активирован!',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Тариф "${tariff.name}" успешно приобретен!',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              if (newBalance != null)
                Text(
                  'Новый баланс: $newBalance ₸',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              if (expiresAt != null) ...[
                const SizedBox(height: 4),
                Text('Действует до: ${_formatDateTime(expiresAt)}'),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.trending_up,
                      color: Colors.green,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ваше объявление получит максимальную видимость!',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context)
                    .pop(); // Возвращаемся на предыдущую страницу
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Отлично!'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handlePurchaseError(
      Tariff tariff, Map<String, dynamic> response) async {
    if (!mounted) return;

    final message = response['message'] ?? 'Неизвестная ошибка';

    if (message.contains('Недостаточно средств')) {
      await _showInsufficientFundsDialog(tariff, response);
    } else if (message.contains('активный тариф')) {
      await _showActiveTariffDialog();
    } else {
      await _showGenericErrorDialog(message);
    }
  }

  Future<void> _showInsufficientFundsDialog(
      Tariff tariff, Map<String, dynamic> response) async {
    if (!mounted) return;

    final requiredAmount = response['required_amount'];
    final currentBalance = response['current_balance'];
    final missingAmount = requiredAmount != null && currentBalance != null
        ? (double.tryParse(requiredAmount.toString()) ?? 0) -
            (currentBalance is int
                ? currentBalance.toDouble()
                : (double.tryParse(currentBalance.toString()) ?? 0))
        : null;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(
                Icons.account_balance_wallet,
                color: Colors.red,
                size: 28,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Недостаточно средств',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Для покупки тарифа "${tariff.name}" необходимо:',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    if (requiredAmount != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Требуемая сумма:'),
                          Text(
                            '$requiredAmount ₸',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    if (currentBalance != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Ваш баланс:'),
                          Text(
                            '$currentBalance ₸',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                    if (missingAmount != null && missingAmount > 0) ...[
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Нужно доплатить:',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${missingAmount.toStringAsFixed(2)} ₸',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Пополните баланс и попробуйте снова.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context)
                    .pop(); // Возвращаемся к профилю для пополнения
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff183B4E),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Пополнить баланс'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showActiveTariffDialog() async {
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(
                Icons.info,
                color: Colors.orange,
                size: 28,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Тариф уже активен',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      color: Colors.orange,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'У вас уже есть активный тариф этого типа. Дождитесь окончания текущего тарифа или выберите другой.',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Понятно'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showGenericErrorDialog(String message) async {
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(
                Icons.error,
                color: Colors.red,
                size: 28,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Ошибка',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(message),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Понятно'),
            ),
          ],
        );
      },
    );
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeString;
    }
  }
}
