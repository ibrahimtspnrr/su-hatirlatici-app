import 'package:flutter/material.dart';
import '../services/preference_service.dart';
import 'main_screen.dart';

enum Gender { male, female }

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _ageController = TextEditingController();

  Gender? _selectedGender;
  int _calculatedGoal = 2000;
  bool _isLoading = false; // 🔹 animasyon kontrolü

  @override
  void initState() {
    super.initState();
    _weightController.addListener(_recalc);
    _heightController.addListener(_recalc);
    _ageController.addListener(_recalc);
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  /// Günlük su ihtiyacı hesaplama (ml)
  int _calculateDailyGoal({
    required double weightKg,
    required int heightCm,
    required int age,
    required Gender gender,
  }) {
    double ml = weightKg * 35.0;
    if (gender == Gender.male) ml *= 1.05;
    if (gender == Gender.female) ml *= 0.95;
    if (age <= 18) ml *= 1.10;
    if (age >= 55) ml *= 0.90;
    if (heightCm > 180) ml += 200;
    if (heightCm < 160) ml -= 100;
    ml = ml.clamp(1200, 5000);
    return ((ml / 100).round() * 100).toInt();
  }

  void _recalc() {
    final weight = double.tryParse(_weightController.text);
    final height = int.tryParse(_heightController.text);
    final age = int.tryParse(_ageController.text);

    if (weight == null || height == null || age == null || _selectedGender == null) return;

    final newGoal = _calculateDailyGoal(
      weightKg: weight,
      heightCm: height,
      age: age,
      gender: _selectedGender!,
    );

    if (newGoal != _calculatedGoal) {
      setState(() => _calculatedGoal = newGoal);
    }
  }

  Future<void> _completeOnboarding() async {
    setState(() => _isLoading = true);

    final weight = double.tryParse(_weightController.text);
    final height = int.tryParse(_heightController.text);
    final age = int.tryParse(_ageController.text);

    if (weight == null || height == null || age == null || _selectedGender == null) {
      setState(() => _isLoading = false);
      return;
    }

    await preferenceService.saveWeight(weight);
    await preferenceService.saveHeightCm(height);
    await preferenceService.saveAge(age);
    await preferenceService.saveDailyGoal(_calculatedGoal);
    await preferenceService.setOnboardingComplete();

    await Future.delayed(const Duration(milliseconds: 800)); // küçük animasyon süresi

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainScreen()),
    );
  }

  void _onGenderChanged(Gender? value) {
    setState(() {
      _selectedGender = value;
    });
    _recalc();
  }

  bool get _isFormValid {
    final weight = double.tryParse(_weightController.text);
    final height = int.tryParse(_heightController.text);
    final age = int.tryParse(_ageController.text);

    return weight != null &&
        height != null &&
        age != null &&
        weight > 0 &&
        height > 0 &&
        age > 0 &&
        _selectedGender != null;
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 180,
            backgroundColor: primary,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              // ✅ 1) Başlık değişti: Hızlı Kurulum → Kişisel Bilgiler
              title: const Text('Kişisel Bilgiler', style: TextStyle(fontWeight: FontWeight.w700)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primary.withOpacity(0.95), primary.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16.0, bottom: 24.0),
                    child: Icon(Icons.water_drop_rounded,
                        color: Colors.white.withOpacity(0.2), size: 120),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _card(
                    context,
                    title: 'Temel Bilgiler',
                    child: Column(
                      children: [
                        _labeledField(
                          label: 'Kilonuz',
                          suffix: 'kg',
                          controller: _weightController,
                          hint: 'Örn: 75',
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _labeledField(
                                label: 'Boyunuz',
                                suffix: 'cm',
                                controller: _heightController,
                                hint: 'Örn: 175',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _labeledField(
                                label: 'Yaş',
                                suffix: 'yıl',
                                controller: _ageController,
                                hint: 'Örn: 28',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // ✅ 2) Kadın butonu seçilince mor — tasarım korunuyor
                        _genderSelector(primary),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _goalCard(context, _calculatedGoal),
                  const SizedBox(height: 24),

                  // === Başlat Butonu ===
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isFormValid && !_isLoading
                          ? _completeOnboarding
                          : null,
                      style: ElevatedButton.styleFrom(
                        // ✅ Kadın seçiliyse mor, aksi halde tema rengi
                        backgroundColor: _isFormValid
                            ? (_selectedGender == Gender.female
                            ? const Color(0xFF9C27B0) // 💜 Kadın seçilirse mor
                            : primary)                // 🔹 Erkek/seçilmemiş: tema rengi
                            : Colors.grey.shade400,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 6,
                        shadowColor: primary.withOpacity(0.4),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: _isLoading
                            ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              "Hesaplanıyor...",
                              key: ValueKey('loading'),
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        )
                            : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.check_circle_rounded),
                            SizedBox(width: 8),
                            Text(
                              'Kullanmaya Başla',
                              key: ValueKey('start'),
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI Helpers ---
  Widget _card(BuildContext context, {required String title, required Widget child}) {
    return Card(
      elevation: 8,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),

    );
  }

  Widget _labeledField({
    required String label,
    required TextEditingController controller,
    required String suffix,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: hint,
            suffixText: suffix,
            filled: true,
            fillColor: Colors.grey.shade100,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),
      ],
    );
  }

  Widget _genderSelector(Color primary) {
    final bool male = _selectedGender == Gender.male;
    final bool female = _selectedGender == Gender.female;

    // İçeride tasarımı bozmadan sadece "aktif renk"i parametre yaptık
    Widget pill({
      required bool selected,
      required IconData icon,
      required String label,
      required VoidCallback onTap,
      required Color activeColor, // ← aktifken kullanılacak renk
    }) {
      return Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: selected ? activeColor.withOpacity(0.12) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? activeColor : Colors.grey.shade300,
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Icon(icon, color: selected ? activeColor : Colors.grey),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: selected ? activeColor : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        // Erkek → tema rengi
        pill(
          selected: male,
          icon: Icons.male_rounded,
          label: 'Erkek',
          onTap: () => _onGenderChanged(Gender.male),
          activeColor: primary,
        ),
        const SizedBox(width: 12),
        // Kadın → mor
        pill(
          selected: female,
          icon: Icons.female_rounded,
          label: 'Kadın',
          onTap: () => _onGenderChanged(Gender.female),
          activeColor: const Color(0xFF9C27B0), // 💜 mor
        ),
      ],
    );
  }

  Widget _goalCard(BuildContext context, int goal) {
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.95),
              Theme.of(context).primaryColor.withOpacity(0.65),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          // 1. DÜZELTME: 'children' listesinin başındaki 'const' kaldırıldı.
          children: [
            const Text('Önerilen Günlük Hedef',
                style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    fontSize: 16)),
            const SizedBox(height: 6),

            // 2. DÜZELTME: Eksik olan Text widget'ı buraya eklendi.
            Text(
              '$goal ml', // 'goal' parametresi burada kullanılıyor
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
