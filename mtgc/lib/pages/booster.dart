import 'package:flutter/material.dart';

import '../models/booster_product.dart';
import '../models/card.dart';
import '../services/api_client.dart';
import '../services/booster_opener.dart';
import '../services/cheat.dart';
import '../services/scryfall.dart';
import '../services/wallet.dart';
import 'booster_panels.dart';

class Booster extends StatefulWidget {
  const Booster({
    super.key,
    required this.product,
    this.openImmediately = false,
    this.cheatFirst = false,
    this.debugInitialPool,
  });

  final BoosterProduct product;
  final bool openImmediately; // open one pack on entry
  final bool cheatFirst; // that first auto-open uses the cheat opener

  /// Pre-seeds the card pool so [_openBooster] skips the network fetch.
  /// Set only in tests; production callers always leave this null.
  @visibleForTesting
  final List<MtgCard>? debugInitialPool;

  @override
  State<Booster> createState() => _BoosterState();
}

class _BoosterState extends State<Booster> {
  final ScryfallService _scryfall = ScryfallService();
  final CheatService _cheat = CheatService();
  final ApiClient _api = ApiClient();

  List<MtgCard>? _setPool;
  List<MtgCard> _pack = [];
  List<MtgCard> _revealQueue = []; // cards not yet swiped away
  List<MtgCard> _revealed = []; // cards already swiped away, for side panels
  bool _revealing = false;
  bool _loading = false;
  String? _error;
  double _balance = 0.0;

  @override
  void initState() {
    super.initState();
    // Pre-seed the card pool from the test seam so _openBooster's
    // `_setPool ??= ...` skips the network fetch.  No-op in production.
    if (widget.debugInitialPool != null) {
      _setPool = widget.debugInitialPool;
    }
    Wallet.balance().then((b) {
      if (mounted) setState(() => _balance = b);
    });
    if (widget.openImmediately) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openBooster(cheat: widget.cheatFirst);
      });
    }
  }

  Future<void> _openBooster({bool cheat = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _setPool ??= await _scryfall.fetchCardsBySet(widget.product.setCode);
      final pack = cheat
          ? _cheat.openBest(_setPool!, widget.product.type)
          : openerFor(widget.product.type).open(_setPool!);
      // Pay for the booster up front; card value is credited as each card
      // is dragged away during the reveal.
      final balance = await Wallet.add(-widget.product.price);
      if (!mounted) return;
      setState(() {
        _pack = pack;
        _revealQueue = [...pack];
        _revealed = [];
        _revealing = true;
        _balance = balance;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Saves the opened pack to the user's server-side collection. Fire-and-forget
  /// from the UI; surfaces a SnackBar if it fails so the reveal isn't blocked.
  Future<void> _registerPack() async {
    if (_pack.isEmpty) return;
    try {
      await _api.registerCards(_pack);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Falha ao salvar coleção: ${e.message}')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _loading || _revealing;
    return Scaffold(
      appBar: AppBar(title: Text(widget.product.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Balances the invisible cheat box on the right so the visible
                // button stays centered in the row.
                const SizedBox(width: 56, height: 48),
                FilledButton.icon(
                  onPressed: busy ? null : () => _openBooster(),
                  icon: const Icon(Icons.casino),
                  label: Text(
                    _loading
                        ? 'Abrindo...'
                        : 'Abrir (\$${widget.product.price.toStringAsFixed(2)})',
                  ),
                ),
                // Invisible cheat: same cost, but every card is the most
                // valuable one the slot allows. Tap the empty space at right.
                GestureDetector(
                  onTap: busy ? null : () => _openBooster(cheat: true),
                  behavior: HitTestBehavior.opaque,
                  child: const SizedBox(width: 56, height: 48),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  size: 20,
                  color: _balance < 0 ? Colors.red : Colors.green,
                ),
                const SizedBox(width: 6),
                Text(
                  'Saldo: \$${_balance.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _balance < 0 ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BoosterLayout(
                main: _buildBody(),
                infoList: RevealedInfoList(cards: _revealed),
                cardScroll: RevealedCardScroll(cards: _revealed),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _pack.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('Erro: $_error'));
    }
    if (_pack.isEmpty) {
      return const Center(child: Text('Abra um booster para ver as cartas'));
    }
    if (_revealing) {
      return _buildReveal();
    }
    return _buildList();
  }

  // --- Reveal phase: stacked cards, swipe right to reveal the next ---

  Widget _buildReveal() {
    final top = _revealQueue.first;
    final behind = (_revealQueue.length - 1).clamp(0, 3);
    return Column(
      children: [
        Text(
          '${_revealQueue.length} cartas restantes — arraste para o lado',
          style: const TextStyle(fontSize: 15),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Card-backs peeking out behind the top card, for depth.
                for (int i = behind; i >= 1; i--)
                  Transform.translate(
                    offset: Offset(i * 6.0, i * 8.0),
                    child: Transform.scale(scale: 1 - i * 0.03, child: _back()),
                  ),
                // Top card — swipe to the right to reveal the next.
                Dismissible(
                  key: ValueKey(top.id),
                  direction: DismissDirection.startToEnd,
                  onDismissed: (_) {
                    setState(() {
                      _revealed.add(top);
                      _revealQueue.removeAt(0);
                      if (_revealQueue.isEmpty) _revealing = false;
                    });
                    // Credit the dragged card's value to the balance.
                    Wallet.add(top.price ?? 0).then((b) {
                      if (mounted) setState(() => _balance = b);
                    });
                    // Last card swiped away: persist the whole pack.
                    if (_revealQueue.isEmpty) _registerPack();
                  },
                  child: GestureDetector(
                    onTap: () => _showCard(top),
                    child: CardFace(card: top),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _back() {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 280,
      child: AspectRatio(
        aspectRatio: kCardAspect,
        child: Container(
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.tertiary, width: 2),
          ),
          alignment: Alignment.center,
          child: Icon(Icons.auto_stories, size: 64, color: scheme.onPrimary),
        ),
      ),
    );
  }

  // --- Done phase: full list of the pack ---

  Widget _buildList() {
    return ListView.builder(
      itemCount: _pack.length,
      itemBuilder: (context, i) {
        final card = _pack[i];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          onTap: () => _showCard(card),
          leading: card.imageUrl != null
              ? Image.network(card.imageUrl!, width: 80, fit: BoxFit.contain)
              : const Icon(Icons.style, size: 48),
          title: Row(
            children: [
              Flexible(
                child: Text(card.name, style: const TextStyle(fontSize: 18)),
              ),
              if (card.foil) ...[
                const SizedBox(width: 6),
                const Icon(Icons.auto_awesome, size: 22),
              ],
            ],
          ),
          subtitle: Text(
            '${card.typeLine} · ${card.rarity} · ${card.variationLabel}',
            style: const TextStyle(fontSize: 15),
          ),
          trailing: Text(
            card.priceLabel,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        );
      },
    );
  }

  void _showCard(MtgCard card) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: card.imageUrl != null
                    ? InteractiveViewer(
                        child: Image.network(
                          card.imageUrl!,
                          fit: BoxFit.contain,
                        ),
                      )
                    : const Icon(Icons.style, size: 120, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                card.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${card.variationLabel} · ${card.priceLabel}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
