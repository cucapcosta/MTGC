import 'package:flutter/material.dart';

import '../models/booster_product.dart';
import 'booster.dart';

class BoosterSelection extends StatefulWidget {
  const BoosterSelection({super.key});

  @override
  State<BoosterSelection> createState() => _BoosterSelectionState();
}

class _BoosterSelectionState extends State<BoosterSelection> {
  final PageController _controller = PageController(viewportFraction: 0.78);
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _open(BoosterProduct product, {bool cheat = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Booster(
          product: product,
          openImmediately: true,
          cheatFirst: cheat,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = boosterCatalog[_index];
    return Scaffold(
      appBar: AppBar(title: const Text('Escolher Booster')),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: boosterCatalog.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) => _BoosterArt(product: boosterCatalog[i]),
            ),
          ),
          const SizedBox(height: 8),
          // Page dots.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < boosterCatalog.length; i++)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _index
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            product.name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: () => _open(product),
                icon: const Icon(Icons.shopping_cart),
                label: Text('Comprar (\$${product.price.toStringAsFixed(2)})'),
              ),
              // Invisible cheat: same product, opens a guaranteed-best pack.
              GestureDetector(
                onTap: () => _open(product, cheat: true),
                behavior: HitTestBehavior.opaque,
                child: const SizedBox(width: 56, height: 48),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _BoosterArt extends StatelessWidget {
  const _BoosterArt({required this.product});

  final BoosterProduct product;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          product.art,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stack) => Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(24),
            child: Text(
              product.name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}
