import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MaterialApp(
    home: HomePage(),
    debugShowCheckedModeBanner: false,
  ));
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
      );

      if (image != null) {
        if (!mounted) return;
        Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AnalysisPage(imageFile: File(image.path)))
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("X-Ray AI Analiz"), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.medical_information, size: 100, color: Colors.blue),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: const Text("Galeriden Röntgen Seç"),
              style: ElevatedButton.styleFrom(minimumSize: const Size(250, 60)),
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text("Kameradan Röntgen Çek"),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(250, 60)
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnalysisPage extends StatefulWidget {
  final File imageFile;
  const AnalysisPage({super.key, required this.imageFile});
  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  bool _isLoading = false;
  Map<String, dynamic>? _res;

  @override
  void initState() {
    super.initState();
    _analyze();
  }

  Future<void> _analyze() async {
    setState(() => _isLoading = true);
    try {
      var req = http.MultipartRequest('POST', Uri.parse('https://hsherlock.pythonanywhere.com/analyze'));
      req.files.add(await http.MultipartFile.fromPath('image', widget.imageFile.path));
      var responseStream = await req.send();
      var res = await http.Response.fromStream(responseStream);
      if (res.statusCode == 200) {
        setState(() => _res = json.decode(res.body));
      } else {
        throw "Sunucu Hatası: ${res.statusCode}";
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(title: const Text("Teknik Analiz Paneli")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _res == null
          ? const Center(child: Text("Veri alınamadı."))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildCard("Orijinal Röntgen", Image.file(widget.imageFile, height: 250, width: double.infinity, fit: BoxFit.contain), _res!['original_score'], "100", "1.000", Colors.blue[800]!),
            _buildCard("Histogram Eşitleme", Image.memory(base64Decode(_res!['hist_img_base64']), height: 250, width: double.infinity, fit: BoxFit.contain), _res!['hist_score'], _res!['hist_psnr'], _res!['hist_ssim'], Colors.blueGrey[700]!),
            _buildCard("CLAHE Analizi", Image.memory(base64Decode(_res!['clahe_img_base64']), height: 250, width: double.infinity, fit: BoxFit.contain), _res!['clahe_score'], _res!['clahe_psnr'], _res!['clahe_ssim'], Colors.blueGrey[800]!),
            const SizedBox(height: 20),
            _buildInfoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(String title, Widget imgWidget, dynamic score, dynamic psnr, dynamic ssim, Color headerColor) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 15),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        Container(
            color: headerColor,
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
        ),
        Container(color: Colors.black, child: imgWidget),
        Padding(
          padding: const EdgeInsets.all(15),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _metricItem("PSNR", "$psnr dB"),
            _metricItem("SSIM", "$ssim"),
            _metricItem("AI Tahmini", "%$score"),
          ]),
        ),
      ]),
    );
  }

  Widget _metricItem(String label, String val) {
    return Column(children: [
      Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
      Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
    ]);
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.blue.withOpacity(0.2))
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("Teknik Analiz Rehberi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
        const Divider(),
        _infoText("• PSNR (dB): Görüntü kalitesini ölçer. Değer ne kadar yüksekse, işlem sonrası görüntü o kadar az bozulmuştur."),
        _infoText("• SSIM: Yapısal benzerlik endeksidir. 1'e yakın olması, kemik ve doku yapısının orijinalle aynı kaldığını ispatlar."),
        _infoText("• Tahmin (%): Derin öğrenme modelinin ilgili görüntü üzerinde saptadığı Pneumonia (Zatürre) olasılığıdır."),
      ]),
    );
  }

  Widget _infoText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(text, style: const TextStyle(fontSize: 13)),
    );
  }
}