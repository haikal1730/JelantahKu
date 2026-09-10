import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jelantah_ku/core/constants/app_theme.dart';
import 'package:jelantah_ku/features/auth/presentation/providers/user_provider.dart';

class _Tube {
  _Tube({
    required this.id,
    required this.location,
    required this.capacityLiters,
    required this.fillRatio,
  });

  final String id;
  final String location;
  final int capacityLiters;
  double fillRatio;
  String pickupStatus = 'Belum diminta';
  DateTime? scheduledAt;
  DateTime? completedAt;

  int get liters => (capacityLiters * fillRatio).round();

  String get sensorStatus {
    if (fillRatio >= 0.90) return 'Kritis (Perlu Pengambilan)';
    if (fillRatio >= 0.80) return 'Hampir Penuh';
    return 'Normal';
  }
}

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  late final List<_Tube> _tubes = [
    _Tube(id: 'TAB-001', location: 'RT 01 / RW 02', capacityLiters: 100, fillRatio: 0.85),
    _Tube(id: 'TAB-002', location: 'Balai Desa', capacityLiters: 150, fillRatio: 0.45),
    _Tube(id: 'TAB-003', location: 'Pos Yandu RW 03', capacityLiters: 100, fillRatio: 0.20),
    _Tube(id: 'TAB-004', location: 'Pasar Desa', capacityLiters: 200, fillRatio: 0.92),
  ];

  int get _pendingCount => _tubes.where((t) => t.pickupStatus != 'Belum diminta' && t.pickupStatus != 'Selesai').length;

  int get _criticalCount => _tubes.where((t) => t.fillRatio >= 0.80 && t.pickupStatus != 'Selesai').length;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin Desa'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreenDark,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.admin_panel_settings, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          'Administrator ${user.village}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: _summaryCard('Perlu Diambil', '$_criticalCount', Icons.warning_amber_rounded, Colors.red)),
                const SizedBox(width: 12),
                Expanded(child: _summaryCard('Sedang Diproses', '$_pendingCount', Icons.local_shipping_outlined, AppTheme.primaryGreen)),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Status Sensor Tabung Komunal',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Jika tabung mencapai 80%, Admin Desa dapat membuat permintaan pengambilan.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _tubes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _buildTubeCard(_tubes[index]),
            ),
            const SizedBox(height: 24),
            _buildPickupInfoCard(),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  const SizedBox(height: 3),
                  Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTubeCard(_Tube tube) {
    final needsPickup = tube.fillRatio >= 0.80 && tube.pickupStatus != 'Selesai';
    final isCritical = tube.fillRatio >= 0.90;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: needsPickup ? () => _showPickupDialog(tube) : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${tube.id} — ${tube.location}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  _statusBadge(tube),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: tube.fillRatio,
                  minHeight: 10,
                  backgroundColor: Colors.grey.shade200,
                  color: isCritical ? AppTheme.errorRed : AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Kapasitas: ${tube.capacityLiters} L', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  Text('Terisi ${(tube.fillRatio * 100).toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              if (tube.pickupStatus != 'Belum diminta') ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_shipping_outlined, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Pengambilan: ${tube.pickupStatus}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ],
              if (needsPickup) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _showPickupDialog(tube),
                    icon: Icon(tube.pickupStatus == 'Belum diminta' ? Icons.local_shipping_outlined : Icons.arrow_forward),
                    label: Text(_actionLabel(tube)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _actionLabel(_Tube tube) {
    switch (tube.pickupStatus) {
      case 'Belum diminta':
        return 'Buat Pengambilan';
      case 'Menunggu Pengambilan':
        return 'Jadwalkan Pengambilan';
      case 'Dijadwalkan':
        return 'Konfirmasi Sudah Diambil';
      default:
        return 'Detail Pengambilan';
    }
  }

  Widget _statusBadge(_Tube tube) {
    final String text;
    final Color bg;
    final Color fg;
    if (tube.pickupStatus == 'Selesai') {
      text = 'Selesai';
      bg = Colors.green.shade100;
      fg = Colors.green.shade900;
    } else if (tube.pickupStatus != 'Belum diminta') {
      text = tube.pickupStatus;
      bg = Colors.orange.shade100;
      fg = Colors.orange.shade900;
    } else if (tube.fillRatio >= 0.90) {
      text = 'Kritis (Perlu Pengambilan)';
      bg = Colors.red.shade100;
      fg = Colors.red.shade900;
    } else if (tube.fillRatio >= 0.80) {
      text = 'Hampir Penuh';
      bg = Colors.orange.shade100;
      fg = Colors.orange.shade900;
    } else {
      text = 'Normal';
      bg = Colors.green.shade100;
      fg = Colors.green.shade900;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg)),
    );
  }

  Widget _buildPickupInfoCard() {
    return Card(
      color: AppTheme.primaryGreen.withOpacity(0.06),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, color: AppTheme.primaryGreen),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Alur: sensor mencapai 80% → Admin Desa membuat dan menjadwalkan pengambilan → petugas lapangan mengambil minyak → Admin Desa mengonfirmasi “Sudah Diambil”. Petugas lapangan tidak menjadi role login ke-4.',
                style: TextStyle(fontSize: 12, height: 1.45, color: Colors.grey.shade800),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPickupDialog(_Tube tube) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('${tube.id} — Pengambilan Minyak'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Lokasi: ${tube.location}'),
              Text('Kapasitas: ${tube.capacityLiters} L'),
              Text('Isi saat ini: ${tube.liters} L (${(tube.fillRatio * 100).toInt()}%)'),
              const SizedBox(height: 14),
              Text('Status: ${tube.pickupStatus}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text(
                'Petugas lapangan mengambil minyak secara fisik. Akun aplikasi tetap hanya memiliki 3 role: Warga, Admin Desa, dan Owner.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          actions: _dialogActions(dialogContext, tube),
        );
      },
    );
  }

  List<Widget> _dialogActions(BuildContext dialogContext, _Tube tube) {
    switch (tube.pickupStatus) {
      case 'Belum diminta':
        return [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              setState(() => tube.pickupStatus = 'Menunggu Pengambilan');
              Navigator.pop(dialogContext);
            },
            child: const Text('Buat Pengambilan'),
          ),
        ];
      case 'Menunggu Pengambilan':
        return [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Tutup')),
          FilledButton(
            onPressed: () {
              setState(() {
                tube.pickupStatus = 'Dijadwalkan';
                tube.scheduledAt = DateTime.now();
              });
              Navigator.pop(dialogContext);
            },
            child: const Text('Jadwalkan'),
          ),
        ];
      case 'Dijadwalkan':
        return [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Tutup')),
          FilledButton.icon(
            onPressed: () {
              setState(() {
                tube.pickupStatus = 'Selesai';
                tube.completedAt = DateTime.now();
                tube.fillRatio = 0;
              });
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${tube.id}: pengambilan selesai, kapasitas kembali 0%.')),
              );
            },
            icon: const Icon(Icons.check),
            label: const Text('Sudah Diambil'),
          ),
        ];
      default:
        return [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Tutup')),
        ];
    }
  }
}
