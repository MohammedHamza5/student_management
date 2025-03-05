import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/colleges_cubit.dart';
import '../cubits/colleges_state.dart';
import '../cubits/stats_cubit.dart';
import '../cubits/stats_state.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "لوحة التحكم",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          backgroundColor: const Color(0xFF1E3A8A),
          elevation: 0,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.pink,
            tabs: [
              Tab(text: "الذكور", icon: Icon(Icons.male)),
              Tab(text: "الإناث", icon: Icon(Icons.female)),
            ],
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFE8F0FE), Colors.white],
            ),
          ),
          child: TabBarView(
            children: [
              _buildGenderDashboard(context, "الذكور"),
              _buildGenderDashboard(context, "الإناث"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderDashboard(BuildContext context, String gender) {
    return MultiBlocBuilder(
      blocs: [
        BlocProvider.of<StatsCubit>(context),
        BlocProvider.of<CollegesCubit>(context),
      ],
      builder: (context, states) {
        final statsState = states[0] as StatsState;
        final collegesState = states[1] as CollegesState;

        final students = gender == "الذكور" ? statsState.male : statsState.female;
        final researches = gender == "الذكور" ? statsState.researchesMale : statsState.researchesFemale;
        final colleges = collegesState.colleges.where((college) => college.gender == gender).length;
        final primaryColor = gender == "الذكور" ? Colors.blueAccent : Colors.pinkAccent;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "إحصائيات $gender",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: primaryColor.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 35),
              Expanded(
                child: ListView(
                  children: [
                    _buildStatCard(
                      title: "عدد الطلاب",
                      value: students.toString(),
                      icon: gender == "الذكور" ? Icons.male : Icons.female,
                      color: primaryColor,
                    ),
                    const SizedBox(height: 35),
                    _buildStatCard(
                      title: "عدد الأبحاث",
                      value: researches.toString(),
                      icon: Icons.book,
                      color: primaryColor,
                    ),
                    const SizedBox(height: 35),
                    _buildStatCard(
                      title: "عدد الكليات",
                      value: colleges.toString(),
                      icon: Icons.school,
                      color: primaryColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.1), Colors.white],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

// MultiBlocBuilder لتتبع حالات متعددة
class MultiBlocBuilder extends StatelessWidget {
  final List<BlocBase> blocs;
  final Widget Function(BuildContext, List<dynamic>) builder;

  const MultiBlocBuilder({
    super.key,
    required this.blocs,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder(
      bloc: blocs[0],
      builder: (context, state1) {
        if (blocs.length == 1) {
          return builder(context, [state1]);
        }
        return BlocBuilder(
          bloc: blocs[1],
          builder: (context, state2) {
            return builder(context, [state1, state2]);
          },
        );
      },
    );
  }
}