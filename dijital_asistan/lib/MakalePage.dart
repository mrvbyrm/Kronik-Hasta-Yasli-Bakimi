import 'package:flutter/material.dart';

class MakalePage extends StatelessWidget {
  const MakalePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor:Color(0xFF94D9C6),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            Image.asset(
              'assets/logo.png', // 💡 Logo buraya eklenecek
              height: 80,
            ),
            const SizedBox(height: 8),
            const Text(
              'INFINITE HEALTH',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                hintText: 'Ara...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(30)),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/hearthHealthy.jpg', // 💡 Görsel burada kullanılacak
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'KENDİNİ SEV SAĞLIKLI BESLEN',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Sağlıklı ve Dengeli Beslenmenin Önemi',
              textAlign: TextAlign.start,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            
            const Text(
              '''
Sağlıklı ve dengeli beslenme, yaşamın her döneminde kritik bir öneme sahiptir, kronik hastalar ve yaşlı bireyler için hayati bir rol oynar. Kronik hastalıklar, genellikle uzun süreli ve karmaşık tedavi süreçleri gerektirir. Bu hastalıkların yönetiminde uygun beslenme, bağışıklık sistemini güçlendirerek komplikasyon risklerini azaltır ve yaşam kalitesini artırır. Özellikle diyabet, hipertansiyon, kalp hastalıkları gibi durumlarda, doğru bir beslenme planı, hastalığın seyrini olumlu yönde etkileyebilir ve ilaç gereksinimini azaltabilir.

Yaşlı bireylerde ise, metabolizmanın yavaşlaması, kas kaybı, kemik erimesi ve bağışıklık sisteminin zayıflaması gibi doğal süreçler beslenme ihtiyacını daha da kritik hale getirir. Dengeli bir diyet, yaşlanan enerji seviyelerini korumalarına, zihinsel sağlığını desteklemelerine ve günlük aktivitelerini daha kolay yerine getirmelerine yardımcı olur. Aynı zamanda, dengeli bir beslenme planı, aşırı besinlerin kemik yoğunluğunu artırabilir ve düşme veya kırık riskini azaltabilir.
              ''',
              textAlign: TextAlign.justify,
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/foodHealthy.jpg', // 💡 Görsel burada kullanılacak
              ),
            ),

            
const SizedBox(height: 12),
const Text(
              'Dengeli Bir Tabağın Oluşturulması',
              textAlign: TextAlign.start,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '''
Dengeli bir tabak, vücudun ihtiyaç duyduğu temel besin gruplarını uygun oranlarda içermelidir. MyPlate modeli gibi yaklaşımlar, sağlıklı bir tabağın nasıl oluşturulacağına dair pratik bir rehber sunar. Bu model, tabağın dört ana bölümden oluşmasını önerir: sebzeler, meyveler, tam tahıllar ve protein kaynakları.
\n1. Sebzeler ve Meyveler: Tabağın yarısı renkli sebzeler ve meyvelerden oluşmalıdır. Bu gruplar, vitaminler, mineraller, lif ve antioksidanlar açısından zengindir. Örneğin, brokoli, ıspanak gibi koyu yeşil sebzeler ve portakal, elma gibi meyveler tercih edilmelidir.
\n2. Tam Tahıllar: Tabağın yaklaşık dörtte biri tam tahıllardan oluşmalıdır. Tam buğday ekmeği, kahverengi pirinç veya kinoa gibi seçenekler, uzun süre enerji sağlayan kompleks karbonhidratlar içerir.
\n3. Protein Kaynakları: Tabağın diğer çeyreği protein kaynaklarına ayrılmalıdır. Balık, tavuk, az yağlı kırmızı et veya bitkisel protein kaynakları (örneğin, mercimek, nohut, tofu) tercih edilebilir. Yaşlı bireyler için proteinin, kas kaybını önlemede özel bir önemi vardır.
\n4. Sağlıklı Yağlar ve Süt Ürünleri: Zeytinyağı, avokado gibi sağlıklı yağlar dengeli bir tabakta yer alabilir. Ayrıca, yoğurt veya az yağlı süt gibi kalsiyum içeren besinler kemik sağlığını destekler.
\nDengeli bir tabağı oluştururken, porsiyon kontrolüne dikkat etmek de önemlidir. Aşırı tuz, şeker ve doymuş yağ tüketiminden kaçınılmalıdır. Ayrıca, yeterli su alımı sağlanarak vücudun hidrasyonu desteklenmelidir.
              ''',
              textAlign: TextAlign.justify,
              style: TextStyle(fontSize: 16, height: 1.5),
            ),



            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/balancedMeal.jpg', // 💡 Görsel burada kullanılacak
              ),
            ),

            const SizedBox(height: 12),
            const Text(
              'Sonuç',
              textAlign: TextAlign.start,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '''
Kronik hastalar ve yaşlı bireyler için sağlıklı ve dengeli beslenme, yalnızca fiziksel sağlığı desteklemekle kalmaz, aynı zamanda genel yaşam kalitesini artırır. Uygun bir beslenme planı oluşturulurken bireyin sağlık durumu, yaş ve enerji ihtiyacı gibi faktörler göz önünde bulundurulmalıdır. Dengeli bir tabak modeli, bu süreçte rehberlik sağlayarak daha bilinçli beslenme alışkanlıklarının oluşmasına yardımcı olur.
              ''',
              textAlign: TextAlign.justify,
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}