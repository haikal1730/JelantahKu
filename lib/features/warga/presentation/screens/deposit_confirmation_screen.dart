import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jelantah_ku/core/constants/app_theme.dart';
import 'package:jelantah_ku/core/utils/currency_formatter.dart';
import 'package:jelantah_ku/features/auth/presentation/providers/user_provider.dart';
import 'package:jelantah_ku/features/warga/presentation/providers/transaction_provider.dart';

class DepositConfirmationScreen extends ConsumerStatefulWidget {
  const DepositConfirmationScreen({super.key});

  @override
  ConsumerState<DepositConfirmationScreen> createState() =>
      _DepositConfirmationScreenState();
}

class _DepositConfirmationScreenState
    extends ConsumerState<DepositConfirmationScreen> {
  // Mock tube sensor reading
  final String _tubeId = 'TAB-001';
  double _weightKg = 5.0;
  final double _pricePerKg = 5000.0;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userNotifierProvider);
    final calculator = ref.watch(calculateDepositValueProvider);

    // Business logic calculation via Domain UseCase
    final totalValue = calculator.execute(
      weightKg: _weightKg,
      pricePerKg: _pricePerKg,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Konfirmasi Setoran'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tube Sensor Header Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryGreenLight.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.sensors_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tabung Komunal Terhubung',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppTheme.primaryGreenDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ID Sensor: $_tubeId • Status: Aktif',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Rincian Hasil Timbangan Sensor',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Weight Adjustment Card (interactive mock sensor reading)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Berat Minyak Jelantah',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.formatKg(_weightKg),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Slider to simulate sensor weight adjustments
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppTheme.primaryGreen,
                        inactiveTrackColor: AppTheme.primaryGreenLight.withOpacity(0.2),
                        thumbColor: AppTheme.primaryGreen,
                      ),
                      child: Slider(
                        value: _weightKg,
                        min: 0.5,
                        max: 20.0,
                        divisions: 39,
                        label: '${_weightKg.toStringAsFixed(1)} kg',
                        onChanged: (val) {
                          setState(() {
                            _weightKg = val;
                          });
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Min: 0.5 kg', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                        Text('Simulasi Sensor Berat', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                        Text('Max: 20.0 kg', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Conversion Breakdown Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildRow(
                      'Harga Per Kilogram',
                      '${CurrencyFormatter.format(_pricePerKg)}/kg',
                    ),
                    const Divider(height: 24),
                    _buildRow(
                      'Perhitungan Domain UseCase',
                      '${_weightKg.toStringAsFixed(1)} kg × ${CurrencyFormatter.format(_pricePerKg)}',
                      valueStyle: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Saldo Diterima',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(totalValue),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        setState(() {
                          _isSubmitting = true;
                        });

                        final success = await ref
                            .read(transactionNotifierProvider.notifier)
                            .createDeposit(
                              userId: user.id,
                              tubeId: _tubeId,
                              weightKg: _weightKg,
                              pricePerKg: _pricePerKg,
                            );

                        if (!mounted) return;
                        final messenger = ScaffoldMessenger.of(context);
                        final nav = Navigator.of(context);

                        setState(() {
                          _isSubmitting = false;
                        });

                        if (success) {
                          messenger.showSnackBar(
                            SnackBar(
                              backgroundColor: AppTheme.successGreen,
                              content: Text(
                                'Setoran ${CurrencyFormatter.formatKg(_weightKg)} berhasil disimpan! Saldo bertambah ${CurrencyFormatter.format(totalValue)}.',
                              ),
                            ),
                          );
                          nav.pop();
                        } else {
                          messenger.showSnackBar(
                            const SnackBar(
                              backgroundColor: AppTheme.errorRed,
                              content: Text('Gagal menyimpan setoran. Silakan coba lagi.'),
                            ),
                          );
                        }
                      },
                child: _isSubmitting
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
                          Icon(Icons.check_circle_outline_rounded),
                          SizedBox(width: 8),
                          Text('Konfirmasi & Simpan Setoran'),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {TextStyle? valueStyle}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: valueStyle ??
              const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
