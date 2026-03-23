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
        fontFamily: 'Roboto',
      ),
      home: const PredictionPage(),
    );
  }
}

// ---------------------------------------------------------------------------
// Country presets
// ---------------------------------------------------------------------------
const Map<String, Map<String, String>> _countryPresets = {
  'Rwanda': {
    'country_name': '40',
    'year': '2015',
    'country_code': '40',
    'malaria_cases_reported': '3500000',
    'bed_nets_pct': '53.0',
    'fever_antimalarial_pct': '38.0',
    'ipt_pregnancy_pct': '31.0',
    'safe_water_total_pct': '14.0',
    'safe_water_rural_pct': '8.0',
    'safe_water_urban_pct': '42.0',
    'safe_sanitation_total_pct': '6.0',
    'safe_sanitation_rural_pct': '4.0',
    'safe_sanitation_urban_pct': '20.0',
    'rural_population_pct': '83.0',
    'rural_population_growth': '2.1',
    'urban_population_pct': '17.0',
    'urban_population_growth': '6.5',
    'basic_water_total_pct': '76.0',
    'basic_water_rural_pct': '70.0',
    'basic_water_urban_pct': '93.0',
    'basic_sanitation_total_pct': '49.0',
    'basic_sanitation_rural_pct': '44.0',
    'basic_sanitation_urban_pct': '72.0',
    'latitude': '-1.94',
    'longitude': '29.87',
    'geometry': '40',
  },
  'Uganda': {
    'country_name': '48',
    'year': '2015',
    'country_code': '48',
    'malaria_cases_reported': '9800000',
    'bed_nets_pct': '42.0',
    'fever_antimalarial_pct': '55.0',
    'ipt_pregnancy_pct': '20.0',
    'safe_water_total_pct': '8.0',
    'safe_water_rural_pct': '4.0',
    'safe_water_urban_pct': '28.0',
    'safe_sanitation_total_pct': '5.0',
    'safe_sanitation_rural_pct': '3.0',
    'safe_sanitation_urban_pct': '15.0',
    'rural_population_pct': '84.0',
    'rural_population_growth': '3.2',
    'urban_population_pct': '16.0',
    'urban_population_growth': '5.8',
    'basic_water_total_pct': '55.0',
    'basic_water_rural_pct': '48.0',
    'basic_water_urban_pct': '88.0',
    'basic_sanitation_total_pct': '19.0',
    'basic_sanitation_rural_pct': '14.0',
    'basic_sanitation_urban_pct': '50.0',
    'latitude': '1.37',
    'longitude': '32.29',
    'geometry': '48',
  },
  'Kenya': {
    'country_name': '22',
    'year': '2015',
    'country_code': '22',
    'malaria_cases_reported': '6500000',
    'bed_nets_pct': '47.0',
    'fever_antimalarial_pct': '30.0',
    'ipt_pregnancy_pct': '43.0',
    'safe_water_total_pct': '22.0',
    'safe_water_rural_pct': '12.0',
    'safe_water_urban_pct': '45.0',
    'safe_sanitation_total_pct': '10.0',
    'safe_sanitation_rural_pct': '6.0',
    'safe_sanitation_urban_pct': '25.0',
    'rural_population_pct': '74.0',
    'rural_population_growth': '2.4',
    'urban_population_pct': '26.0',
    'urban_population_growth': '4.2',
    'basic_water_total_pct': '63.0',
    'basic_water_rural_pct': '53.0',
    'basic_water_urban_pct': '85.0',
    'basic_sanitation_total_pct': '30.0',
    'basic_sanitation_rural_pct': '22.0',
    'basic_sanitation_urban_pct': '55.0',
    'latitude': '-0.02',
    'longitude': '37.91',
    'geometry': '22',
  },
};

// ---------------------------------------------------------------------------
// Field model
// ---------------------------------------------------------------------------
class _Field {
  final String key;
  final String label;
  final String rangeLabel;
  final IconData icon;
  final double min;
  final double max;
  final TextEditingController controller = TextEditingController();

  _Field({
    required this.key,
    required this.label,
    required this.rangeLabel,
    required this.icon,
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
  static const String _apiUrl =
      'https://malaria-predictor-api.onrender.com/predict';

  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  double? _resultValue;
  String? _error;
  String _selectedCountry = 'Rwanda';

  final List<_Field> _fields = [
    _Field(key: 'country_name',               label: 'Country Name (encoded) [0–53]',           rangeLabel: '0–53',    icon: Icons.flag,               min: 0,    max: 53),
    _Field(key: 'year',                        label: 'Year [2007–2017]',                         rangeLabel: '2007–2017', icon: Icons.calendar_today,   min: 2007, max: 2017),
    _Field(key: 'country_code',                label: 'Country Code (encoded) [0–53]',            rangeLabel: '0–53',    icon: Icons.tag,                min: 0,    max: 53),
    _Field(key: 'malaria_cases_reported',      label: 'Malaria Cases Reported [≥0]',              rangeLabel: '≥0',      icon: Icons.sick,               min: 0,    max: 20000000),
    _Field(key: 'bed_nets_pct',                label: 'Bed Net Usage % under-5 [0–100]',          rangeLabel: '0–100',   icon: Icons.bed,                min: 0,    max: 100),
    _Field(key: 'fever_antimalarial_pct',      label: 'Fever Antimalarial Treatment % [0–100]',   rangeLabel: '0–100',   icon: Icons.medication,         min: 0,    max: 100),
    _Field(key: 'ipt_pregnancy_pct',           label: 'IPT in Pregnancy % [0–100]',               rangeLabel: '0–100',   icon: Icons.pregnant_woman,     min: 0,    max: 100),
    _Field(key: 'safe_water_total_pct',        label: 'Safe Water Total % [0–100]',               rangeLabel: '0–100',   icon: Icons.water_drop,         min: 0,    max: 100),
    _Field(key: 'safe_water_rural_pct',        label: 'Safe Water Rural % [0–100]',               rangeLabel: '0–100',   icon: Icons.water_drop,         min: 0,    max: 100),
    _Field(key: 'safe_water_urban_pct',        label: 'Safe Water Urban % [0–100]',               rangeLabel: '0–100',   icon: Icons.water_drop,         min: 0,    max: 100),
    _Field(key: 'safe_sanitation_total_pct',   label: 'Safe Sanitation Total % [0–100]',          rangeLabel: '0–100',   icon: Icons.clean_hands,        min: 0,    max: 100),
    _Field(key: 'safe_sanitation_rural_pct',   label: 'Safe Sanitation Rural % [0–100]',          rangeLabel: '0–100',   icon: Icons.clean_hands,        min: 0,    max: 100),
    _Field(key: 'safe_sanitation_urban_pct',   label: 'Safe Sanitation Urban % [0–100]',          rangeLabel: '0–100',   icon: Icons.clean_hands,        min: 0,    max: 100),
    _Field(key: 'rural_population_pct',        label: 'Rural Population % [0–100]',               rangeLabel: '0–100',   icon: Icons.nature_people,      min: 0,    max: 100),
    _Field(key: 'rural_population_growth',     label: 'Rural Population Growth %/yr [-10–10]',    rangeLabel: '-10–10',  icon: Icons.trending_up,        min: -10,  max: 10),
    _Field(key: 'urban_population_pct',        label: 'Urban Population % [0–100]',               rangeLabel: '0–100',   icon: Icons.location_city,      min: 0,    max: 100),
    _Field(key: 'urban_population_growth',     label: 'Urban Population Growth %/yr [-10–10]',    rangeLabel: '-10–10',  icon: Icons.trending_up,        min: -10,  max: 10),
    _Field(key: 'basic_water_total_pct',       label: 'Basic Water Total % [0–100]',              rangeLabel: '0–100',   icon: Icons.opacity,            min: 0,    max: 100),
    _Field(key: 'basic_water_rural_pct',       label: 'Basic Water Rural % [0–100]',              rangeLabel: '0–100',   icon: Icons.opacity,            min: 0,    max: 100),
    _Field(key: 'basic_water_urban_pct',       label: 'Basic Water Urban % [0–100]',              rangeLabel: '0–100',   icon: Icons.opacity,            min: 0,    max: 100),
    _Field(key: 'basic_sanitation_total_pct',  label: 'Basic Sanitation Total % [0–100]',         rangeLabel: '0–100',   icon: Icons.sanitizer,          min: 0,    max: 100),
    _Field(key: 'basic_sanitation_rural_pct',  label: 'Basic Sanitation Rural % [0–100]',         rangeLabel: '0–100',   icon: Icons.sanitizer,          min: 0,    max: 100),
    _Field(key: 'basic_sanitation_urban_pct',  label: 'Basic Sanitation Urban % [0–100]',         rangeLabel: '0–100',   icon: Icons.sanitizer,          min: 0,    max: 100),
    _Field(key: 'latitude',                    label: 'Latitude [-35–38]',                        rangeLabel: '-35–38',  icon: Icons.explore,            min: -35,  max: 38),
    _Field(key: 'longitude',                   label: 'Longitude [-18–52]',                       rangeLabel: '-18–52',  icon: Icons.explore,            min: -18,  max: 52),
    _Field(key: 'geometry',                    label: 'Geometry (encoded) [0–53]',                rangeLabel: '0–53',    icon: Icons.map,                min: 0,    max: 53),
  ];

  static const List<(String, IconData, int, int)> _sections = [
    ('Country & Year',      Icons.public,        0,  4),
    ('Disease Indicators',  Icons.coronavirus,   4,  7),
    ('Water Services',      Icons.water_drop,    7,  10),
    ('Sanitation Services', Icons.clean_hands,   10, 13),
    ('Population',          Icons.people,        13, 17),
    ('Basic Water',         Icons.opacity,       17, 20),
    ('Basic Sanitation',    Icons.sanitizer,     20, 23),
    ('Geography',           Icons.map,           23, 26),
  ];

  @override
  void initState() {
    super.initState();
    _applyPreset('Rwanda');
  }

  void _applyPreset(String country) {
    final preset = _countryPresets[country]!;
    for (final f in _fields) {
      f.controller.text = preset[f.key] ?? '';
    }
    setState(() => _selectedCountry = country);
  }

  String _riskLabel(double value) {
    if (value < 100) return 'Low Risk';
    if (value < 300) return 'Moderate Risk';
    return 'High Risk';
  }

  Color _riskColor(double value) {
    if (value < 100) return const Color(0xFF2E7D32);
    if (value < 300) return const Color(0xFFF57F17);
    return const Color(0xFFC62828);
  }

  Future<void> _predict() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _resultValue = null;
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
        setState(() {
          _resultValue =
              (data['predicted_malaria_incidence_per_1000'] as num).toDouble();
        });
      } else {
        setState(() {
          _error = data['detail']?.toString() ?? 'Unknown error (${response.statusCode})';
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
    if (num < f.min || num > f.max) return 'Must be ${f.min} – ${f.max}';
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                      children: [
                        _buildCountrySelector(),
                        const SizedBox(height: 12),

                        for (final (title, icon, start, end) in _sections) ...[
                          _SectionCard(
                            title: title,
                            icon: icon,
                            fields: _fields.sublist(start, end),
                            validator: _validateField,
                          ),
                          const SizedBox(height: 12),
                        ],

                        const SizedBox(height: 8),
                        _buildPredictButton(),
                        const SizedBox(height: 16),

                        if (_resultValue != null) ...[
                          _buildResultCard(_resultValue!),
                          const SizedBox(height: 16),
                        ],
                        if (_error != null) ...[
                          _buildErrorCard(_error!),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountrySelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.tune, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'Country Preset',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select a country to auto-fill all fields with typical values. You can still edit any field manually.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCountry,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.flag, size: 18, color: Color(0xFF388E3C)),
                    filled: true,
                    fillColor: const Color(0xFFF9FBF9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF388E3C), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  items: _countryPresets.keys
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) _applyPreset(value);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        children: [
          const Icon(Icons.biotech, color: Colors.white, size: 40),
          const SizedBox(height: 8),
          const Text(
            'Malaria Incidence Predictor',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Rwanda · Uganda · Kenya',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(double value) {
    final color = _riskColor(value);
    final label = _riskLabel(value);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: color, size: 22),
              const SizedBox(width: 8),
              Text(
                'Prediction Result',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: color,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value.toStringAsFixed(2),
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: color,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'cases per 1,000 population at risk',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              error,
              style: TextStyle(color: Colors.red.shade800, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _loading ? null : _predict,
        icon: _loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white),
              )
            : const Icon(Icons.analytics, color: Colors.white),
        label: Text(
          _loading ? 'Predicting…' : 'Predict',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section Card
// ---------------------------------------------------------------------------
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_Field> fields;
  final String? Function(_Field, String?) validator;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.fields,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Column(
              children: [
                for (int i = 0; i < fields.length; i++) ...[
                  _buildField(fields[i]),
                  if (i < fields.length - 1) const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(_Field f) {
    return TextFormField(
      controller: f.controller,
      keyboardType:
          const TextInputType.numberWithOptions(signed: true, decimal: true),
      decoration: InputDecoration(
        labelText: f.label,
        prefixIcon: Icon(f.icon, size: 18, color: const Color(0xFF388E3C)),
        filled: true,
        fillColor: const Color(0xFFF9FBF9),
        labelStyle: const TextStyle(fontSize: 12, color: Colors.black54),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF388E3C), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      style: const TextStyle(fontSize: 14),
      validator: (v) => validator(f, v),
    );
  }
}
