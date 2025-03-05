import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/search_cubit.dart';
import '../cubits/search_state.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController _searchController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text("البحث", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E3A8A),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: "ابحث عن توزيع",
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                BlocProvider.of<SearchCubit>(context).search(value);
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BlocBuilder<SearchCubit, SearchState>(
                builder: (context, state) {
                  final results = state.results;
                  if (results.isEmpty) {
                    return const Center(child: Text("لا توجد نتائج مطابقة"));
                  }
                  return SingleChildScrollView(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text("رقم المسلسل")),
                        DataColumn(label: Text("البحث")),
                      ],
                      rows: results.map((item) => DataRow(cells: [
                        DataCell(Text(item["serial"] ?? "")),
                        DataCell(Text(item["research"] ?? "")),
                      ])).toList(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}