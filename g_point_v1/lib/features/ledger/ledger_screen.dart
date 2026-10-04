import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/app_controller.dart';
import '../../data/models.dart';

class LedgerScreen extends StatefulWidget { const LedgerScreen({super.key}); @override State<LedgerScreen> createState()=>_LedgerScreenState(); }
class _LedgerScreenState extends State<LedgerScreen>{
  @override Widget build(BuildContext context){
    final app=context.watch<AppController>(); final s=AppStrings(app.bangla);
    return FutureBuilder<List<Player>>(future:app.db.getPlayers(),builder:(context,p){final players=p.data??const <Player>[]; return ListView(padding:const EdgeInsets.fromLTRB(16,10,16,110),children:[Text(s.ledger,style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w800)),const SizedBox(height:12),...players.map((pl)=>FutureBuilder<List<LedgerEntry>>(future:app.db.getLedger(pl.id!),builder:(context,l){final items=(l.data??const <LedgerEntry>[]).take(5).toList(); if(items.isEmpty)return const SizedBox.shrink(); return Card(child:ExpansionTile(title:Text(pl.name,style:const TextStyle(fontWeight:FontWeight.w800)),subtitle:Text('${pl.points} pts'),children:items.map((e)=>ListTile(dense:true,title:Text('${e.type} • ${e.points}'),subtitle:Text(DateFormat('dd MMM yyyy, hh:mm a').format(e.createdAt)))).toList()));})),if(players.every((p)=>p.points==0))Padding(padding:const EdgeInsets.all(24),child:Center(child:Text(s.noData))) ]);}
}
