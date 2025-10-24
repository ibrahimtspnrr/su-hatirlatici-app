// lib/screens/home_screen.dart (PREMIUM bottom sheet tasarım)

import 'package:flutter/material.dart';
import 'dart:math';
import '../services/preference_service.dart';
import '../services/water_record_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _dailyGoal = 2000;
  int _todayIntake = 0;
  List<int> _customVolumes = [];
  String _progressColorHex = '';
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    waterRecordService.waterBox.addListener(_updateIntakeFromHive);
    _updateIntakeFromHive();
  }

  @override
  void dispose() {
    waterRecordService.waterBox.removeListener(_updateIntakeFromHive);
    super.dispose();
  }

  void _loadSettings() {
    setState(() {
      _dailyGoal = preferenceService.getDailyGoal();
      _customVolumes = preferenceService.getCustomVolumes();
    });
  }

  void _updateIntakeFromHive() {
    setState(() {
      _todayIntake = waterRecordService.getTodayIntake();
    });
  }

  Future<void> _updateWater(int amount, {bool isSubtraction = false}) async {
    int finalAmount = isSubtraction ? -amount : amount;
    int newIntake = _todayIntake + finalAmount;
    if (newIntake < 0) newIntake = 0;

    await waterRecordService.updateTodayIntake(newIntake);

    if (!mounted) return;

    if (finalAmount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('+$finalAmount ml su eklendi!')),
      );
    } else if (finalAmount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${finalAmount} ml su çıkarıldı.')),
      );
    }
  }

  // ---------- PREMIUM: Alt Sayfa ile Manuel Düzenleme ----------
  void _showManualUpdateSheet() {
    final TextEditingController controller = TextEditingController();
    bool isAddition = true;
    int amount = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SafeArea(
            top: false,
            child: StatefulBuilder(
              builder: (context, setInner) {
                void applyQuick(int v) {
                  amount = v;
                  controller.text = v.toString();
                  setInner(() {});
                }

                void step(int delta) {
                  final curr = int.tryParse(controller.text) ?? amount;
                  amount = (curr + delta).clamp(0, 100000);
                  controller.text = amount.toString();
                  setInner(() {});
                }

                Future<void> submit() async {
                  final parsed = int.tryParse(controller.text) ?? 0;
                  if (parsed <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lütfen geçerli bir miktar giriniz.')),
                    );
                    return;
                  }
                  await _updateWater(parsed, isSubtraction: !isAddition);
                  if (mounted) Navigator.pop(context);
                }

                final quicks = <int>{
                  ..._customVolumes,
                  150, 250, 300, 500
                }.toList()
                  ..sort();

                final Color primary = Colors.green.shade600;
                final Color removeColor = Colors.red.shade600;

                return Column(
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Text(
                            'Tüketimi ${isAddition ? "Ekle" : "Çıkar"}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: isAddition ? primary : removeColor,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(color: Colors.black12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _SegmentPill(
                                  label: 'Ekle',
                                  active: isAddition,
                                  activeColor: primary,
                                  onTap: () => setInner(() => isAddition = true),
                                ),
                                _SegmentPill(
                                  label: 'Çıkar',
                                  active: !isAddition,
                                  activeColor: removeColor,
                                  onTap: () => setInner(() => isAddition = false),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: () => step(-50),
                                icon: const Icon(Icons.remove_rounded),
                                tooltip: '-50',
                              ),
                              IconButton(
                                onPressed: () => step(-10),
                                icon: const Icon(Icons.remove),
                                tooltip: '-10',
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: TextField(
                                  controller: controller,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                                  decoration: const InputDecoration(
                                    hintText: '0',
                                    border: InputBorder.none,
                                    suffixText: ' ml',
                                  ),
                                  onChanged: (v) => amount = int.tryParse(v) ?? 0,
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                onPressed: () => step(10),
                                icon: const Icon(Icons.add),
                                tooltip: '+10',
                              ),
                              IconButton(
                                onPressed: () => step(50),
                                icon: const Icon(Icons.add_rounded),
                                tooltip: '+50',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (quicks.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: quicks.map((v) {
                            final selected = amount == v;
                            return ChoiceChip(
                              label: Text('$v ml'),
                              selected: selected,
                              onSelected: (_) => applyQuick(v),
                              selectedColor: (isAddition ? primary : removeColor).withOpacity(0.15),
                              labelStyle: TextStyle(
                                color: selected ? (isAddition ? primary : removeColor) : null,
                                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: FilledButton.icon(
                        onPressed: submit,
                        icon: Icon(isAddition ? Icons.add_circle : Icons.remove_circle),
                        label: Text(isAddition ? 'Ekle' : 'Çıkar'),
                        style: FilledButton.styleFrom(
                          backgroundColor: isAddition ? primary : removeColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }


  // Premium segment parçası
  // (küçük yuvarlak toggle butonları)
  // ignore: unused_element
  // (dosyada private ama StatefulBuilder içinde kullanılıyor)
  // Bu widget altta.
  // ------------------------------------------------------------

  String _getMotivationMessage(double progress) {
    // Premium tarzda rastgele seçilen derin motivasyon cümleleri
    final List<String> startMessages = [
      "Her yudum bir adım. Küçük başla, büyük hisset. 💧",
      "Zihnin uyanmadan önce vücudunu uyandır: bir bardak suyla. ☀️",
      "Bugün ne olursa olsun, kendine iyi davran — başla bir bardakla. 🌿",
      "İlk yudumun, günün tonunu belirler. İç, nefes al, devam et. 🌤️",
      "Hedefler büyük olabilir ama ilk adım hep küçük bir bardaktır. 🚀",
      "Kendini önemsemenin en sade yolu: su içmek. 💙",
      "Sade, sessiz, etkili bir alışkanlık: hidrasyon. ✨",
      "Su, odaklanmanın en doğal yakıtıdır. Zihnini aç. 🧠",
    ];

    final List<String> lowMessages = [
      "Her küçük yudum seni tazeler — devam et. 🌸",
      "Sadece içtiğin su değil, kendine verdiğin değer artıyor. 💎",
      "Bir bardak daha, bir fark daha. ⛅",
      "Gövden seninle işbirliği yapıyor, suyla ona destek ol. 💧",
      "Motivasyon dışarıda değil, senin içinde — ve biraz da bardakta. 🌿",
      "Günün sakin gücü: suyun berraklığı sende. 🌊",
      "Bardağını doldur, enerjini yenile. Her şey dengeyle başlar. ⚖️",
    ];

    final List<String> midMessages = [
      "Yolun yarısındasın, bu istikrarın sihirli eşiği. ✨",
      "Hedefe yaklaşırken suyun seni güçlendirsin. 💪",
      "Sadece susuzluğu değil, kararlılığı da gideriyorsun. 🔥",
      "Ritmini buldun. Şimdi devam et, suyun akışı gibi. 🌊",
      "Vücudun seni ödüllendiriyor — sen farkında olmasan da. 💫",
      "Bir bardak daha: basit ama mükemmel bir seçim. 💧",
      "İstikrar, fark edilmeden kazanılan bir süper güçtür. 🦾",
    ];

    final List<String> highMessages = [
      "Harika gidiyorsun! Enerjin fark yaratıyor. 🌟",
      "Neredeyse tamam. Küçük bir adım, büyük bir tatmin. 🏁",
      "Sınırları zorluyorsun — bu disiplini herkes yapamaz. 💪",
      "Suyun berraklığı gibi zihnin de netleşiyor. ✨",
      "Bu alışkanlık seni dönüştürüyor. Her bardakta biraz daha. 🌱",
      "Kendinle gurur duymalısın, çünkü tutarlılık bir erdemdir. 🧘‍♂️",
      "Bir yudum daha, bir kazanç daha. İlerliyorsun. ⏳",
    ];

    final List<String> goalMessages = [
      "Hedef tamamlandı! Şimdi bedenin teşekkür ediyor. 🏆",
      "Kendine yatırımın meyvesini topluyorsun. 💙",
      "Bu istikrar bir alışkanlık değil, yaşam biçimi. 🌟",
      "Hidrasyon şampiyonu! Her yudum bir zaferdi. 🥇",
      "Sadece su içmedin, disiplini içselleştirdin. ✨",
      "Bugün kendine verdiğin sözü tuttun. Bunun adı güçtür. 💪",
      "Suyun berraklığı sende parlıyor. Gurur duy. 💫",
      "Şimdi derin bir nefes al, çünkü gerçekten harika bir iş çıkardın. 🌿",
    ];

    // Premium karışımı — gelişim hissine göre dağıtım
    if (progress >= 1.0) {
      return goalMessages[_random.nextInt(goalMessages.length)];
    } else if (progress >= 0.75) {
      return highMessages[_random.nextInt(highMessages.length)];
    } else if (progress >= 0.50) {
      return midMessages[_random.nextInt(midMessages.length)];
    } else if (progress >= 0.25) {
      return lowMessages[_random.nextInt(lowMessages.length)];
    } else {
      return startMessages[_random.nextInt(startMessages.length)];
    }
  }


  Widget _buildQuickAddButton(int volume, Color progressColor) {
    const IconData defaultIcon = Icons.local_drink;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton.icon(
          onPressed: () => _updateWater(volume),
          icon: const Icon(defaultIcon, color: Colors.white),
          label: Text(
            '+$volume ml',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: progressColor.withOpacity(0.8),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            elevation: 6,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double progress = _todayIntake / _dailyGoal;
    if (progress > 1.0) progress = 1.0;

// Tema rengine doğrudan bağlanıyor (artık tema değişince bu da değişiyor)
    Color selectedProgressColor = Theme.of(context).colorScheme.primary;

    final Color progressColor = progress >= 1.0 ? Colors.green.shade500 : selectedProgressColor;
    final Color textColor = Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87;
    final String motivationalMessage = _getMotivationMessage(progress);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Günlük Takip',
          style: TextStyle(
            color: Colors.white, // yazı beyaz
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false, // sola hizalı
        elevation: 4, // gölge efekti
        backgroundColor: Theme.of(context).colorScheme.primary, // tema rengi
        shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.4),
      ),


      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 1. İlerleme Çubuğu ve Merkezi Görsel
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: progressColor.withOpacity(0.3),
                            blurRadius: 25,
                            spreadRadius: 3,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 250,
                            height: 250,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 20,
                              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$_todayIntake ml',
                                style: TextStyle(fontSize: 42, fontWeight: FontWeight.w800, color: textColor),
                              ),
                              Text(
                                '/ $_dailyGoal ml',
                                style: TextStyle(fontSize: 18, color: Colors.grey.shade500),
                              ),
                              if (_todayIntake >= _dailyGoal)
                                const Padding(
                                  padding: EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    'HEDEF TAMAMLANDI! 🏅',
                                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Motivasyon mesajı
                    Text(
                      motivationalMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: progressColor, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Hızlı Ekleme Butonları
            const Text(
              'Hızlı Tüketim Ekle',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _customVolumes.map((volume) {
                return _buildQuickAddButton(volume, progressColor);
              }).toList(),
            ),

            // 3. Manuel Düzenleme Butonu
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showManualUpdateSheet, // <<< yeni premium alt sayfa
                icon: const Icon(Icons.edit_note, size: 24),
                label: const Text('Tüketimi Düzenle / Çıkar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

// ------------------ Yardımcı küçük widget ------------------

class _SegmentPill extends StatelessWidget {
  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _SegmentPill({
    required this.label,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(100),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
            fontWeight: active ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
