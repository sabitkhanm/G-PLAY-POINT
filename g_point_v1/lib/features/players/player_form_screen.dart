import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_controller.dart';
import '../../data/models.dart';

class PlayerFormScreen extends StatefulWidget {
  final Player? player;

  const PlayerFormScreen({
    super.key,
    this.player,
  });

  bool get isEdit => player != null;

  @override
  State<PlayerFormScreen> createState() => _PlayerFormScreenState();
}

class _PlayerFormScreenState extends State<PlayerFormScreen> {
  late final TextEditingController name;
  late final TextEditingController phone;
  late final TextEditingController email;
  late final TextEditingController notes;

  bool saving = false;

  @override
  void initState() {
    super.initState();

    final player = widget.player;

    name = TextEditingController(text: player?.name ?? '');
    phone = TextEditingController(text: player?.phone ?? '');
    email = TextEditingController(text: player?.email ?? '');
    notes = TextEditingController(text: player?.notes ?? '');
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    email.dispose();
    notes.dispose();
    super.dispose();
  }

  Future<void> _save(AppController app, AppStrings s) async {
    FocusScope.of(context).unfocus();

    final playerName = name.text.trim();

    if (playerName.isEmpty) {
      _showError(s, s.name);
      return;
    }

    setState(() => saving = true);

    try {
      final now = DateTime.now();

      if (widget.isEdit) {
        final old = widget.player!;

        final updated = Player(
          id: old.id,
          name: playerName,
          phone: phone.text.trim(),
          email: email.text.trim(),
          points: old.points,
          notes: notes.text.trim(),
          createdAt: old.createdAt,
          updatedAt: now,
        );

        await app.db.updatePlayer(updated);
      } else {
        await app.db.insertPlayer(
          Player(
            name: playerName,
            phone: phone.text.trim(),
            email: email.text.trim(),
            points: 0,
            notes: notes.text.trim(),
            createdAt: now,
            updatedAt: now,
          ),
        );
      }

      await app.refreshSummary();

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() => saving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${s.save} failed: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  void _showError(AppStrings s, String field) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$field ${s.bangla ? 'প্রয়োজন' : 'is required'}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final s = AppStrings(app.bangla);

    final title = widget.isEdit
        ? (app.bangla ? 'প্লেয়ার এডিট করুন' : 'Edit Player')
        : s.addPlayer;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _field(
            s.name,
            name,
            CupertinoIcons.person,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),

          _field(
            s.phone,
            phone,
            CupertinoIcons.phone,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),

          _field(
            s.email,
            email,
            CupertinoIcons.mail,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),

          _field(
            s.notes,
            notes,
            CupertinoIcons.pencil,
            maxLines: 4,
          ),
          const SizedBox(height: 24),

          FilledButton(
            onPressed: saving ? null : () => _save(app, s),
            child: saving
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    widget.isEdit
                        ? (app.bangla ? 'আপডেট করুন' : 'Update')
                        : s.save,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}
