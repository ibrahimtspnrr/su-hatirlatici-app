import 'package:flutter/material.dart';
import '../services/preference_service.dart';

enum Gender { male, female }

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _ageController = TextEditingController();

  Gender? _selectedGender;
  int _previewGoal = 2000;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Var olan değerleri yükle (preferenceService’de bu getter’ların tanımlı olduğunu varsayıyorum)
    final weight = preferenceService.getWeight();
    _weightController.text = weight.toStringAsFixed(weight.truncateToDouble() == weight ? 0 : 1);

    // Bu iki getter sende zaten tanımlıysa kullanılır; yoksa 170/25 fallback
    int height;
    try {
      // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
      // Eğer projende getHeightCm yoksa bu satırı kendi getter’ınla değiştir.
      // Aşağıdaki satırı kendi servisindeki metoda göre düzenleyebilirsin.
      // örn: preferenceService.getHeightCm()
      height = (preferenceService as dynamic).getHeightCm();
    } catch (_) {
      height = 170;
    }
    _heightController.text = height.toString();

    int age;
    try {
      // örn: preferenceService.getAge()
      age = (preferenceService as dynamic).getAge();
    } catch (_) {
      age = 25;
    }
    _ageController.text = age.toString();

    // Cinsiyet saklıysa yükle (yoksa null kalsın)
    try {
      final g = (preferenceService as dynamic).getGender(); // e.g. returns 'male'/'female'
      if (g == 'male') _selectedGender = Gender.male;
      if (g == 'female') _selectedGender = Gender.female;
    } catch (_) {
      // opsiyonel
    }

    _weightController.addListener(_recalc);
    _heightController.addListener(_recalc);
    _ageController.addListener(_recalc);

    // İlk hedef önizlemesi
    _recalc();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

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

    final goal = _calculateDailyGoal(
      weightKg: weight,
      heightCm: height,
      age: age,
      gender: _selectedGender!,
    );
    if (goal != _previewGoal) {
      setState(() => _previewGoal = goal);
    }
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

  Future<void> _save() async {
    if (!_isFormValid) return;
    setState(() => _saving = true);

    final weight = double.parse(_weightController.text);
    final height = int.parse(_heightController.text);
    final age = int.parse(_ageController.text);

    await preferenceService.saveWeight(weight);

    try {
      await (preferenceService as dynamic).saveHeightCm(height);
    } catch (_) { /* servisinde yoksa göz ardı et */ }

    try {
      await (preferenceService as dynamic).saveAge(age);
    } catch (_) {}

    // cinsiyet saklama (opsiyonel string olarak)
    try {
      await (preferenceService as dynamic)
          .saveGender(_selectedGender == Gender.female ? 'female' : 'male');
    } catch (_) {}

    await preferenceService.saveDailyGoal(_previewGoal);

    setState(() => _saving = false);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  void _setGender(Gender g) {
    setState(() => _selectedGender = g);
    _recalc();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final femaleColor = const Color(0xFF9C27B0); // Mor

    // Kadın seçiliyse üst appbar rengini mor yapabiliriz; istemezsen primary kullan.
    final appbarColor = _selectedGender == Gender.female ? femaleColor : primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kişisel Bilgiler'),
        backgroundColor: appbarColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _sectionCard(
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
                _genderSelector(
                  maleActive: primary,
                  femaleActive: femaleColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _goalCard(context, _previewGoal),
          const SizedBox(height: 24),

          SizedBox(
            height: 55,
            child: ElevatedButton(
              onPressed: _isFormValid && !_saving ? _save : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isFormValid
                    ? (_selectedGender == Gender.female ? femaleColor : primary)
                    : Colors.grey.shade400,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 6,
                shadowColor: appbarColor.withOpacity(0.4),
              ),
              child: _saving
                  ? const SizedBox(
                height: 22, width: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
              )
                  : const Text('Kaydet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI helpers ---
  Widget _sectionCard(BuildContext context, {required String title, required Widget child}) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0), // <-- BURAYA DİKKAT: padding parametresi şart
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            title,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(height: 12),
          child,
        ]),
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),
      ],
    );
  }

  Widget _genderSelector({
    required Color maleActive,
    required Color femaleActive,
  }) {
    final bool male = _selectedGender == Gender.male;
    final bool female = _selectedGender == Gender.female;

    Widget pill({
      required bool selected,
      required IconData icon,
      required String label,
      required VoidCallback onTap,
      required Color activeColor,
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
        pill(
          selected: male,
          icon: Icons.male_rounded,
          label: 'Erkek',
          onTap: () => _setGender(Gender.male),
          activeColor: maleActive,   // tema rengi
        ),
        const SizedBox(width: 12),
        pill(
          selected: female,
          icon: Icons.female_rounded,
          label: 'Kadın',
          onTap: () => _setGender(Gender.female),
          activeColor: femaleActive, // mor
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
          children: [
            const Text('Önerilen Günlük Hedef',
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 6),
            Text(
              '$goal ml',
              style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            const Text('Bilgilerinize göre akıllı hesaplama', style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
