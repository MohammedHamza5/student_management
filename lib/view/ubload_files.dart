import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hive/hive.dart';
import 'dart:io';
import '../cubits/stats_cubit.dart';
import '../cubits/upload_cubit.dart';
import '../cubits/upload_state.dart';
import '../model/mock_data.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class UploadFileScreen extends StatelessWidget {
  const UploadFileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "رفع الملفات",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          backgroundColor: const Color(0xFF1E3A8A),
          elevation: 8,
          shadowColor: Colors.black.withOpacity(0.3),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Color(0xFFF97316),
            indicatorWeight: 3,
            labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.male, size: 20),
                    SizedBox(width: 8),
                    Text("الذكور"),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.female, size: 20),
                    SizedBox(width: 8),
                    Text("الإناث"),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFE8F0FE).withOpacity(0.9),
                Colors.white,
              ],
            ),
          ),
          child: TabBarView(
            children: [
              UploadTab(gender: "الذكور"),
              UploadTab(gender: "الإناث"),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddResearchDialog(BuildContext context, String gender) {
    final TextEditingController _addResearchController = TextEditingController();
    final primaryColor = gender == "الذكور" ? Colors.blueAccent : Colors.pinkAccent;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        elevation: 8,
        title: Text(
          "إضافة بحث جديد",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        content: TextField(
          controller: _addResearchController,
          decoration: InputDecoration(
            labelText: "عنوان البحث",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey[100],
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("إلغاء", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (_addResearchController.text.isNotEmpty) {
                final newResearch = MockResearch(_addResearchController.text);
                final researches = gender == "الذكور"
                    ? BlocProvider.of<UploadCubit>(context).researchesMale
                    : BlocProvider.of<UploadCubit>(context).researchesFemale;
                final updatedResearches = List<MockResearch>.from(researches)..add(newResearch);

                final box = Hive.box('app_data');
                if (gender == "الذكور") {
                  BlocProvider.of<UploadCubit>(context).researchesMale = updatedResearches;
                  box.put('researchesMale', updatedResearches.map((r) => r.toJson()).toList());
                } else {
                  BlocProvider.of<UploadCubit>(context).researchesFemale = updatedResearches;
                  box.put('researchesFemale', updatedResearches.map((r) => r.toJson()).toList());
                }

                BlocProvider.of<UploadCubit>(context).emit(ResearchAdded(updatedResearches.length, gender));
                BlocProvider.of<StatsCubit>(context).setStats(
                  researchesMale: gender == "الذكور" ? updatedResearches.length : null,
                  researchesFemale: gender == "الإناث" ? updatedResearches.length : null,
                );
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF97316),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text("إضافة", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class UploadTab extends StatefulWidget {
  final String gender;

  const UploadTab({super.key, required this.gender});

  @override
  _UploadTabState createState() => _UploadTabState();
}

class _UploadTabState extends State<UploadTab> {
  bool isLoading = false;
  final TextEditingController _editResearchController = TextEditingController();

  void _pickFile() async {
    setState(() {
      isLoading = true;
    });

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['docx'],
    );
    if (result != null) {
      if (kIsWeb) {
        await BlocProvider.of<UploadCubit>(context).uploadFile(widget.gender, result);
      } else {
        if (result.files.single.path != null) {
          File file = File(result.files.single.path!);
          await BlocProvider.of<UploadCubit>(context).uploadFile(widget.gender, file);
        }
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  void _exportToPdf() async {
    final researches = widget.gender == "الذكور"
        ? BlocProvider.of<UploadCubit>(context).researchesMale
        : BlocProvider.of<UploadCubit>(context).researchesFemale;
    if (researches.isEmpty) return;

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Table(
            border: pw.TableBorder.all(),
            columnWidths: {
              0: const pw.FixedColumnWidth(50),
              1: const pw.FlexColumnWidth(3),
            },
            children: [
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('رقم البحث', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('عنوان البحث', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                ],
              ),
              ...researches.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final research = entry.value;
                return pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(index.toString()),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(research.title),
                    ),
                  ],
                );
              }).toList(),
            ],
          );
        },
      ),
    );

    if (!kIsWeb) {
      final dir = await getApplicationDocumentsDirectory();
      final file = File("${dir.path}/أبحاث_${widget.gender}.pdf");
      await file.writeAsBytes(await pdf.save());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("تم تصدير الأبحاث إلى ${file.path}"), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تصدير PDF غير مدعوم على الويب حاليًا")),
      );
    }
  }

  void _editResearch(int index) {
    final researches = widget.gender == "الذكور"
        ? BlocProvider.of<UploadCubit>(context).researchesMale
        : BlocProvider.of<UploadCubit>(context).researchesFemale;
    _editResearchController.text = researches[index].title;
    final primaryColor = widget.gender == "الذكور" ? Colors.blueAccent : Colors.pinkAccent;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        elevation: 8,
        title: Text(
          "تعديل البحث",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        content: TextField(
          controller: _editResearchController,
          decoration: InputDecoration(
            labelText: "عنوان البحث",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey[100],
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("إلغاء", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (_editResearchController.text.isNotEmpty) {
                final updatedResearches = List<MockResearch>.from(researches);
                updatedResearches[index] = MockResearch(_editResearchController.text);

                final box = Hive.box('app_data');
                if (widget.gender == "الذكور") {
                  BlocProvider.of<UploadCubit>(context).researchesMale = updatedResearches;
                  box.put('researchesMale', updatedResearches.map((r) => r.toJson()).toList());
                } else {
                  BlocProvider.of<UploadCubit>(context).researchesFemale = updatedResearches;
                  box.put('researchesFemale', updatedResearches.map((r) => r.toJson()).toList());
                }

                BlocProvider.of<UploadCubit>(context).emit(ResearchEdited(updatedResearches.length, widget.gender));
                BlocProvider.of<StatsCubit>(context).setStats(
                  researchesMale: widget.gender == "الذكور" ? updatedResearches.length : null,
                  researchesFemale: widget.gender == "الإناث" ? updatedResearches.length : null,
                );
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF97316),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text("حفظ", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteResearch(int index) {
    final primaryColor = widget.gender == "الذكور" ? Colors.blueAccent : Colors.pinkAccent;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        elevation: 8,
        title: Text(
          "تأكيد الحذف",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        content: const Text("هل أنت متأكد من حذف هذا البحث؟"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("إلغاء", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final researches = widget.gender == "الذكور"
                  ? BlocProvider.of<UploadCubit>(context).researchesMale
                  : BlocProvider.of<UploadCubit>(context).researchesFemale;
              final updatedResearches = List<MockResearch>.from(researches)..removeAt(index);

              final box = Hive.box('app_data');
              if (widget.gender == "الذكور") {
                BlocProvider.of<UploadCubit>(context).researchesMale = updatedResearches;
                box.put('researchesMale', updatedResearches.map((r) => r.toJson()).toList());
              } else {
                BlocProvider.of<UploadCubit>(context).researchesFemale = updatedResearches;
                box.put('researchesFemale', updatedResearches.map((r) => r.toJson()).toList());
              }

              BlocProvider.of<UploadCubit>(context).emit(ResearchDeleted(updatedResearches.length, widget.gender));
              BlocProvider.of<StatsCubit>(context).setStats(
                researchesMale: widget.gender == "الذكور" ? updatedResearches.length : null,
                researchesFemale: widget.gender == "الإناث" ? updatedResearches.length : null,
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text("حذف", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _clearResearchesByGender() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        elevation: 8,
        title: Text(
          'حذف جميع أبحاث ${widget.gender}',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
        ),
        content: Text('هل أنت متأكد من حذف جميع الأبحاث الخاصة ب${widget.gender}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              BlocProvider.of<UploadCubit>(context).resetResearches(widget.gender);
              BlocProvider.of<StatsCubit>(context).setStats(
                researchesMale: widget.gender == "الذكور" ? 0 : null,
                researchesFemale: widget.gender == "الإناث" ? 0 : null,
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('تم حذف جميع أبحاث ${widget.gender}'), backgroundColor: Colors.green),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.gender == "الذكور" ? Colors.blueAccent : Colors.pinkAccent;

    return BlocListener<UploadCubit, UploadState>(
      listener: (context, state) {
        if (state is UploadSuccess && state.gender == widget.gender) {
          setState(() {
            isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم رفع الملف بنجاح"), backgroundColor: Colors.green));
          BlocProvider.of<StatsCubit>(context).setStats(
            researchesMale: widget.gender == "الذكور" ? BlocProvider.of<UploadCubit>(context).researchesMale.length : null,
            researchesFemale: widget.gender == "الإناث" ? BlocProvider.of<UploadCubit>(context).researchesFemale.length : null,
          );
        } else if (state is ResearchAdded && state.gender == widget.gender) {
          setState(() {
            isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم إضافة البحث بنجاح"), backgroundColor: Colors.green));
        } else if (state is ResearchEdited && state.gender == widget.gender) {
          setState(() {
            isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم تعديل البحث بنجاح"), backgroundColor: Colors.green));
        } else if (state is ResearchDeleted && state.gender == widget.gender) {
          setState(() {
            isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم حذف البحث بنجاح"), backgroundColor: Colors.green));
        } else if (state is UploadError) {
          setState(() {
            isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ: ${state.message}")));
        } else if (state is UploadInitial && (BlocProvider.of<UploadCubit>(context).researchesMale.isEmpty || BlocProvider.of<UploadCubit>(context).researchesFemale.isEmpty)) {
          setState(() {
            isLoading = false;
          });
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "أبحاث ${widget.gender}",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: primaryColor.withOpacity(0.9),
                shadows: [
                  Shadow(
                    blurRadius: 4.0,
                    color: Colors.grey.withOpacity(0.3),
                    offset: const Offset(2.0, 2.0),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            BlocBuilder<UploadCubit, UploadState>(
              builder: (context, state) {
                final researches = widget.gender == "الذكور"
                    ? BlocProvider.of<UploadCubit>(context).researchesMale
                    : BlocProvider.of<UploadCubit>(context).researchesFemale;
                return Text(
                  "عدد الأبحاث: ${researches.length}",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: isLoading ? null : _pickFile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF97316),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                  ),
                  icon: const Icon(Icons.upload_file, color: Colors.white),
                  label: const Text("رفع ملف وورد", style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton.icon(
                  onPressed: () => UploadFileScreen()._showAddResearchDialog(context, widget.gender),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                  ),
                  icon: const Icon(Icons.add_circle, color: Colors.white),
                  label: const Text("إضافة بحث", style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton.icon(
                  onPressed: () => _clearResearchesByGender(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.9),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                  ),
                  icon: const Icon(Icons.delete_forever, color: Colors.white),
                  label: const Text("حذف الكل", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: BlocBuilder<UploadCubit, UploadState>(
                        builder: (context, state) {
                          if (isLoading) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          final researches = widget.gender == "الذكور"
                              ? BlocProvider.of<UploadCubit>(context).researchesMale
                              : BlocProvider.of<UploadCubit>(context).researchesFemale;

                          if (researches.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.description,
                                    size: 60,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "لا توجد أبحاث بعد، أضف واحدًا الآن!",
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[500],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: DataTable(
                                columnSpacing: MediaQuery.of(context).size.width * 0.25,
                                columns: [
                                  DataColumn(
                                    label: Expanded(
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          "رقم البحث",
                                          style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Expanded(
                                      child: Center(
                                        child: Text(
                                          "عنوان البحث",
                                          style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Expanded(
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          "إجراءات",
                                          style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                rows: researches.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final research = entry.value;
                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text((index + 1).toString()),
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 300,
                                          child: Text(
                                            research.title,
                                            softWrap: true,
                                            style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: Icon(Icons.edit, color: primaryColor.withOpacity(0.8)),
                                                tooltip: 'تعديل',
                                                onPressed: () => _editResearch(index),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                                tooltip: 'حذف',
                                                onPressed: () => _deleteResearch(index),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}