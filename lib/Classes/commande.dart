class Commande {
  String raisonSociale, reference, vendeur, lastModified, cleEtatEffet, printCount;
  int time;

  Commande({
    required this.raisonSociale,
    required this.cleEtatEffet,
    required this.reference,
    required this.vendeur,
    required this.printCount,
    required this.lastModified,
    this.time = 0,
  });

  factory Commande.fromJSON(Map<String, dynamic> json) {
    Commande commande = Commande(
        raisonSociale: json["RaisonSociale"],
        cleEtatEffet: json["CleEtatEffet"],
        reference: json["Reference"],
        vendeur: json["CleUser"],
        printCount: json["PrintCount"],
        lastModified: json["LastModified"],
        time: currentTime.difference(DateTime.parse(json["LastModified"])).inMinutes);
    if (commande.cleEtatEffet == '1') isAprepare = true;
    return commande;
  }
}

bool isAprepare = false;
DateTime currentTime = DateTime.now();
int duration = 10;
var vendeurs = {};
