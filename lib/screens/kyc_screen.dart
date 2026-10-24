import 'package:digia_engage/digia_engage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/digia_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_message.dart';

/// Opens the KYC form. Shows a confirmation message once it's submitted.
Future<void> openKycScreen(BuildContext context) async {
  final submitted = await Navigator.push<bool>(
    context,
    MaterialPageRoute(builder: (_) => const KycScreen()),
  );
  // The KYC screen is only reachable from the Account tab.
  Digia.setCurrentScreen(ScreenIds.account);
  if (submitted == true && context.mounted) {
    showAppMessage(context, 'KYC details submitted');
  }
}

/// Collects the user's KYC details: name, PAN and date of birth.
class KycScreen extends StatefulWidget {
  const KycScreen({super.key});

  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _pan = TextEditingController();
  final _dob = TextEditingController();

  static final _panPattern = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$');
  static final _dobPattern = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$');

  @override
  void initState() {
    super.initState();
    Digia.setCurrentScreen(ScreenIds.kyc);
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _pan.dispose();
    _dob.dispose();
    super.dispose();
  }

  String? _required(String? value, String field) =>
      (value == null || value.trim().isEmpty) ? 'Enter your $field' : null;

  String? _validatePan(String? value) {
    final pan = value?.trim() ?? '';
    if (pan.isEmpty) return 'Enter your PAN';
    if (!_panPattern.hasMatch(pan)) return 'PAN must look like ABCDE1234F';
    return null;
  }

  /// Parses DD/MM/YYYY, returning null if the text isn't a real date.
  DateTime? _parseDob(String text) {
    final match = _dobPattern.firstMatch(text.trim());
    if (match == null) return null;
    final day = int.parse(match[1]!);
    final month = int.parse(match[2]!);
    final year = int.parse(match[3]!);
    final date = DateTime(year, month, day);
    final valid = date.year == year && date.month == month && date.day == day;
    return valid ? date : null;
  }

  String? _validateDob(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter your date of birth';
    }
    final dob = _parseDob(value);
    if (dob == null) return 'Use the format DD/MM/YYYY';
    final now = DateTime.now();
    final eighteenthBirthday = DateTime(dob.year + 18, dob.month, dob.day);
    if (eighteenthBirthday.isAfter(now)) return 'You must be at least 18';
    if (dob.year < 1900) return 'Enter a valid date of birth';
    return null;
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final latest = DateTime(now.year - 18, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _parseDob(_dob.text) ?? DateTime(latest.year - 7),
      firstDate: DateTime(1900),
      lastDate: latest,
    );
    if (picked == null) return;
    String two(int n) => n.toString().padLeft(2, '0');
    _dob.text = '${two(picked.day)}/${two(picked.month)}/${picked.year}';
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Digia.trackEvent('kyc_submitted');
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete KYC')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Enter your details exactly as they appear on your PAN card.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              TextFormField(
                key: const ValueKey('kyc_first_name'),
                controller: _firstName,
                decoration: const InputDecoration(
                  labelText: 'First name',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.givenName],
                validator: (v) => _required(v, 'first name'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const ValueKey('kyc_last_name'),
                controller: _lastName,
                decoration: const InputDecoration(
                  labelText: 'Last name',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.familyName],
                validator: (v) => _required(v, 'last name'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const ValueKey('kyc_pan'),
                controller: _pan,
                decoration: const InputDecoration(
                  labelText: 'PAN card number',
                  hintText: 'ABCDE1234F',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]')),
                  LengthLimitingTextInputFormatter(10),
                  _UpperCaseFormatter(),
                ],
                validator: _validatePan,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const ValueKey('kyc_dob'),
                controller: _dob,
                decoration: InputDecoration(
                  labelText: 'Date of birth',
                  hintText: 'DD/MM/YYYY',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    tooltip: 'Pick date',
                    onPressed: _pickDob,
                    icon: const Icon(Icons.calendar_today_outlined),
                  ),
                ),
                keyboardType: TextInputType.datetime,
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9/]')),
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: _validateDob,
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 28),
              FilledButton(
                key: const ValueKey('kyc_submit'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _submit,
                child: const Text(
                  'Submit',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: newValue.text.toUpperCase());
}
