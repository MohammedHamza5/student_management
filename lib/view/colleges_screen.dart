import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/colleges_cubit.dart';
import '../cubits/colleges_state.dart';
import '../cubits/stats_cubit.dart';
import 'package:flutter/services.dart'; // لـ RawKeyboardListener

class CollegesScreen extends StatelessWidget {
  const CollegesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: buildAppBar(context),
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
              _buildCollegeTab(context, "الذكور"),
              _buildCollegeTab(context, "الإناث"),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddCollegeDialog(context),
          backgroundColor: const Color(0xFFF97316),
          elevation: 6,
          tooltip: 'إضافة كلية',
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.add, size: 28),
        ),
      ),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text(
        'الكليات',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      backgroundColor: const Color(0xFF1E3A8A),
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.3),
      bottom: TabBar(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorColor: const Color(0xFFF97316),
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [Icon(Icons.male), SizedBox(width: 8), Text("الذكور")],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [Icon(Icons.female), SizedBox(width: 8), Text("الإناث")],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollegeTab(BuildContext context, String gender) {
    final primaryColor = gender == "الذكور" ? Colors.blueAccent : Colors.pinkAccent;

    return BlocBuilder<CollegesCubit, CollegesState>(
      builder: (context, state) {
        final colleges = state is CollegesInitial
            ? state.colleges.where((c) => c.gender == gender).toList()
            : (state as CollegesUpdated).colleges.where((c) => c.gender == gender).toList();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "كليات $gender",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: primaryColor.withOpacity(0.9),
                  shadows: [Shadow(blurRadius: 4.0, color: Colors.grey.withOpacity(0.3), offset: const Offset(2.0, 2.0))],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "عدد الكليات: ${colleges.length}",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: primaryColor),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _clearCollegesByGender(context, gender),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.9),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
                icon: const Icon(Icons.delete_forever, color: Colors.white),
                label: const Text("حذف الكل", style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: colleges.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.school, size: 60, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        "لا توجد كليات بعد، أضف واحدة الآن!",
                        style: TextStyle(fontSize: 18, color: Colors.grey[500], fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                )
                    : SingleChildScrollView(
                  child: Column(
                    children: colleges.map((college) {
                      final index = state is CollegesInitial
                          ? state.colleges.indexOf(college)
                          : (state as CollegesUpdated).colleges.indexOf(college);
                      return _buildCollegeCard(context, college, index, primaryColor);
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCollegeCard(BuildContext context, College college, int index, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.15), Colors.white],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    college.name,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[850]),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.people, size: 18, color: color),
                      const SizedBox(width: 6),
                      Text("الطلاب: ${college.students}", style: TextStyle(fontSize: 16, color: color.withOpacity(0.9))),
                    ],
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: color.withOpacity(0.8)),
                  onPressed: () => _showEditCollegeDialog(context, college, index),
                  tooltip: 'تعديل',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => _showDeleteConfirmationDialog(context, college, index),
                  tooltip: 'حذف',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCollegeDialog(BuildContext context) {
    final nameController = TextEditingController();
    final studentsController = TextEditingController();
    String? selectedGender;
    final _formKey = GlobalKey<FormState>();
    final focusNode = FocusNode(); // للتحكم في التركيز

    void _submitForm() {
      if (_formKey.currentState!.validate() && selectedGender != null) {
        final collegesCubit = BlocProvider.of<CollegesCubit>(context);
        final colleges = collegesCubit.state is CollegesInitial
            ? (collegesCubit.state as CollegesInitial).colleges
            : (collegesCubit.state as CollegesUpdated).colleges;

        // التحقق من تكرار اسم الكلية في نفس الجنس
        final isDuplicate = colleges.any((c) =>
        c.name.trim().toLowerCase() == nameController.text.trim().toLowerCase() && c.gender == selectedGender);

        if (isDuplicate) {
          showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: Colors.white,
              elevation: 8,
              title: const Text("تنبيه", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
              content: Text("الكلية '${nameController.text}' موجودة بالفعل لـ $selectedGender. هل تريد إضافتها؟"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("لا", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF97316),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("نعم", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ).then((shouldAdd) {
            if (shouldAdd == true) {
              _addCollege(context, nameController.text, studentsController.text, selectedGender!);
            }
          });
        } else {
          _addCollege(context, nameController.text, studentsController.text, selectedGender!);
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) => RawKeyboardListener(
        focusNode: focusNode,
        onKey: (RawKeyEvent event) {
          if (event is RawKeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
            _submitForm(); // تنفيذ الإضافة عند الضغط على Enter
          }
        },
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          elevation: 8,
          title: const Text("إضافة كلية", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: "اسم الكلية",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'يرجى إدخال اسم الكلية';
                    if (RegExp(r'^\d+$').hasMatch(value)) return 'اسم الكلية لا يمكن أن يكون أرقامًا فقط';
                    return null;
                  },
                  onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(), // الانتقال إلى الحقل التالي
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: studentsController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: "عدد الطلاب",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'يرجى إدخال عدد الطلاب';
                    if (!RegExp(r'^\d+$').hasMatch(value)) return 'عدد الطلاب يجب أن يكون رقمًا صحيحًا فقط';
                    return null;
                  },
                  onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(), // الانتقال إلى الحقل التالي
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: "الجنس",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: const [
                    DropdownMenuItem(value: "الذكور", child: Text("الذكور")),
                    DropdownMenuItem(value: "الإناث", child: Text("الإناث")),
                  ],
                  onChanged: (value) => selectedGender = value,
                  validator: (value) => value == null ? 'يرجى اختيار الجنس' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("إلغاء", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF97316),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text("إضافة", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _addCollege(BuildContext context, String name, String studentsText, String gender) {
    BlocProvider.of<CollegesCubit>(context).addCollege(
      name,
      int.parse(studentsText),
      gender,
    );
    BlocProvider.of<StatsCubit>(context).updateStats(
      male: gender == "الذكور" ? int.parse(studentsText) : 0,
      female: gender == "الإناث" ? int.parse(studentsText) : 0,
      researchesMale: 0,
      researchesFemale: 0,
    );
    Navigator.pop(context);
  }

  void _showEditCollegeDialog(BuildContext context, College college, int index) {
    final nameController = TextEditingController(text: college.name);
    final studentsController = TextEditingController(text: college.students.toString());
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        elevation: 8,
        title: const Text("تعديل كلية", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "اسم الكلية",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'يرجى إدخال اسم الكلية';
                  if (RegExp(r'^\d+$').hasMatch(value)) return 'اسم الكلية لا يمكن أن يكون أرقامًا فقط';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: studentsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "عدد الطلاب",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'يرجى إدخال عدد الطلاب';
                  if (!RegExp(r'^\d+$').hasMatch(value)) return 'عدد الطلاب يجب أن يكون رقمًا صحيحًا فقط';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("إلغاء", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                BlocProvider.of<CollegesCubit>(context).editCollege(
                  index,
                  nameController.text,
                  int.parse(studentsController.text),
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

  void _showDeleteConfirmationDialog(BuildContext context, College college, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        elevation: 8,
        title: const Text("تأكيد الحذف", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
        content: Text("هل أنت متأكد من حذف كلية ${college.name}؟"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("لا", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              BlocProvider.of<CollegesCubit>(context).deleteCollege(index);
              BlocProvider.of<StatsCubit>(context).updateStats(
                male: college.gender == "الذكور" ? -college.students : 0,
                female: college.gender == "الإناث" ? -college.students : 0,
                researchesMale: 0,
                researchesFemale: 0,
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text("نعم", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _clearCollegesByGender(BuildContext context, String gender) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        elevation: 8,
        title: Text('حذف جميع كليات $gender', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
        content: Text('هل أنت متأكد من حذف جميع الكليات الخاصة ب$gender؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final collegesCubit = BlocProvider.of<CollegesCubit>(context);
              final colleges = collegesCubit.state is CollegesInitial
                  ? (collegesCubit.state as CollegesInitial).colleges
                  : (collegesCubit.state as CollegesUpdated).colleges;
              final totalStudents = colleges.where((c) => c.gender == gender).fold<int>(0, (sum, c) => sum + c.students);

              collegesCubit.clearCollegesByGender(gender);
              BlocProvider.of<StatsCubit>(context).updateStats(
                male: gender == "الذكور" ? -totalStudents : 0,
                female: gender == "الإناث" ? -totalStudents : 0,
                researchesMale: 0,
                researchesFemale: 0,
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('تم حذف جميع كليات $gender'), backgroundColor: Colors.green),
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
}