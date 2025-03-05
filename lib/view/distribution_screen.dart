import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import '../cubits/colleges_cubit.dart';
import '../cubits/distribution_cubit.dart';
import '../cubits/distribution_state.dart';
import '../cubits/stats_cubit.dart';
import '../cubits/stats_state.dart';

class DistributionScreen extends StatefulWidget {
  final DistributionCubit distributionCubit;
  final StatsCubit statsCubit;
  final CollegesCubit collegesCubit;

  const DistributionScreen({
    super.key,
    required this.distributionCubit,
    required this.statsCubit,
    required this.collegesCubit,
  });

  @override
  _DistributionScreenState createState() => _DistributionScreenState();
}

class _DistributionScreenState extends State<DistributionScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "توزيع الأبحاث",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF1E3A8A),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.pink,
            mouseCursor: SystemMouseCursors.click,
            tabs: [
              Tab(text: "الذكور", icon: Icon(Icons.male)),
              Tab(text: "الإناث", icon: Icon(Icons.female)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            DistributionTab(
              gender: "الذكور",
              distributionCubit: widget.distributionCubit,
              statsCubit: widget.statsCubit,
            ),
            DistributionTab(
              gender: "الإناث",
              distributionCubit: widget.distributionCubit,
              statsCubit: widget.statsCubit,
            ),
          ],
        ),
      ),
    );
  }
}

class DistributionTab extends StatefulWidget {
  final String gender;
  final DistributionCubit distributionCubit;
  final StatsCubit statsCubit;

  const DistributionTab({
    super.key,
    required this.gender,
    required this.distributionCubit,
    required this.statsCubit,
  });

  @override
  _DistributionTabState createState() => _DistributionTabState();
}

class _DistributionTabState extends State<DistributionTab> {
  final TextEditingController searchController = TextEditingController();
  List<Map<String, String>> currentDistribution = [];
  List<Map<String, String>> filteredDistribution = [];
  bool isLoading = false;

  Future<void> _distributeResearches(int totalStudents, int totalResearches) async {
    setState(() {
      isLoading = true;
    });

    widget.distributionCubit.distributeResearches(totalStudents, totalResearches, widget.gender);

    await Future.delayed(const Duration(milliseconds: 100));
    final state = widget.distributionCubit.state;
    if (state is DistributionSuccess) {
      setState(() {
        currentDistribution = state.distribution[widget.gender == "الذكور" ? "male" : "female"] ?? [];
        filteredDistribution = currentDistribution;
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم التوزيع بنجاح")));
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("فشل التوزيع، حاول مرة أخرى")));
    }
  }

  Future<void> _resetDistribution() async {
    setState(() {
      isLoading = true;
    });

    widget.distributionCubit.resetDistribution(widget.gender);

    await Future.delayed(const Duration(milliseconds: 100));
    final state = widget.distributionCubit.state;
    if (state is DistributionSuccess) {
      setState(() {
        currentDistribution = state.distribution[widget.gender == "الذكور" ? "male" : "female"] ?? [];
        filteredDistribution = currentDistribution;
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم إعادة تعيين التوزيع بنجاح")));
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("فشل إعادة التعيين، حاول مرة أخرى")));
    }
  }

  Widget _buildSearchField() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: 'ابحث عن طريق المسلسل أو عنوان البحث...',
          prefixIcon: const Icon(Icons.search, color: Colors.blue),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          suffixIcon: searchController.text.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear, color: Colors.grey),
            onPressed: () {
              searchController.clear();
              _onSearchChanged();
            },
          )
              : null,
        ),
        onChanged: (value) => _onSearchChanged(),
      ),
    );
  }

  Future<void> _exportToPdf() async {
    try {
      setState(() {
        isLoading = true;
      });

      final pdf = pw.Document();

      Map<String, List<String>> researchToSerials = {};
      for (var item in currentDistribution) {
        final research = item['research'] ?? 'غير محدد';
        final serial = item['serial'] ?? 'غير محدد';
        if (researchToSerials.containsKey(research)) {
          researchToSerials[research]!.add(serial);
        } else {
          researchToSerials[research] = [serial];
        }
      }

      final totalResearches = widget.statsCubit.state is StatsInitial
          ? widget.gender == "الذكور"
          ? (widget.statsCubit.state as StatsInitial).researchesMale
          : (widget.statsCubit.state as StatsInitial).researchesFemale
          : widget.gender == "الذكور"
          ? (widget.statsCubit.state as StatsUpdated).researchesMale
          : (widget.statsCubit.state as StatsUpdated).researchesFemale;

      print('Total Researches Uploaded: $totalResearches');
      print('Distributed Researches: ${researchToSerials.length}');
      print('Current Distribution Length: ${currentDistribution.length}');

      final fontData = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
      final font = pw.Font.ttf(fontData.buffer.asByteData());

      final table = pw.Table(
        border: pw.TableBorder.all(),
        columnWidths: {
          0: const pw.FlexColumnWidth(3),
          1: const pw.FlexColumnWidth(2),
        },
        defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
        children: [
          pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(
                  'عنوان البحث',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, font: font),
                  textDirection: pw.TextDirection.rtl,
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(
                  'المسلسلات',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, font: font),
                  textDirection: pw.TextDirection.rtl,
                ),
              ),
            ],
          ),
          ...researchToSerials.entries.map((entry) {
            final serialsText = entry.value.join(', ');
            return pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                    entry.key,
                    style: pw.TextStyle(fontSize: 10, font: font),
                    textDirection: pw.TextDirection.rtl,
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                    serialsText,
                    style: pw.TextStyle(fontSize: 14, font: font),
                    textDirection: pw.TextDirection.rtl,
                  ),
                ),
              ],
            );
          }).toList(),
        ],
      );

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => [
            pw.Text(
              'توزيع الأبحاث - ${widget.gender}',
              style: pw.TextStyle(fontSize: 16, font: font),
              textDirection: pw.TextDirection.rtl,
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              'عدد الأبحاث المرفوعة: $totalResearches',
              style: pw.TextStyle(fontSize: 12, font: font),
              textDirection: pw.TextDirection.rtl,
            ),
            pw.Text(
              'عدد الأبحاث الموزعة: ${researchToSerials.length}',
              style: pw.TextStyle(fontSize: 12, font: font),
              textDirection: pw.TextDirection.rtl,
            ),
            pw.Text(
              'عدد المسلسلات: ${currentDistribution.length}',
              style: pw.TextStyle(fontSize: 12, font: font),
              textDirection: pw.TextDirection.rtl,
            ),
            pw.SizedBox(height: 5),
            table,
          ],
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File('${output.path}/distribution_${widget.gender}.pdf');
      await file.writeAsBytes(await pdf.save());

      setState(() {
        isLoading = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم حفظ ملف PDF بنجاح'),
          action: SnackBarAction(
            label: 'فتح',
            onPressed: () async {
              if (await canLaunchUrl(Uri.file(file.path))) {
                await launchUrl(Uri.file(file.path));
              }
            },
          ),
        ),
      );
    } catch (e) {
      print('PDF Export Error: $e');
      setState(() {
        isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء إنشاء ملف PDF')));
    }
  }

  void _loadCurrentDistribution() {
    final state = widget.distributionCubit.state;
    if (state is DistributionSuccess) {
      setState(() {
        currentDistribution = state.distribution[widget.gender == "الذكور" ? "male" : "female"] ?? [];
        filteredDistribution = currentDistribution;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    searchController.addListener(_onSearchChanged);
    _loadCurrentDistribution();
  }

  @override
  void didUpdateWidget(DistributionTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gender != widget.gender) {
      _loadCurrentDistribution();
    }
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      final searchQuery = searchController.text.trim().toLowerCase();
      if (searchQuery.isEmpty) {
        filteredDistribution = currentDistribution;
      } else {
        filteredDistribution = currentDistribution.where((item) {
          final serial = item['serial']?.toLowerCase() ?? '';
          final research = item['research']?.toLowerCase() ?? '';
          return serial.contains(searchQuery) || research.contains(searchQuery);
        }).toList();
      }
    });
  }

  Widget _buildDistributionList() {
    if (currentDistribution.isEmpty) {
      return const Center(
        child: Text(
          "لا يوجد توزيع حالياً",
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    final searchQuery = searchController.text.trim().toLowerCase();

    Map<String, List<Map<String, dynamic>>> researchToSerials = {};
    for (var item in currentDistribution) {
      final research = item['research'] ?? '';
      final serial = item['serial'] ?? '';
      if (researchToSerials.containsKey(research)) {
        researchToSerials[research]!.add({
          'serial': serial,
          'highlight': searchQuery.isNotEmpty && serial.toLowerCase().contains(searchQuery),
        });
      } else {
        researchToSerials[research] = [
          {
            'serial': serial,
            'highlight': searchQuery.isNotEmpty && serial.toLowerCase().contains(searchQuery),
          }
        ];
      }
    }

    if (searchQuery.isNotEmpty) {
      researchToSerials = Map.fromEntries(
        researchToSerials.entries.where((entry) =>
        entry.key.toLowerCase().contains(searchQuery) ||
            entry.value.any((item) => item['serial'].toString().toLowerCase().contains(searchQuery))),
      );
    }

    if (researchToSerials.isEmpty && searchQuery.isNotEmpty) {
      return const Center(
        child: Text(
          "غير موجود",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: researchToSerials.length,
      itemBuilder: (context, index) {
        final research = researchToSerials.keys.elementAt(index);
        final serials = researchToSerials[research]!;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        research,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${serials.length} طالب',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'المسلسلات:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: serials.map((item) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: item['highlight'] ? Colors.green[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item['serial'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: item['highlight'] ? Colors.green[900] : Colors.black,
                      ),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalStudents = widget.statsCubit.state is StatsInitial
        ? widget.gender == "الذكور"
        ? (widget.statsCubit.state as StatsInitial).male
        : (widget.statsCubit.state as StatsInitial).female
        : widget.gender == "الذكور"
        ? (widget.statsCubit.state as StatsUpdated).male
        : (widget.statsCubit.state as StatsUpdated).female;

    final totalResearches = widget.statsCubit.state is StatsInitial
        ? widget.gender == "الذكور"
        ? (widget.statsCubit.state as StatsInitial).researchesMale
        : (widget.statsCubit.state as StatsInitial).researchesFemale
        : widget.gender == "الذكور"
        ? (widget.statsCubit.state as StatsUpdated).researchesMale
        : (widget.statsCubit.state as StatsUpdated).researchesFemale;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: isLoading || currentDistribution.isNotEmpty
                      ? null
                      : () async {
                    if (totalResearches > 0 && totalStudents > 0) {
                      await _distributeResearches(totalStudents, totalResearches);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("يرجى رفع الأبحاث أولاً وإضافة طلاب قبل التوزيع")),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: currentDistribution.isNotEmpty ? Colors.grey : null,
                  ),
                  child: Text(currentDistribution.isNotEmpty ? "تم التوزيع" : "توزيع عشوائي"),
                ),
              ),
              if (currentDistribution.isNotEmpty) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _resetDistribution,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                    child: const Text("إعادة تعيين التوزيع"),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          if (isLoading)
            const CircularProgressIndicator()
          else if (currentDistribution.isNotEmpty) ...[
            _buildSearchField(),
            const SizedBox(height: 16),
            Expanded(child: _buildDistributionList()),
          ] else
            const Expanded(
              child: Center(
                child: Text("لا يوجد توزيع بعد، اضغط 'توزيع عشوائي' للبدء"),
              ),
            ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _exportToPdf,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text("تصدير التوزيع كـ PDF", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}