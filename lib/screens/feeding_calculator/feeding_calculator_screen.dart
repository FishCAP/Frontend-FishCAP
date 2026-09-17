import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fishcap_app/l10n/app_localizations.dart';
import '../../services/api_service.dart';

class FeedingCalculatorScreen extends StatefulWidget {
  const FeedingCalculatorScreen({super.key});

  @override
  State<FeedingCalculatorScreen> createState() => _FeedingCalculatorScreenState();
}

class _FeedingCalculatorScreenState extends State<FeedingCalculatorScreen> {
  final _searchController = TextEditingController();
  final _countController = TextEditingController();
  final _weightController = TextEditingController();
  DateTime? _stockingDate;

  List<dynamic> _suggestions = [];
  Map<String, dynamic>? _selectedSpecies;
  Timer? _debounce;

  double? _totalFeedGrams;

  @override
  void dispose() {
    _searchController.dispose();
    _countController.dispose();
    _weightController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (q.trim().isEmpty) {
        setState(() => _suggestions = []);
        return;
      }
      final res = await ApiService.instance.searchSpecies(q);
      if (res['success'] == true && res['data'] is List) {
        setState(() => _suggestions = res['data']);
      }
    });
  }

  void _selectSpecies(Map<String, dynamic> s) {
    setState(() {
      _selectedSpecies = s;
      _searchController.text = (s['nameEn'] ?? s['nameKm'] ?? '') as String;
      _suggestions = [];
    });
  }

  void _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (picked != null) setState(() => _stockingDate = picked);
  }

  void _calculate() {
    final count = int.tryParse(_countController.text) ?? 0;
    if (count <= 0) {
      setState(() => _totalFeedGrams = 0);
      return;
    }

    double avgWeight = 0;
    if (_weightController.text.isNotEmpty) {
      avgWeight = double.tryParse(_weightController.text) ?? 0;
    } else {
      final defaultW = (_selectedSpecies?['defaultInitialWeight'] ?? 5).toDouble();
      final days = _stockingDate != null ? DateTime.now().difference(_stockingDate!).inDays : 0;
      // pick adg from last growth stage
      double adg = 1.0;
      final stages = _selectedSpecies?['growthStages'] as List<dynamic>?;
      if (stages != null && stages.isNotEmpty) {
        final last = stages.last as Map<String, dynamic>;
        adg = (last['adg'] as num?)?.toDouble() ?? adg;
      }
      avgWeight = defaultW + adg * days;
    }

    // determine feeding rate
    double feedingRate = 3.0;
    final stages = _selectedSpecies?['growthStages'] as List<dynamic>?;
    if (stages != null && stages.isNotEmpty) {
      bool found = false;
      for (final st in stages) {
        final minW = (st['minWeight'] as num?)?.toDouble() ?? 0;
        final maxW = (st['maxWeight'] as num?)?.toDouble() ?? double.infinity;
        if (avgWeight >= minW && avgWeight <= maxW) {
          feedingRate = (st['feedingRatePercent'] as num?)?.toDouble() ?? feedingRate;
          found = true;
          break;
        }
      }
      if (!found) {
        feedingRate = (stages.last['feedingRatePercent'] as num?)?.toDouble() ?? feedingRate;
      }
    }

    final total = count * avgWeight * (feedingRate / 100);
    setState(() => _totalFeedGrams = total);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appName)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.searchSpecies),
            const SizedBox(height: 8),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(hintText: l10n.typeToSearch),
              onChanged: _onSearchChanged,
            ),
            if (_suggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 150,
                child: Card(
                  child: ListView.builder(
                    itemCount: _suggestions.length,
                    itemBuilder: (context, i) {
                      final s = _suggestions[i] as Map<String, dynamic>;
                      final title = l10n.localeName.contains('km') ? (s['nameKm'] ?? s['nameEn']) : (s['nameEn'] ?? s['nameKm']);
                      return ListTile(
                        title: Text(title.toString()),
                        subtitle: Text((s['aliases'] as List<dynamic>?)?.join(', ') ?? ''),
                        onTap: () => _selectSpecies(s),
                      );
                    },
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(l10n.fishCount),
            const SizedBox(height: 8),
            TextField(controller: _countController, keyboardType: TextInputType.number, decoration: InputDecoration(hintText: l10n.enterNumberOfFish)),
            const SizedBox(height: 16),
            Text(l10n.stockingDateOptional),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: Text(_stockingDate != null ? _stockingDate!.toLocal().toString().split(' ')[0] : l10n.notSet)),
              ElevatedButton(onPressed: _pickDate, child: Text(l10n.pickDate)),
            ]),
            const SizedBox(height: 16),
            Text(l10n.avgWeightPerFish),
            const SizedBox(height: 8),
            TextField(controller: _weightController, keyboardType: TextInputType.number, decoration: InputDecoration(hintText: l10n.eg50)),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ElevatedButton(onPressed: _calculate, child: Text(l10n.calculate))),
            ]),
            const SizedBox(height: 20),
            if (_totalFeedGrams != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(l10n.results, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('${l10n.totalDailyFeed} : ${(_totalFeedGrams! / 1000).toStringAsFixed(3)} kg'),
                    const SizedBox(height: 8),
                    Text('${l10n.perFeed3x} : ${(_totalFeedGrams! / 3 / 1000).toStringAsFixed(3)} kg'),
                    const SizedBox(height: 8),
                    Text('${l10n.monthlyBudget} : ${(_totalFeedGrams! * 30 / 1000).toStringAsFixed(3)} kg'),
                    const SizedBox(height: 8),
                    Text('${l10n.recommendedSchedule}: ${[l10n.morningSchedule, l10n.middaySchedule, l10n.eveningSchedule].join(', ')}'),
                  ]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
