import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'cubits/colleges_cubit.dart';
import 'cubits/distribution_cubit.dart';
import 'cubits/distribution_state.dart';
import 'cubits/stats_cubit.dart';
import 'cubits/upload_cubit.dart';
import 'cubits/search_cubit.dart';
import 'model/mock_data.dart';
import 'view/colleges_screen.dart';
import 'view/dash_board_screen.dart';
import 'view/distribution_screen.dart';
import 'view/ubload_files.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(MockResearchAdapter());
  var box = await Hive.openBox('app_data');
  // await box.clear(); // سطر واحد لحذف جميع البيانات من Hive عند بدء التطبيق
  runApp(const StudentManagement());
}

class StudentManagement extends StatelessWidget {
  const StudentManagement({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<StatsCubit>(
          create: (_) => StatsCubit(), // تعريف StatsCubit أولاً
        ),
        BlocProvider<UploadCubit>(
          create: (_) => UploadCubit()..loadResearches(), // تعريف UploadCubit ثانيًا
        ),
        BlocProvider<CollegesCubit>(
          create: (context) => CollegesCubit(
            statsCubit: BlocProvider.of<StatsCubit>(context), // يعتمد على StatsCubit
          ),
        ),
        BlocProvider<DistributionCubit>(
          create: (context) => DistributionCubit(
            uploadCubit: BlocProvider.of<UploadCubit>(context), // يعتمد على UploadCubit
          ),
        ),
        BlocProvider<SearchCubit>(
          create: (context) => SearchCubit(
            distributionCubit: BlocProvider.of<DistributionCubit>(context), // يعتمد على DistributionCubit
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Student Management',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const MainScreen(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const DashboardScreen(),
      const UploadFileScreen(),
      const CollegesScreen(),
      BlocBuilder<DistributionCubit, DistributionState>(
        builder: (context, state) {
          return DistributionScreen(
            distributionCubit: context.read<DistributionCubit>(),
            statsCubit: context.read<StatsCubit>(),
            collegesCubit: context.read<CollegesCubit>(),
          );
        },
      ),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            // المحتوى الرئيسي (الشاشات والشريط الجانبي)
            Row(
              children: [
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: screens,
                  ),
                ),
                Container(
                  width: 180,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF1E3A8A),
                        const Color(0xFF2B4C9B).withOpacity(0.9),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(2, 0),
                      ),
                    ],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      Expanded(
                        child: NavigationRail(
                          selectedIndex: _selectedIndex,
                          onDestinationSelected: (int index) {
                            setState(() {
                              _selectedIndex = index;
                            });
                          },
                          labelType: NavigationRailLabelType.all,
                          backgroundColor: Colors.transparent,
                          selectedIconTheme: const IconThemeData(color: Color(0xFFF97316), size: 32),
                          unselectedIconTheme: const IconThemeData(color: Colors.white70, size: 28),
                          selectedLabelTextStyle: const TextStyle(
                            color: Color(0xFFF97316),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          unselectedLabelTextStyle: const TextStyle(color: Colors.white70, fontSize: 14),
                          groupAlignment: -0.7,
                          destinations: const [
                            NavigationRailDestination(
                              icon: Icon(Icons.dashboard),
                              label: Text("لوحة التحكم"),
                              padding: EdgeInsets.symmetric(vertical: 8),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.upload_file),
                              label: Text("رفع الملفات"),
                              padding: EdgeInsets.symmetric(vertical: 8),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.school),
                              label: Text("الكليات"),
                              padding: EdgeInsets.symmetric(vertical: 8),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.assignment),
                              label: Text("توزيع الأبحاث"),
                              padding: EdgeInsets.symmetric(vertical: 8),
                            ),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          "v1.0.0",
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // الشعار كعلامة مائية "مطبوعة"
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              bottom: 0,
              child: Center(
                child: Opacity(
                  opacity: 0.1, // شفافية منخفضة لتأثير "مطبوع"
                  child: ClipOval(
                    child: Image.asset(
                      'assets/logo/logo.jpg', // مسار الشعار
                      height: 300, // حجم كبير ليبدو كعلامة مائية
                      width: 300,
                      fit: BoxFit.contain, // عرض الصورة كاملة
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}