import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const MalariaApp());

class MalariaApp extends StatelessWidget {
  const MalariaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Malaria Incidence Predictor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B5E20),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
      home: const PredictionPage(),
    );
  }
}

// ---------------------------------------------------------------------------
// Model for each input field
// ---------------------------------------------------------------------------
class _Field {
  final String key;
  final String label;
  final String hint;
  final double min;
  final double max;
  final TextEditingController controller = TextEditingController();

  _Field({
    required this.key,
    required this.label,
    required this.hint,
    required this.min,
    required this.max,
  });
}

// ---------------------------------------------------------------------------
// Prediction Page
// ---------------------------------------------------------------------------
class PredictionPage extends StatefulWidget {
  const PredictionPage({super.key});

  @override
  State<PredictionPage> createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  // Replace with your deployed Render URL once live
  static const String _apiUrl =
      'https://malaria-predictor-api.onrender.com/predict';

  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _result;
  String? _error;

  // 26 fields matching the API Pydantic model
  final List<_Field> _fields = [
    _Field(key: 'country_name',               label: 'Country Name (encoded)',           hint: '0 – 53',    min: 0,    max: 53),
    _Field(key: 'year',                        label: 'Year',                             hint: '2007–2017', min: 2007, max: 2017),
    _Field(key: 'country_code',                label: 'Country Code (encoded)',           hint: '0 – 53',    min: 0,    max: 53),
    _Field(key: 'malaria_cases_reported',      label: 'Malaria Cases Reported',           hint: '≥ 0',       min: 0,    max: 20000000),
    _Field(key: 'bed_nets_pct',                label: 'Bed Net Usage (% under-5)',        hint: '0 – 100',   min: 0,    max: 100),
    _Field(key: 'fever_antimalarial_pct',      label: 'Fever Antimalarial Treatment (%)', hint: '0 – 100',   min: 0,    max: 100),
    _Field(key: 'ipt_pregnancy_pct',           label: 'IPT in Pregnancy (%)',             hint: '0 – 100',   min: 0,    max: 100),
    _Field(key: 'safe_water_total_pct',        label: 'Safe Water – Total (%)',           hint: '0 – 100',   min: 0,    max: 100),
    _Field(key: 'safe_water_rural_pct',        label: 'Safe Water – Rural (%)',           hint: '0 – 100',   min: 0,    max: 100),
    _Field(key: 'safe_water_urban_pct',        label: 'Safe Water – Urban (%)',           hint: '0 – 100',   min: 0,    max: 100),
    _Field(key: 'safe_sanitation_total_pct',   label: 'Safe Sanitation – Total (%)',      hint: '0 – 100',   min: 0,    max: 100),
    _Field(key: 'safe_sanitation_rural_pct',   label: 'Safe Sanitation – Rural (%)',      hint: '0 – 100',   min: 0,    max: 100),
    _Field(key: 'safe_sanitation_urban_pct',   label: 'Safe Sanitation – Urban (%)',      hint: '0 – 100',   min: 0,    max: 100),
    _Field(key: 'rural_population_pct',        label: 'Rural Population (%)',             hint: '0 – 100',   min: 0,    max: 100),
    _Field(key: 'rural_population_growth',     label: 'Rural Population Growth (%/yr)',   hint: '-10 – 10',  min: -10,  max: 10),
    _Field(key: 'urban_population_pct',        label: 'Urban Population (%)',             hint: '0 – 100',   min: 0,    max: 100),
    _Field(key: 'urban_population_growth',     label: 'Urban Population Growth (%/yr)',   hint: '-10 – 10',  min: -10,  max: 10),
    _Field(key: 'basic_water_total_pct',       label: 'Basic Water – Total (%)',          hint: '0 – 100',   min: 0,    max: 100),
    _Field(key: 'basic_water_rural_pct',       label: 'Basic Water – Rural (%)',          hint: '0 – 100',   min: 0,    max: 100),
    _Field(key: 'basic_water_urban_pct',       label: 'Basic Water – Urban (%)',          hint: '0 – 100',   min: 0,    max: 100),
    _Field(key: 'basic_sanitation_total_pct',  label: 'Basic Sanitation – Total (%)',     hint: '0 – 100',   min: 0,    max: 100),
    _Field(key: 'basic_sanitation_rural_pct',  label: 'Basic Sanitation – Rural (%)',     hint: '0 – 100',   min: 0,    max: 100),
    _Field(key: 'basic_sanitation_urban_pct',  label: 'Basic Sanitation – Urban (%)',     hint: '0 – 100',   min: 0,    max: 100),
    _Field(key: 'latitude',                    label: 'Latitude',                         hint: '-35 – 38',  min: -35,  max: 38),
    _Field(key: 'longitude',                   label: 'Longitude',                        hint: '-18 – 52',  min: -18,  max: 52),
    _Field(key: 'geometry',                    label: 'Geometry (encoded)',               hint: '0 – 53',    min: 0,    max: 53),
  ];

  // Section groupings: (title, startIndex, endIndex)
  static const List<(String, int, int)> _sections = [
    ('Country & Year',      0,  4),
    ('Disease Indicators',  4,  7),
    ('Water Services',      7,  10),
    ('Sanitation Services', 10, 13),
    ('Population',          13, 17),
    ('Basic Water',         17, 20),
    ('Basic Sanitation',    20, 23),
    ('Geography',           23, 26),
  ];

  Future<void> _predict() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _result = null;
      _error = null;
    });

    final body = <String, dynamic>{};
    for (final f in _fields) {
      final val = double.tryParse(f.controller.text.trim()) ?? 0.0;
      body[f.key] = f.key == 'year' ? val.toInt() : val;
    }

    try {
      final response = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final value = data['predicted_malaria_incidence_per_1000'] as num;
        setState(() {
          _result =
              '${value.toStringAsFixed(2)} cases per 1,000 population at risk';
        });
      } else {
        setState(() {
          _error = 'Error ${response.statusCode}: ${data['detail'] ?? response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Request failed: $e';
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  String? _validateField(_Field f, String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final num = double.tryParse(value.trim());
    if (num == null) return 'Enter a valid number';
    if (num < f.min || num > f.max) {
      return 'Must be between ${f.min} and ${f.max}';
    }
    return null;
  }

  @override
  void dispose() {
    for (final f in _fields) {
      f.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Malaria Incidence Predictor',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Mission banner
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Predict malaria incidence rates (per 1,000 population at risk) '
                'to guide health resource allocation in Rwanda, Uganda & Kenya.',
                style: TextStyle(fontSize: 13, color: scheme.onPrimaryContainer),
                textAlign: TextAlign.center,
              ),
            ),

            // Input sections
            for (final (title, start, end) in _sections) ...[
              _SectionHeader(title: title),
              const SizedBox(height: 8),
              for (final f in _fields.sublist(start, end)) ...[
                _InputField(
                  field: f,
                  validator: (v) => _validateField(f, v),
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 6),
            ],

            const SizedBox(height: 8),

            // Predict button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _predict,
                icon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.biotech),
                label: Text(
                  _loading ? 'Predicting…' : 'Predict',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Result / Error display
            if (_result != null)
              _ResultCard(
                value: _result!,
                isError: false,
                color: scheme.primaryContainer,
                textColor: scheme.onPrimaryContainer,
              ),
            if (_error != null)
              _ResultCard(
                value: _error!,
                isError: true,
                color: const Color(0xFFFFEBEE),
                textColor: Colors.red.shade800,
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable widgets
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1B5E20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 14,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final _Field field;
  final FormFieldValidator<String>? validator;

  const _InputField({required this.field, this.validator});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: field.controller,
      keyboardType:
          const TextInputType.numberWithOptions(signed: true, decimal: true),
      decoration: InputDecoration(
        labelText: field.label,
        hintText: field.hint,
        labelStyle: const TextStyle(fontSize: 13),
      ),
      style: const TextStyle(fontSize: 14),
      validator: validator,
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String value;
  final bool isError;
  final Color color;
  final Color textColor;

  const _ResultCard({
    required this.value,
    required this.isError,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: textColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isError ? 'Prediction Error' : 'Prediction Result',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: isError ? 13 : 22,
              fontWeight: isError ? FontWeight.normal : FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
