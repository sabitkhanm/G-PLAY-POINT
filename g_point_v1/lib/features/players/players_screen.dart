import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_controller.dart';
import '../../core/motion/page_transitions.dart';
import '../../core/widgets/premium_card.dart';
import '../../data/models.dart';
import 'player_detail_screen.dart';
import 'player_form_screen.dart';

class PlayersScreen extends StatefulWidget {
  const PlayersScreen({super.key});
  @override State<PlayersScreen> createState() => _PlayersScreenState();
}
class _PlayersScreenState extends State<PlayersScreen> {
  String q = '';
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final s = AppStrings(app.bangla);
    return FutureBuilder<List<Player>>(
      future: app.db.getPlayers(query: q),
      builder: (context, snapshot) {
        final players = snapshot.data ?? const <Player>[];
        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              await Navigator.of(context).push(IosPageRoute(page: const PlayerFormScreen()));
              if (mounted) setState(() {});
            },
            icon: const Icon(CupertinoIcons.person_add),
            label: Text(s.addPlayer),
          ),
          body: Column(children: [
            Padding(padding: const EdgeInsets.fromLTRB(16, 10, 16, 8), child: TextField(
              onChanged: (v) => setState(() => q = v),
              decoration: InputDecoration(hintText: s.search, prefixIcon: const Icon(CupertinoIcons.search), filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none)),
            )),
            Expanded(child: snapshot.connectionState == ConnectionState.waiting ? const Center(child: CircularProgressIndicator.adaptive()) : players.isEmpty ? Center(child: Text(s.noData)) : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 110),
              itemCount: players.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _PlayerTile(player: players[index], s: s),
            )),
          ]),
        );
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }
}

class _PlayerTile extends StatelessWidget {
  final Player player; final AppStrings s;
  const _PlayerTile({required this.player, required this.s});
  @override Widget build(BuildContext context) => PremiumCard(onTap: () => Navigator.of(context).push(IosPageRoute(page: PlayerDetailScreen(playerId: player.id!))), child: Row(children: [
    CircleAvatar(radius: 25, child: Text(player.name.trim().isEmpty ? '?' : player.name.trim()[0].toUpperCase())),
    const SizedBox(width: 14),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(player.name, style: const TextStyle(fontWeight: FontWeight.w800)), if (player.email.isNotEmpty) Text(player.email, maxLines: 1, overflow: TextOverflow.ellipsis), if (player.phone.isNotEmpty) Text(player.phone)])),
    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('${player.points}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 19)), Text(s.bn ? 'পয়েন্ট' : 'pts')]),
  ]));
}
