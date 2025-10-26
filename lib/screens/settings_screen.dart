// lib/screens/settings_screen.dart
// (FINAL) – Ayarlar + Minimal Tema Rengi seçici (ÖZEL SAATLER KALDIRILDI)

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../services/preference_service.dart';
import '../services/notification_service.dart';
import '../services/water_record_service.dart';
import 'package:su_icme_uygulamasi/screens/personal_info_screen.dart';
import 'personal_info_screen.dart';
import '../main.dart'; // ← Tema rengini anında uygulamak için

// =============================== AYARLAR EKRANI ==============================

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _currentGoal = 0;
  List<int> _customVolumes = [];
  int _startHour = 8;
  int _endHour = 22;
  int _intervalMinutes = 60;

  // Tema seçici görünürlüğü
  bool _showThemePicker = false;
  // Seçilebilir renkler
  final List<Map<String, String>> _colorOptions = const [
    {'name': 'Soft Mavi', 'hex': '0xFF64B5F6'},
    {'name': 'Mor', 'hex': '0xFF9C27B0'},
    {'name': 'Yeşil', 'hex': '0xFF4CAF50'},
    {'name': 'Turuncu', 'hex': '0xFFFF9800'},
    {'name': 'Koyu Mavi', 'hex': '0xFF1565C0'},
    {'name': 'Pembe', 'hex': '0xFFE91E63'},
    {'name': 'Su Yeşili', 'hex': '0xFF26A69A'},
  ];

  String _currentColorHex = preferenceService.getAppPrimaryColorHex();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _currentGoal = preferenceService.getDailyGoal();
      _customVolumes = preferenceService.getCustomVolumes();
      _startHour = preferenceService.getStartHour();
      _endHour = preferenceService.getEndHour();
      _intervalMinutes = preferenceService.getReminderInterval();
      _currentColorHex = preferenceService.getAppPrimaryColorHex();
    });
  }

  // --- Tema rengini uygula ---
  void _applyColor(String hex) {
    final modeStr = preferenceService.getThemeMode();
    final ThemeMode mode = ThemeMode.values.firstWhere(
          (e) => e.toString() == 'ThemeMode.$modeStr',
      orElse: () => ThemeMode.system,
    );

    // Kaydet + anında uygula
    WaterTrackerApp.of(context).setThemeAndColor(mode, hex);
    setState(() {
      _currentColorHex = hex;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tema rengi güncellendi.')),
    );
  }

  // --- Tema Rengi Kartı (Minimal) ---
  Widget _buildThemeColorCard() {
    final primary = Theme.of(context).colorScheme.primary;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.palette_outlined, color: primary),
            title: const Text('Tema Rengi'),
            subtitle: Text(
              _colorOptions.firstWhere(
                    (c) => c['hex'] == _currentColorHex,
                orElse: () => {'name': 'Özel', 'hex': ''},
              )['name']!,
            ),
            trailing: Icon(_showThemePicker ? Icons.expand_less : Icons.expand_more),
            onTap: () => setState(() => _showThemePicker = !_showThemePicker),
          ),
          if (_showThemePicker) const Divider(height: 1),
          if (_showThemePicker)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
              child: Column(
                children: _colorOptions.map((c) {
                  final hex = c['hex']!;
                  final name = c['name']!;
                  final color = Color(int.parse(hex));
                  final isActive = hex == _currentColorHex;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: color,
                      ),
                      title: Text(name),
                      trailing: isActive
                          ? Chip(
                        label: const Text('Seçili'),
                        backgroundColor: color.withOpacity(0.15),
                        side: BorderSide(color: color.withOpacity(0.5)),
                        labelStyle: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                          : OutlinedButton(
                        onPressed: () => _applyColor(hex),
                        child: const Text('Seç'),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  // --- Yardımcı: Kart iskeleti ---
  Widget _buildSettingsCard({required String title, required List<Widget> children}) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const Divider(height: 1),
            ...children,
          ],
        ),
      ),
    );
  }

  // --- Geçmiş tüketim ekleme diyaloğu ---
  Future<void> _showPastIntakeDialog() async {
    DateTime selectedDate = DateTime.now().subtract(const Duration(days: 1));
    final TextEditingController controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setInnerState) {
            final dateFormatter = '${selectedDate.day}.${selectedDate.month}.${selectedDate.year}';

            return AlertDialog(
              title: const Text('Geçmiş Tüketimi Ekle'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2023),
                        lastDate: DateTime.now().subtract(const Duration(days: 1)),
                      );
                      if (picked != null) {
                        setInnerState(() => selectedDate = picked);
                      }
                    },
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(dateFormatter),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Toplam Tüketilen Miktar (ml)",
                      hintText: "Örn: 2500",
                      suffixText: "ml",
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
                ElevatedButton(
                  onPressed: () async {
                    final amount = int.tryParse(controller.text);
                    if (amount != null && amount >= 0) {
                      await waterRecordService.updateWaterForDate(selectedDate, amount);

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$dateFormatter için ${amount} ml kaydedildi.')),
                        );
                        Navigator.pop(context);
                      }
                    }
                  },
                  child: const Text('Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- Hedef ayarı ---
  void _showGoalEditDialog() {
    final TextEditingController controller = TextEditingController(text: _currentGoal.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Günlük Hedefi Ayarla'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: "Örn: 3000 ml",
              suffixText: "ml",
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
            ElevatedButton(
              onPressed: () async {
                final newGoal = int.tryParse(controller.text);
                if (newGoal != null && newGoal > 500) {
                  await preferenceService.saveDailyGoal(newGoal);
                  _loadSettings();
                  Navigator.pop(context);
                }
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );
  }

  // --- Hızlı bardak hacmi ayarı ---
  void _showVolumeEditDialog(int index) {
    final TextEditingController controller = TextEditingController(text: _customVolumes[index].toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${index + 1}. Bardak Hacmini Düzenle'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: "Örn: 400 ml",
              suffixText: "ml",
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
            ElevatedButton(
              onPressed: () async {
                final newVolume = int.tryParse(controller.text);
                if (newVolume != null && newVolume >= 50 && newVolume <= 1000) {
                  _customVolumes[index] = newVolume;
                  await preferenceService.saveCustomVolumes(List<int>.from(_customVolumes));
                  _loadSettings();
                  Navigator.pop(context);
                }
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );
  }

  // --- Hatırlatıcı saat aralığı ve sıklığı ---
  void _rescheduleReminders() {
    final Duration interval = Duration(minutes: preferenceService.getReminderInterval());
    notificationService.scheduleWaterReminders(
      startHour: preferenceService.getStartHour(),
      endHour: preferenceService.getEndHour(),
      interval: interval,
    );
  }


  // SettingsScreen içinde: mevcut _showHoursEditDialog metodunu bununla değiştirin
// SettingsScreen içinde: mevcut _showHoursEditDialog metodunu bununla değiştirin
  Future<void> _showHoursEditDialog() async {
    int tempStart = _startHour;
    int tempEnd = _endHour > _startHour ? _endHour : (_startHour + 1).clamp(1, 23);
    int step = 0; // 0: Uyanma, 1: Yatış

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;

        return StatefulBuilder(
          builder: (context, setInnerState) {
            final String title = step == 0 ? 'Uyanma Saatini Seç' : 'Yatış Saatini Seç';
            final int initialHour = step == 0 ? tempStart : tempEnd;

            return Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Başlık + Kapat
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Kapat'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Tek picker (adım adım)
                    SizedBox(
                      height: 220,
                      child: CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.time,
                        use24hFormat: true,
                        // dakika seçimini istersen aç: minuteInterval: 5,
                        initialDateTime: DateTime(2024, 1, 1, initialHour, 0),
                        onDateTimeChanged: (dt) {
                          setInnerState(() {
                            if (step == 0) {
                              tempStart = dt.hour;
                              // yatışın en az 1 saat sonrası olmasını öner
                              if (tempEnd <= tempStart) {
                                tempEnd = (tempStart + 1).clamp(1, 23);
                              }
                            } else {
                              tempEnd = dt.hour;
                            }
                          });
                        },
                      ),
                    ),

                    // Alt butonlar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      child: Row(
                        children: [
                          if (step == 1)
                            OutlinedButton.icon(
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Geri'),
                              onPressed: () => setInnerState(() => step = 0),
                            ),
                          if (step == 1) const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              icon: Icon(step == 0 ? Icons.arrow_forward : Icons.save),
                              label: Text(step == 0 ? 'İleri' : 'Kaydet'),
                              onPressed: () async {
                                if (step == 0) {
                                  // Uyanma seçildi, şimdi yatışa geç
                                  setInnerState(() => step = 1);
                                  return;
                                }

                                // step == 1 => Kaydet
                                if (tempStart >= tempEnd) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Yatış saati, uyanma saatinden sonra olmalıdır.'),
                                    ),
                                  );
                                  return;
                                }

                                await preferenceService.saveReminderHours(tempStart, tempEnd);

                                if (mounted) {
                                  setState(() {
                                    _startHour = tempStart;
                                    _endHour = tempEnd;
                                  });
                                }

                                // Bildirimleri yeniden planla
                                _rescheduleReminders();

                                if (mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Saatler güncellendi: $_startHour:00 - $_endHour:00'),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }



  Future<void> _showIntervalEditDialog() async {
    final intervals = [
      {'value': 30, 'label': '30 Dakika (Yoğun Takip)'},
      {'value': 45, 'label': '45 Dakika'},
      {'value': 60, 'label': '1 Saat (Önerilen)'},
      {'value': 90, 'label': '1 Saat 30 Dakika'},
      {'value': 120, 'label': '2 Saat (Rahat Takip)'}
    ];

    int? selectedInterval = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hatırlatıcı Sıklığı Seçin'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: intervals.map((item) {
                final int interval = item['value'] as int;
                final String label = item['label'] as String;

                return ListTile(
                  title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
                  leading: Radio<int>(
                    value: interval,
                    groupValue: _intervalMinutes,
                    onChanged: (int? value) => Navigator.pop(context, value),
                  ),
                  onTap: () => Navigator.pop(context, interval),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kapat')),
          ],
        );
      },
    );

    if (selectedInterval != null) {
      await preferenceService.saveReminderInterval(selectedInterval);
      setState(() {
        _intervalMinutes = selectedInterval;
      });
      _rescheduleReminders();
    }
  }

  Future<void> _showClearDataDialog() async {
    final bool? shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verileri Sıfırla'),
        content: const Text('Bu işlem, tüm geçmiş su tüketim kayıtlarınızı (istatistikler dahil) kalıcı olarak siler. Devam etmek istiyor musunuz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () { Navigator.pop(context, true); },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Tümünü Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldClear == true) {
      await waterRecordService.clearAllRecords();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tüm tüketim geçmişi başarıyla silindi.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ayarlar ve Özelleştirme',
          style: TextStyle(
            color: Colors.white, // yazı beyaz
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
        elevation: 4,
        backgroundColor: Theme.of(context).colorScheme.primary, // 🔹 tema rengi
        shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.4),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          // 0) Tema Rengi (minimal & şık)
          _buildThemeColorCard(),

          // 1) Hatırlatma Programı (ÖZEL SAATLER KARTINI BURADAN KALDIRDIM)

          // EK: Kişisel Bilgiler Kartı (SettingsScreen build() içinde, listede uygun yere ekle)
          _buildSettingsCard(
            title: 'Kişisel Bilgiler',
            children: [
              ListTile(
                leading: Icon(Icons.person_outline, color: Theme.of(context).primaryColor),
                title: const Text('Kilo / Boy / Yaş / Cinsiyet'),
                subtitle: const Text('Bilgilerini düzenle ve hedefi yeniden hesapla'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () async {
                  final changed = await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PersonalInfoScreen()),
                  );
                  // geri dönünce hedef & özetleri tazele
                  if (changed == true && mounted) {
                    setState(() {
                      // senin _currentGoal değişkenin vs. yenilensin
                      _currentGoal = preferenceService.getDailyGoal();
                    });
                  }
                },
              ),
            ],
          ),


          // 2) Kişisel Hedef
          _buildSettingsCard(
            title: 'Kişisel Hedef Ayarları',
            children: [
              ListTile(
                leading: Icon(Icons.star_border, color: primary),
                title: const Text('Günlük Su Hedefi'),
                subtitle: Text('$_currentGoal ml'),
                trailing: const Icon(Icons.edit),
                onTap: _showGoalEditDialog,
              ),
            ],
          ),

          // 3) Hızlı Ekleme Bardakları
          _buildSettingsCard(
            title: 'Hızlı Ekleme Bardakları',
            children: _customVolumes.asMap().entries.map((entry) {
              final index = entry.key;
              final volume = entry.value;
              return ListTile(
                leading: Icon(Icons.local_drink, color: primary),
                title: Text('${index + 1}. Bardak Hacmi'),
                subtitle: Text('$volume ml'),
                trailing: const Icon(Icons.edit),
                onTap: () => _showVolumeEditDialog(index),
              );
            }).toList(),
          ),

          // 4) Sabit Aralık Ayarları
          _buildSettingsCard(
            title: 'Sabit Aralık Ayarları',
            children: [
              ListTile(
                leading: Icon(Icons.access_time, color: primary),
                title: const Text('Uyanma ve Yatış Saatleri\nBu saatler arasında bildirim almazsınız'),
                subtitle: Text('$_startHour:00 - $_endHour:00 Arası'),
                trailing: const Icon(Icons.edit),
                onTap: _showHoursEditDialog,
              ),
              ListTile(
                leading: Icon(Icons.notifications_none, color: primary),
                title: const Text('Hatırlatıcı Sıklığı'),
                subtitle: Text('Her $_intervalMinutes dakikada bir'),
                trailing: const Icon(Icons.edit),
                onTap: _showIntervalEditDialog,
              ),
            ],
          ),

          // 5) Veri Yönetimi
          _buildSettingsCard(
            title: 'Veri Yönetimi',
            children: [
              ListTile(
                leading: Icon(Icons.history, color: primary),
                title: const Text('Geçmiş Tüketim Ekle'),
                subtitle: const Text('Önceki günlere ait kaydı manuel girin'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _showPastIntakeDialog,
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Tüm Verileri Sıfırla'),
                subtitle: const Text('Tüm geçmiş kayıtlar ve istatistikler silinir.'),
                trailing: const Icon(Icons.warning, size: 16, color: Colors.red),
                onTap: _showClearDataDialog,
              ),
            ],
          ),

          // 6) Uygulama Bilgisi
          _buildSettingsCard(
            title: 'Uygulama Bilgisi',
            children: const [
              ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Uygulama Versiyonu'),
                subtitle: Text('1.0.0'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}