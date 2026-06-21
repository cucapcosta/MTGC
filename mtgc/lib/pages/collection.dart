import 'package:flutter/material.dart';

import '../models/collection_entry.dart';
import '../services/api_client.dart';
import '../ui/card_detail.dart';
import '../ui/layout_metrics.dart';
import 'booster_panels.dart' show CardFace;

class Collection extends StatefulWidget {
  const Collection({super.key});

  @override
  State<Collection> createState() => _CollectionState();
}

class _CollectionState extends State<Collection> {
  final ApiClient _api = ApiClient();

  List<CollectionEntry>? _entries;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final entries = await _api.fetchCollection();
      if (!mounted) return;
      setState(() => _entries = entries);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e is ApiException ? e.message : 'Erro inesperado.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Coleção')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Erro: $_error', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _load,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }
    final entries = _entries ?? const [];
    if (entries.isEmpty) {
      return const Center(child: Text('Nenhuma carta na coleção'));
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = columnsFor(modeFor(constraints.maxWidth));
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            childAspectRatio: kCardAspect, // CardFace also uses kCardAspect — keep in sync
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: entries.length,
          itemBuilder: (context, i) => _CollectionCard(entry: entries[i]),
        );
      },
    );
  }
}

class _CollectionCard extends StatelessWidget {
  const _CollectionCard({required this.entry});

  final CollectionEntry entry;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          showCardDetail(context, entry.card, quantity: entry.quantity),
      child: Stack(
        children: [
          CardFace(card: entry.card, width: double.infinity),
          if (entry.quantity > 1)
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '×${entry.quantity}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
