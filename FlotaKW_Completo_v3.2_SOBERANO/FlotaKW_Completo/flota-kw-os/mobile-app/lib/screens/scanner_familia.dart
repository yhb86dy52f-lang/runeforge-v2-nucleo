import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ScannerFamilia extends StatefulWidget { const ScannerFamilia({super.key}); @override State<ScannerFamilia> createState()=>_ScannerFamiliaState(); }
class _ScannerFamiliaState extends State<ScannerFamilia>{
  Map<String,Map<String,dynamic>> seen={}; bool scanning=false; StreamSubscription? sub;
  final Map<String,String> kwMap={"26435":"KW 749_R","26520":"KW 750_R","25431":"KW 751_R","25961":"KW 752_R","24529":"KW 753_R","24837":"KW 754_R","23806":"KW 755_R","24374":"KW 756_R","25665":"KW 759_R","25203":"KW 761_R"};
  final Map<String,String> tileMap={"BDVA-3358":"TILE 14","BDVA-5366":"TILE 11","BDVA-7011":"TILE 15 KW753 Tag15","BDVA-5277":"TILE 17","BDVA-4393":"TILE NUEVO"};
  String classify(String name,String mac){
    var n=name.toUpperCase(); var m=mac.toUpperCase();
    if(n.startsWith("PB705")) return "PB705";
    if(m.startsWith("C3:00:00:6B")||n.contains("AIIQ")||n.contains("CICLO")||n.startsWith("C3:")) return "CICLOPE";
    if(n.startsWith("BDVA")||n.contains("TILE")) return "TILE";
    if(n.contains("AT11")||n.contains("SAMSARA")||n.startsWith("GD")) return "AT11";
    if(n.contains("APPLE")||n.contains("AIRTAG")) return "APPLE";
    return "UNKNOWN";
  }
  void startScan() async {
    seen.clear(); setState(()=>scanning=true);
    await FlutterBluePlus.startScan(timeout: Duration(seconds: 40));
    sub=FlutterBluePlus.scanResults.listen((results){
      for(var r in results){
        var name=r.device.name; var mac=r.device.remoteId.toString(); var rssi=r.rssi;
        if(mac.isEmpty) continue;
        var type=classify(name,mac);
        var id="\_\"; var suffix=name.contains("-")?name.split("-").last:"";
        var label=kwMap[suffix]??tileMap[name]??name.isNotEmpty?name:mac;
        var imei=type=="PB705"?"7809018077\":mac;
        if(!seen.containsKey(id) || seen[id]!["rssi"]<rssi){
          setState(()=>seen[id]={"type":type,"label":label,"name":name,"mac":mac,"imei":imei,"rssi":rssi,"suffix":suffix});
        }
      }
    });
    await Future.delayed(Duration(seconds: 40)); stopScan();
  }
  void stopScan(){ FlutterBluePlus.stopScan(); sub?.cancel(); setState(()=>scanning=false); }
  Future<void> alta(String codigo,String mac,String imei) async {
    var isR=codigo.endsWith("_R");
    var body={"codigo":codigo,"mac":mac,"tecnico":"Nestor","gps_marca_modelo":isR?imei:"CALAMP"};
    try{ var res=await http.post(Uri.parse("http://10.0.2.2:8000/api/v1/alta"),headers:{"Content-Type":"application/json"},body:jsonEncode(body)); if(res.statusCode==200) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text("ALTA \ OK \"))); }catch(e){ ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text("Error alta: \"))); }
  }
  Color c(String t){ switch(t){ case "PB705": return Color(0xFF00FF88); case "CICLOPE": return Color(0xFF00D4FF); case "TILE": return Color(0xFFFFCC00); case "AT11": return Color(0xFFFF6A00); case "APPLE": return Color(0xFFA0A0A0); default: return Color(0xFF555555);} }
  @override Widget build(BuildContext context){
    return Scaffold(backgroundColor: Color(0xFF060806),appBar: AppBar(title: Text("SCANNER v12 FAMILIA - TODOS SIN NOMBRE",style: TextStyle(fontSize:12,letterSpacing:2)),backgroundColor: Color(0xFF121412)),body: Column(children: [
      Padding(padding: EdgeInsets.all(10),child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00FF88),minimumSize: Size(double.infinity,50)),onPressed: scanning?null:(){ startScan(); },child: Text(scanning?"ESCANEANDO 40s FAMILIA...":"ESCANEAR TODA LA FAMILIA",style: TextStyle(color: Colors.black,fontWeight: FontWeight.w900)))),
      Expanded(child: ListView(children: seen.values.map((d){ return Container(margin: EdgeInsets.symmetric(horizontal:10,vertical:4),decoration: BoxDecoration(color: Color(0xFF121412),border: Border(left: BorderSide(color: c(d["type"]),width: 3)),borderRadius: BorderRadius.circular(12)),child: ListTile(title: Text(d["label"],style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,fontSize:13)),subtitle: Text("\ | \ | IMEI \",style: TextStyle(color: Color(0xFF7A9180),fontSize:9,fontFamily: "monospace")),trailing: Column(mainAxisAlignment: MainAxisAlignment.center,children: [Text("\",style: TextStyle(fontSize:18,fontWeight: FontWeight.w900,color: c(d["type"]))),Text(d["rssi"]>-70?"CERCA":d["rssi"]>-85?"MEDIO":"LEJOS",style: TextStyle(fontSize:9,color: Color(0xFF7A9180))) ]),onTap: (){ var kw=d["label"]; if(kwMap.containsValue(kw)||kw.contains("KW")) alta(kw,d["mac"],d["imei"]); else alta("KW 751_R",d["mac"],d["imei"]); })); }).toList()))
    ]));
  }
}
