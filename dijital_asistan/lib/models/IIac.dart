class Ilac {
  final int id;
  final String ilacAd;
  final DateTime baslangicTarih;
  final DateTime bitisTarih;
  final String siklik;
  final String hatirlatmaSaati;
  final bool alindiMi;

  Ilac({
    required this.id,
    required this.ilacAd,
    required this.baslangicTarih,
    required this.bitisTarih,
    required this.siklik,
    required this.hatirlatmaSaati,
    required this.alindiMi,
  });

  factory Ilac.fromJson(Map<String, dynamic> json) {
    return Ilac(
      id: json['id'],
      ilacAd: json['ilacAd'],
      baslangicTarih: DateTime.parse(json['baslangicTarih']),
      bitisTarih: DateTime.parse(json['bitisTarih']),
      siklik: json['siklik'],
      hatirlatmaSaati: json['hatirlatmaSaati'],
      alindiMi: json['alindiMi'],
    );
  }
}