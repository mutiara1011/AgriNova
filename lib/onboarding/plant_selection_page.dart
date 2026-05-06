import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/plant_provider.dart';
import '../bottom_nav.dart';
import '../models/commodity.dart';
import '../services/commodity_service.dart';

class PlantSelectionPage extends StatefulWidget {
  const PlantSelectionPage({super.key});

  @override
  State<PlantSelectionPage> createState() => _PlantSelectionPageState();
}

class _PlantSelectionPageState extends State<PlantSelectionPage> {
  Commodity? selectedCommodity;
  DateTime selectedDate = DateTime.now();
  List<Commodity> commodities = [];
  bool isLoading = true;

  final _formKey = GlobalKey<FormState>();
  final CommodityService _commodityService = CommodityService();

  // Controllers for Custom Plant Form
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _phMinCtrl = TextEditingController(text: "5.5");
  final _phMaxCtrl = TextEditingController(text: "6.5");
  final _phIdealCtrl = TextEditingController(text: "6.0");
  final _tdsVegMinCtrl = TextEditingController(text: "500");
  final _tdsVegMaxCtrl = TextEditingController(text: "800");
  final _tdsVegIdealCtrl = TextEditingController(text: "700");
  final _tdsPemMinCtrl = TextEditingController(text: "800");
  final _tdsPemMaxCtrl = TextEditingController(text: "1200");
  final _tdsPemIdealCtrl = TextEditingController(text: "1000");
  final _harvestDaysCtrl = TextEditingController(text: "30");
  final _harvestRangeCtrl = TextEditingController(text: "5");
  File? _customImage;
  bool _saveAsTemplate = false;

  @override
  void initState() {
    super.initState();
    _loadCommodities();
  }

  Future<void> _loadCommodities() async {
    setState(() => isLoading = true);
    final list = await _commodityService.getAllCommodities();
    setState(() {
      commodities = list;
      isLoading = false;
    });
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _customImage = File(image.path);
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _phMinCtrl.dispose();
    _phMaxCtrl.dispose();
    _phIdealCtrl.dispose();
    _tdsVegMinCtrl.dispose();
    _tdsVegMaxCtrl.dispose();
    _tdsVegIdealCtrl.dispose();
    _tdsPemMinCtrl.dispose();
    _tdsPemMaxCtrl.dispose();
    _tdsPemIdealCtrl.dispose();
    _harvestDaysCtrl.dispose();
    _harvestRangeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "MULAI TANAM",
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 0.5),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xff03AF55)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Pilih Komoditas",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  _buildDropdown(),
                  const SizedBox(height: 24),
                  
                  if (selectedCommodity != null && selectedCommodity!.name == "Tanaman Lainnya")
                    _buildCustomPlantForm()
                  else if (selectedCommodity != null)
                    _buildCommodityDetailCard(selectedCommodity!),

                  const SizedBox(height: 32),
                  const Text(
                    "Tanggal Tanam (Pindah Tanam)",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  _buildDatePicker(),
                  const SizedBox(height: 40),
                  _buildStartButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildDropdown() {
    // Add "Tanaman Lainnya" option virtually if not in list
    List<Commodity> dropdownList = List.from(commodities);
    if (!dropdownList.any((c) => c.name == "Tanaman Lainnya")) {
      dropdownList.add(Commodity(
        id: "custom",
        name: "Tanaman Lainnya",
        isCustom: true,
      ));
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Commodity>(
          isExpanded: true,
          value: selectedCommodity,
          hint: const Text("Pilih Sayuran..."),
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xff03AF55)),
          items: dropdownList.map((Commodity commodity) {
            return DropdownMenuItem<Commodity>(
              value: commodity,
              child: Text(
                commodity.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            );
          }).toList(),
          onChanged: (Commodity? newValue) {
            setState(() {
              selectedCommodity = newValue;
            });
          },
        ),
      ),
    );
  }

  Widget _buildCommodityDetailCard(Commodity commodity) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            child: _buildPlantImage(commodity),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  commodity.name,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xff03AF55)),
                ),
                const SizedBox(height: 8),
                Text(
                  commodity.description,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.5),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),
                _buildParameterRow("pH Air", "${commodity.phMin} - ${commodity.phMax}", "Ideal: ${commodity.phIdeal}"),
                const SizedBox(height: 12),
                _buildParameterRow("Nutrisi (Vegetatif)", "${commodity.tdsVegetatifMin.toInt()} - ${commodity.tdsVegetatifMax.toInt()} PPM", "Ideal: ${commodity.tdsVegetatifIdeal} PPM"),
                const SizedBox(height: 12),
                _buildParameterRow("Nutrisi (Pembesaran)", "${commodity.tdsPembesaranMin.toInt()} - ${commodity.tdsPembesaranMax.toInt()} PPM", "Ideal: ${commodity.tdsPembesaranIdeal} PPM"),
                const SizedBox(height: 12),
                _buildParameterRow("Suhu Udara", "${commodity.airTempMin.toInt()} - ${commodity.airTempMax.toInt()} °C", "Ideal: ${commodity.airTempIdeal} °C"),
                const SizedBox(height: 12),
                _buildParameterRow("Suhu Air", "${commodity.waterTempMin.toInt()} - ${commodity.waterTempMax.toInt()} °C", "Ideal: ${commodity.waterTempIdeal} °C"),
                const SizedBox(height: 12),
                _buildParameterRow("Kelembapan", "${commodity.humidityMin.toInt()} - ${commodity.humidityMax.toInt()} %", "Ideal: ${commodity.humidityIdeal} %"),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xff03AF55).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.eco, color: Color(0xff03AF55)),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Estimasi Masa Panen", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          Text(
                            "+- ${commodity.harvestDays} Hari (Range: ${commodity.harvestDays - commodity.harvestRange} - ${commodity.harvestDays + commodity.harvestRange})",
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xff03AF55)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParameterRow(String label, String range, String ideal) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(range, style: const TextStyle(fontWeight: FontWeight.w900)),
            Text(ideal, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        )
      ],
    );
  }

  Widget _buildCustomPlantForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Detail Tanaman Baru", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            
            // Image Picker
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                ),
                child: _customImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_customImage!, fit: BoxFit.cover),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                          SizedBox(height: 8),
                          Text("Pilih Foto Tanaman", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _nameCtrl,
              decoration: _inputDecoration("Nama Tanaman"),
              validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: _inputDecoration("Deskripsi Singkat"),
            ),
            const SizedBox(height: 20),
            const Text("Parameter Hidroponik", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(child: TextFormField(controller: _phMinCtrl, decoration: _inputDecoration("pH Min"), keyboardType: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(child: TextFormField(controller: _phMaxCtrl, decoration: _inputDecoration("pH Max"), keyboardType: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(child: TextFormField(controller: _phIdealCtrl, decoration: _inputDecoration("pH Ideal"), keyboardType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 12),
            const Text("Nutrisi (Vegetatif Awal)", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: TextFormField(controller: _tdsVegMinCtrl, decoration: _inputDecoration("Min PPM"), keyboardType: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(child: TextFormField(controller: _tdsVegMaxCtrl, decoration: _inputDecoration("Max PPM"), keyboardType: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(child: TextFormField(controller: _tdsVegIdealCtrl, decoration: _inputDecoration("Ideal PPM"), keyboardType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 12),
            const Text("Nutrisi (Pembesaran)", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: TextFormField(controller: _tdsPemMinCtrl, decoration: _inputDecoration("Min PPM"), keyboardType: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(child: TextFormField(controller: _tdsPemMaxCtrl, decoration: _inputDecoration("Max PPM"), keyboardType: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(child: TextFormField(controller: _tdsPemIdealCtrl, decoration: _inputDecoration("Ideal PPM"), keyboardType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextFormField(controller: _harvestDaysCtrl, decoration: _inputDecoration("Panen (Hari)"), keyboardType: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(child: TextFormField(controller: _harvestRangeCtrl, decoration: _inputDecoration("+- Range"), keyboardType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _saveAsTemplate,
                  activeColor: const Color(0xff03AF55),
                  onChanged: (v) => setState(() => _saveAsTemplate = v ?? false),
                ),
                const Expanded(
                  child: Text("Simpan sebagai Template untuk digunakan lagi nanti", style: TextStyle(fontSize: 12, color: Colors.grey)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  Widget _buildPlantImage(Commodity commodity) {
    String? assetPath;
    final name = commodity.name.toLowerCase();

    if (name.contains("kangkung")) {
      assetPath = 'assets/images/kangkung.png';
    } else if (name.contains("pakcoy")) {
      assetPath = 'assets/images/pakcoy.png';
    } else if (name.contains("selada")) {
      assetPath = 'assets/images/selada.png';
    }

    if (assetPath != null) {
      return Image.asset(assetPath,
          height: 180, width: double.infinity, fit: BoxFit.cover);
    }

    if (commodity.imagePath.isNotEmpty) {
      if (commodity.imagePath.startsWith('http')) {
        return Image.network(commodity.imagePath,
            height: 180, width: double.infinity, fit: BoxFit.cover);
      } else if (commodity.imagePath.startsWith('assets/')) {
        return Image.asset(commodity.imagePath,
            height: 180, width: double.infinity, fit: BoxFit.cover);
      } else {
        return Image.file(File(commodity.imagePath),
            height: 180, width: double.infinity, fit: BoxFit.cover);
      }
    }

    return Container(
      height: 180,
      width: double.infinity,
      color: Colors.grey.shade200,
      child: const Icon(Icons.image, size: 50, color: Colors.grey),
    );
  }

  Widget _buildDatePicker() {

    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Color(0xff03AF55),
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          setState(() => selectedDate = picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Icon(Icons.calendar_today, color: Color(0xff03AF55)),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff03AF55),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        onPressed: selectedCommodity == null
            ? null
            : () async {
                Commodity? plantToStart = selectedCommodity;

                // If Custom Plant, validate and save if needed
                if (selectedCommodity!.name == "Tanaman Lainnya") {
                  if (!_formKey.currentState!.validate()) return;
                  
                  final newCommodity = Commodity(
                    id: "custom_${DateTime.now().millisecondsSinceEpoch}",
                    name: _nameCtrl.text,
                    description: _descCtrl.text,
                    imagePath: _customImage?.path ?? "",
                    isCustom: true,
                    phMin: double.tryParse(_phMinCtrl.text) ?? 5.5,
                    phMax: double.tryParse(_phMaxCtrl.text) ?? 6.5,
                    phIdeal: _phIdealCtrl.text,
                    tdsVegetatifMin: double.tryParse(_tdsVegMinCtrl.text) ?? 500,
                    tdsVegetatifMax: double.tryParse(_tdsVegMaxCtrl.text) ?? 800,
                    tdsVegetatifIdeal: _tdsVegIdealCtrl.text,
                    tdsPembesaranMin: double.tryParse(_tdsPemMinCtrl.text) ?? 800,
                    tdsPembesaranMax: double.tryParse(_tdsPemMaxCtrl.text) ?? 1200,
                    tdsPembesaranIdeal: _tdsPemIdealCtrl.text,
                    harvestDays: int.tryParse(_harvestDaysCtrl.text) ?? 30,
                    harvestRange: int.tryParse(_harvestRangeCtrl.text) ?? 5,
                  );

                  if (_saveAsTemplate) {
                    await _commodityService.createCommodity(newCommodity);
                  }
                  plantToStart = newCommodity;
                }

                // Start the cycle via PlantProvider
                await context.read<PlantProvider>().startNewCycle(
                      name: plantToStart!.name,
                      startDate: selectedDate,
                      targetPhMin: plantToStart.phMin,
                      targetPhMax: plantToStart.phMax,
                      targetTdsVegetatifMin: plantToStart.tdsVegetatifMin,
                      targetTdsVegetatifMax: plantToStart.tdsVegetatifMax,
                      targetTdsPembesaranMin: plantToStart.tdsPembesaranMin,
                      targetTdsPembesaranMax: plantToStart.tdsPembesaranMax,
                    );
                    
                if (context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const BottomNav()),
                  );
                }
              },
        child: const Text(
          "MULAI MONITORING",
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white, letterSpacing: 1),
        ),
      ),
    );
  }
}
