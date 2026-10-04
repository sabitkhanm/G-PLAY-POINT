import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_controller.dart';
import '../../data/models.dart';

class PlayerFormScreen extends StatefulWidget {
  const PlayerFormScreen({super.key});
  @override State<PlayerFormScreen> createState() => _PlayerFormScreenState();
}
class _PlayerFormScreenState extends State<PlayerFormScreen> {
  final name = TextEditingController(); final phone = TextEditingController(); final email = TextEditingController(); final notes = TextEditingController();
  bool saving = false;
  @override void dispose(){name.dispose();phone.dispose();email.dispose();notes.dispose();super.dispose();}
  @override Widget build(BuildContext context){
    final app = context.watch<AppController>(); final s=AppStrings(app.bangla);
    return Scaffold(appBar: AppBar(title: Text(s.addPlayer)), body: ListView(padding: const EdgeInsets.all(16), children:[
      _field(s.name,name,CupertinoIcons.person), const SizedBox(height:12),
      _field(s.phone,phone,CupertinoIcons.phone), const SizedBox(height:12),
      _field(s.email,email,CupertinoIcons.mail), const SizedBox(height:12),
      _field(s.notes,notes,CupertinoIcons.pencil), const SizedBox(height:24),
      FilledButton(onPressed:saving?null:() async {if(name.text.trim().isEmpty)return; setState(()=>saving=true); final now=DateTime.now(); await app.db.insertPlayer(Player(name:name.text.trim(),phone:phone.text.trim(),email:email.text.trim(),notes:notes.text.trim(),createdAt:now,updatedAt:now)); await app.refreshSummary(); if(mounted)Navigator.pop(context,true);}, child: saving?const SizedBox(height:22,width:22,child:CircularProgressIndicator(strokeWidth:2)):Text(s.save)),
    ]));
  }
  Widget _field(String label,TextEditingController c,IconData icon)=>TextField(controller:c,decoration:InputDecoration(labelText:label,prefixIcon:Icon(icon),border:OutlineInputBorder(borderRadius:BorderRadius.circular(18))));
}
