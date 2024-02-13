import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:commande/Classes/commande.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
  doWhenWindowReady(() {
    const initialSize = Size(1800, 950);
    appWindow.minSize = initialSize;
    appWindow.title = "Commande";
    appWindow.maximize();
    appWindow.show();
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  void loadVendeurs() async {
    vendeurs.clear();
    var res = await http.post(Uri.parse('http://10.10.10.5:8081/test/php/vendeurs.php'));

    if (res.statusCode == 200) {
      var data = json.decode(res.body);
      vendeurs = data['data'];
      currentTime = DateTime.parse(data['time']);
      firstTime = currentTime;
      duration = data['duration'];
    }
  }

  @override
  Widget build(BuildContext context) {
    loadVendeurs();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Roboto'),
      home: Scaffold(
        body: Column(
          children: [
            const Expanded(
              flex: 15,
              child: DataTable(),
            ),
            bottomWidget(),
          ],
        ),
      ),
    );
  }

  Widget bottomWidget() {
    return Expanded(
      child: Container(
        color: const Color(0xff195c79),
        child: Row(
          children: [
            const Spacer(),
            Row(
              children: [
                Image.asset('assets/clock.png'),
                const SizedBox(width: 16.0),
                const CurrentTime(),
              ],
            ),
            const Spacer(flex: 2),
            Image.asset('assets/logo.jpg'),
            const Spacer(flex: 2),
            Row(
              children: [
                Image.asset('assets/date.png'),
                const SizedBox(width: 16.0),
                Text(
                  DateFormat('dd-MM-yyyy').format(firstTime),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w500,
                  ),
                )
              ],
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class DataTable extends StatefulWidget {
  const DataTable({super.key});

  @override
  State<DataTable> createState() => _DataTableState();
}

class _DataTableState extends State<DataTable> {
  bool isLoading = false, isError = false;
  dynamic data;
  List<Commande> commandesBrut = [];
  final audioPlayer = AudioPlayer();

  void alertPlayer() async {
    final player = AudioCache(prefix: 'assets/');
    final url = await player.load('alert.mp3');
    audioPlayer.setUrl(url.path, isLocal: true);
    audioPlayer.resume();
  }

  void restart() =>
      Navigator.pushReplacement(context, MaterialPageRoute<void>(builder: (BuildContext context) => const MyApp()));

  void loaddata() async {
    while (true) {
      if (currentTime.day != firstTime.day) restart();

      isLoading = true;
      isError = false;
      isAprepare = false;
      commandesBrut.clear();

      var res = await http.post(Uri.parse('http://10.10.10.5:8081/test/php/cmc.php'));

      if (res.statusCode == 200) {
        data = json.decode(res.body);
        if (data == "error") {
          setState(() {
            isLoading = false;
            isError = true;
          });
        } else {
          commandesBrut = List<Commande>.from(data.map((i) => Commande.fromJSON(i)));
          setState(() => isLoading = false);
        }
        await Future.delayed(Duration(seconds: duration));
      }
    }
  }

  @override
  void initState() {
    super.initState();

    loaddata();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isAprepare ? Colors.red : const Color(0xff042434),
      //check if data is loaded, if loaded then show datalist on child
      child: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : isError
              ? const Center(
                  child: Text(
                    'Erreur!!!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : datalist(),
    );
  }

  Widget datalist() {
    List<Commande> commandes = [];
    for (var element in commandesBrut) {
      // A PREPARER
      if (element.cleEtatEffet == '1') commandes.add(element);
    }
    //alert notefication when there is A preparer commande
    if (isAprepare) {
      alertPlayer();
    }
    for (var element in commandesBrut) {
      // A PREPARER SPECIAL
      if (element.cleEtatEffet == '34') commandes.add(element);
    }
    for (var element in commandesBrut) {
      // En Cours
      if (element.cleEtatEffet == '2') commandes.add(element);
    }
    for (var element in commandesBrut) {
      // Produit Showroom
      if (element.cleEtatEffet == '63') commandes.add(element);
    }
    for (var element in commandesBrut) {
      // PRETE
      if (element.cleEtatEffet == '3') commandes.add(element);
    }
    if (commandes.isEmpty) {
      return const Center(
        child: Text(
          'Liste Vide',
          style: TextStyle(
            color: Colors.white,
            fontSize: 38,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    } else {
      // const
      return SingleChildScrollView(
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(4),
            1: FlexColumnWidth(2),
            2: FlexColumnWidth(1),
            3: FlexColumnWidth(1),
          },
          border: TableBorder.all(
            color: Colors.grey,
            width: 0.3,
          ),
          children: [
            TableRow(
                decoration: const BoxDecoration(
                  color: Color(0xffac5c04),
                ),
                children: [
                  headerCell('Client'),
                  headerCell('Etat de commande'),
                  headerCell('Reference'),
                  headerCell('Vendeur'),
                ]),
            ...commandes
                .map((commande) => TableRow(children: [
                      bodyCell(commande.raisonSociale, alignment: Alignment.centerLeft),
                      commande.cleEtatEffet == '1'
                          ? Container(
                              color: Colors.red[900],
                              child: bodyCell(
                                'A préparer        ${commande.time == 0 ? '<1' : commande.time} min',
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          : commande.cleEtatEffet == '34'
                              ? Container(
                                  color: Colors.orange[700],
                                  child: bodyCell(
                                    'A préparer',
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              : commande.cleEtatEffet == '2'
                                  ? Container(
                                      color: const Color(0xffebd803),
                                      child: bodyCell(
                                        'En cours        ${commande.time == 0 ? '<1' : commande.time} min',
                                        textColor: Colors.black,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    )
                                  : commande.cleEtatEffet == '63'
                                      ? Container(
                                          color: const Color(0xff00beff),
                                          child: bodyCell(
                                            'Showroom        ${commande.time == 0 ? '<1' : commande.time} min',
                                            textColor: Colors.black,
                                            fontSize: 24,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        )
                                      : Container(
                                          color: Colors.green[700],
                                          child: bodyCell(
                                            'Prete        ${commande.time == 0 ? '<1' : commande.time} min',
                                            fontSize: 24,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                      bodyCell(commande.reference),
                      bodyCell(vendeurs[commande.vendeur.toString()] ?? commande.vendeur),
                    ]))
                .toList(),
          ],
        ),
      );
    }
  }

  Widget headerCell(String txt) {
    return SizedBox(
      height: 50,
      child: Center(
        child: Text(
          txt,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget bodyCell(
    String txt, {
    Color textColor = Colors.white,
    double fontSize = 22,
    FontWeight fontWeight = FontWeight.normal,
    Alignment alignment = Alignment.center,
  }) {
    return Container(
      alignment: alignment,
      height: 40,
      padding: const EdgeInsets.only(left: 8.0),
      child: Text(
        txt,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ),
    );
  }
}

class CurrentTime extends StatefulWidget {
  const CurrentTime({super.key});

  @override
  State<CurrentTime> createState() => _CurrentTimeState();
}

class _CurrentTimeState extends State<CurrentTime> {
  @override
  void initState() {
    Timer.periodic(const Duration(seconds: 1),
        (Timer t) => setState(() => currentTime = currentTime.add(const Duration(seconds: 1))));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      DateFormat('HH:mm:ss').format(currentTime),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 38,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
