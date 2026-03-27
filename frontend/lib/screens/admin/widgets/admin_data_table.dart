import 'package:flutter/material.dart';

class AdminDataTable extends StatelessWidget {
  const AdminDataTable({
    super.key,
    required this.columns,
    required this.rows,
  });

  final List<String> columns;
  final List<List<Widget>> rows;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingTextStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF64748B),
        ),
        columns: columns.map((c) => DataColumn(label: Text(c.toUpperCase()))).toList(),
        rows: rows
            .map(
              (cells) => DataRow(
                cells: cells.map((w) => DataCell(w)).toList(),
              ),
            )
            .toList(),
      ),
    );
  }
}
