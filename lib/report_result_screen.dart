import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hand_write_notes/get_report_result_cubit/cubit/get_generated_report_result_cubit.dart';

class ReportResultScreen extends StatefulWidget {
  const ReportResultScreen({super.key});

  @override
  State<ReportResultScreen> createState() => _ReportResultScreenState();
}

// class _ReportResultScreenState extends State<ReportResultScreen> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Report Data"),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: BlocBuilder<GetGeneratedReportResultCubit,
//             GetGeneratedReportResultState>(
//           builder: (context, state) {
//             if (state is GetGeneratedReportResultSuccess) {
//               if (state.generatedReportScreen.isEmpty) {
//                 return const Center(
//                   child: Text("No Data"),
//                 );
//               }
//               // Add both horizontal and vertical scroll support
//               return SingleChildScrollView(
//                 scrollDirection: Axis.vertical,
//                 child: SingleChildScrollView(
//                   scrollDirection: Axis.horizontal,
//                   child: DataTable(
//                     columnSpacing: 20.0,
//                     columns: const [
//                       DataColumn(label: Text('Name')),
//                       DataColumn(label: Text('Procedure')),
//                       DataColumn(label: Text('No. of Visits')),
//                       DataColumn(label: Text('Visit Date')),
//                       DataColumn(label: Text('Procedure Status')),
//                       DataColumn(label: Text('Notes')),
//                     ],
//                     rows: state.generatedReportScreen.map<DataRow>((data) {
//                       return DataRow(
//                         cells: [
//                           DataCell(Text(data['Name'] ?? 'N/A')),
//                           DataCell(Text(data['Procedure'] ?? 'N/A')),
//                           DataCell(Text(data['NoVisits'].toString())),
//                           DataCell(Text(data['Visit_Date'] ?? 'N/A')),
//                           DataCell(Text(data['Procedure_Status'] ?? 'N/A')),
//                           DataCell(Text(data['Notes'] ?? 'N/A')),
//                         ],
//                         color: WidgetStateProperty.resolveWith<Color?>(
//                             (Set<WidgetState> states) {
//                           // All rows will have the same selected color.
//                           if (states.contains(WidgetState.selected)) {
//                             return Theme.of(context)
//                                 .colorScheme
//                                 .primary
//                                 .withOpacity(0.08);
//                           }
//                           // Even rows will have a grey color.
//                           if (state.generatedReportScreen
//                               .indexOf(data)
//                               .isEven) {
//                             return const Color(0xFF00695C).withOpacity(0.3);
//                           }
//                           return null; // Use default value for other states and odd rows.
//                         }),
//                       );
//                     }).toList(),
//                   ),
//                 ),
//               );
//             } else if (state is GetGeneratedReportResultFailed) {
//               return const Center(child: Text("Failed to load data"));
//             } else {
//               return const Center(child: CircularProgressIndicator());
//             }
//           },
//         ),
//       ),
//     );
//   }
// }

class _ReportResultScreenState extends State<ReportResultScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Report Data")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: BlocBuilder<GetGeneratedReportResultCubit,
            GetGeneratedReportResultState>(
          builder: (context, state) {
            if (state is GetGeneratedReportResultSuccess) {
              if (state.generatedReportScreen.isEmpty) {
                return const Center(child: Text("No Data"));
              }
              // Extract dynamic column names from first row
              List<String> columnNames =
                  state.generatedReportScreen.first.keys.toList();
              return SingleChildScrollView(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 20.0,
                    columns: columnNames.map((colName) {
                      return DataColumn(
                          label: Text(colName.replaceAll("_", " ")));
                    }).toList(),
                    rows: state.generatedReportScreen.map<DataRow>((data) {
                      return DataRow(
                        cells: columnNames.map((colName) {
                          return DataCell(
                              Text(data[colName]?.toString() ?? 'N/A'));
                        }).toList(),
                        color: WidgetStateProperty.resolveWith<Color?>(
                            (Set<WidgetState> states) {
                          if (states.contains(WidgetState.selected)) {
                            return Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.08);
                          }
                          return state.generatedReportScreen
                                  .indexOf(data)
                                  .isEven
                              ? const Color(0xFF00695C).withOpacity(0.3)
                              : null;
                        }),
                      );
                    }).toList(),
                  ),
                ),
              );
            } else if (state is GetGeneratedReportResultFailed) {
              return const Center(child: Text("Failed to load data"));
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }
}





































// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:hand_write_notes/get_report_result_cubit/cubit/get_generated_report_result_cubit.dart';
// import 'package:hand_write_notes/reporting_screen_cubit/cubit/reporting_cubit.dart';

// class ReportResultScreen extends StatefulWidget {
//   const ReportResultScreen({super.key});

//   @override
//   State<ReportResultScreen> createState() => _ReportResultScreenState();
// }

// class _ReportResultScreenState extends State<ReportResultScreen> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Report Data"),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: BlocBuilder<GetGeneratedReportResultCubit,
//             GetGeneratedReportResultState>(
//           builder: (context, state) {
//             if (state is GetGeneratedReportResultSuccess) {
//               if (state.generatedReportScreen.isEmpty) {
//                 return const Center(
//                   child: Text("No Data"),
//                 );
//               }
//               return ListView.builder(
//                 itemCount: state.generatedReportScreen.length,
//                 itemBuilder: (context, index) {
//                   final data = state.generatedReportScreen[index];
//                   return Card(
//                     elevation: 4,
//                     margin: const EdgeInsets.symmetric(vertical: 8),
//                     child: Padding(
//                       padding: const EdgeInsets.all(12.0),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             "Name: ${data['Name']}",
//                             style: const TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           Text(
//                             "Procedure: ${data['Procedure']}",
//                             style: const TextStyle(fontSize: 14),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             "No. of Visits: ${data['NoVisits']}",
//                             style: const TextStyle(fontSize: 14),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             "Visit Date: ${data['Visit_Date']}",
//                             style: const TextStyle(fontSize: 14),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             "Procedure Status: ${data['Procedure_Status']}",
//                             style: const TextStyle(fontSize: 14),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             "Notes: ${data['Notes']}",
//                             style: const TextStyle(fontSize: 14),
//                           ),
//                         ],
//                       ),
//                     ),
//                   );
//                 },
//               );
//             } else if (state is GetGeneratedReportResultFailed) {
//               return const Text("Failed to load data");
//             } else {
//               return const Center(
//                 child: CircularProgressIndicator(),
//               );
//             }
//           },
//         ),
//       ),
//     );
//   }
// }





// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:hand_write_notes/get_report_result_cubit/cubit/get_generated_report_result_cubit.dart';

// class ReportResultScreen extends StatefulWidget {
//   const ReportResultScreen({super.key});

//   @override
//   State<ReportResultScreen> createState() => _ReportResultScreenState();
// }

// class _ReportResultScreenState extends State<ReportResultScreen> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Report Data"),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: BlocBuilder<GetGeneratedReportResultCubit,
//             GetGeneratedReportResultState>(
//           builder: (context, state) {
//             if (state is GetGeneratedReportResultSuccess) {
//               if (state.generatedReportScreen.isEmpty) {
//                 return const Center(
//                   child: Text("No Data"),
//                 );
//               }

//               return SingleChildScrollView(
//                 scrollDirection: Axis.horizontal,
//                 child: DataTable(
//                   columnSpacing: 20.0,
//                   columns: const [
//                     DataColumn(label: Text('Name')),
//                     DataColumn(label: Text('Procedure')),
//                     DataColumn(label: Text('No. of Visits')),
//                     DataColumn(label: Text('Visit Date')),
//                     DataColumn(label: Text('Procedure Status')),
//                     DataColumn(label: Text('Notes')),
//                   ],
//                   rows: state.generatedReportScreen.map<DataRow>((data) {
//                     return DataRow(
//                       cells: [
//                         DataCell(Text(data['Name'] ?? 'N/A')),
//                         DataCell(Text(data['Procedure'] ?? 'N/A')),
//                         DataCell(Text(data['NoVisits'].toString())),
//                         DataCell(Text(data['Visit_Date'] ?? 'N/A')),
//                         DataCell(Text(data['Procedure_Status'] ?? 'N/A')),
//                         DataCell(Text(data['Notes'] ?? 'N/A')),
//                       ],
//                     );
//                   }).toList(),
//                 ),
//               );
//             } else if (state is GetGeneratedReportResultFailed) {
//               return const Center(child: Text("Failed to load data"));
//             } else {
//               return const Center(child: CircularProgressIndicator());
//             }
//           },
//         ),
//       ),
//     );
//   }
// }








// import 'package:fl_chart/fl_chart.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:hand_write_notes/get_report_result_cubit/cubit/get_generated_report_result_cubit.dart';
// import 'package:hand_write_notes/reporting_screen_cubit/cubit/reporting_cubit.dart';

// class ReportResultScreen extends StatefulWidget {
//   const ReportResultScreen({super.key});

//   @override
//   State<ReportResultScreen> createState() => _ReportResultScreenState();
// }

// class _ReportResultScreenState extends State<ReportResultScreen> {
//   // Dynamic color generation based on the number of entries
//   Color getColorForIndex(int index, int listLength) {
//     final List<Color> colors = [
//       Colors.blue,
//       Colors.green,
//       Colors.orange,
//       Colors.red,
//       Colors.purple,
//       Colors.cyan,
//       Colors.amber,
//       Colors.indigo,
//       Colors.teal,
//       Colors.lime,
//       Colors.pink,
//       Colors.brown,
//     ];
//     return colors[index % colors.length];
//   }

//   // Track the tapped slice's details
//   String tappedSliceInfo = '';

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Report Data"),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: BlocBuilder<GetGeneratedReportResultCubit,
//             GetGeneratedReportResultState>(
//           builder: (context, state) {
//             if (state is GetGeneratedReportResultSuccess) {
//               if (state.generatedReportScreen.isEmpty) {
//                 return const Center(
//                   child: Text("No Data"),
//                 );
//               }
//               return Column(
//                 children: [
//                   SizedBox(
//                     height: 250,
//                     child: PieChart(
//                       PieChartData(
//                         sections: state.generatedReportScreen
//                             .asMap()
//                             .entries
//                             .map((entry) {
//                           final index = entry.key;
//                           final data = entry.value;

//                           return PieChartSectionData(
//                             value: (data['NoVisits'] as int).toDouble(),
//                             title: '', // Remove title inside the slice
//                             color: getColorForIndex(
//                                 index, state.generatedReportScreen.length),
//                             radius: 60,
//                             borderSide:
//                                 BorderSide(color: Colors.white, width: 2),
//                             titleStyle: const TextStyle(
//                               fontSize: 14,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.white,
//                             ),
//                           );
//                         }).toList(),
//                         centerSpaceRadius: 40, // Space in the center of the pie
//                         borderData: FlBorderData(show: false),
//                         sectionsSpace: 4, // Space between each section
//                         pieTouchData: PieTouchData(
//                           touchCallback: (p0, pieTouchResponse) {
//                             final touchedIndex = pieTouchResponse
//                                 ?.touchedSection?.touchedSectionIndex;
//                             if (touchedIndex != null && touchedIndex >= 0) {
//                               final touchedData =
//                                   state.generatedReportScreen[touchedIndex];
//                               setState(() {
//                                 tappedSliceInfo =
//                                     'Name: ${touchedData['Name']}\n'
//                                     'Procedure: ${touchedData['Procedure']}\n'
//                                     'No. of Visits: ${touchedData['NoVisits']}\n'
//                                     'Visit Date: ${touchedData['Visit_Date']}\n'
//                                     'Status: ${touchedData['Procedure_Status']}\n'
//                                     'Notes: ${touchedData['Notes']}';
//                               });
//                             }
//                           },
//                         ),
//                       ),
//                     ),
//                   ),
//                   if (tappedSliceInfo.isNotEmpty)
//                     Padding(
//                       padding: const EdgeInsets.all(16.0),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Text(
//                             'Detailed Information:',
//                             style: TextStyle(
//                                 fontSize: 18, fontWeight: FontWeight.bold),
//                           ),
//                           const SizedBox(height: 8),
//                           Text(tappedSliceInfo),
//                         ],
//                       ),
//                     ),
//                 ],
//               );
//             } else if (state is GetGeneratedReportResultFailed) {
//               return const Center(child: Text("Failed to load data"));
//             } else {
//               return const Center(child: CircularProgressIndicator());
//             }
//           },
//         ),
//       ),
//     );
//   }
// }

// import 'package:fl_chart/fl_chart.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:hand_write_notes/get_report_result_cubit/cubit/get_generated_report_result_cubit.dart';
// import 'package:hand_write_notes/reporting_screen_cubit/cubit/reporting_cubit.dart';

// class ReportResultScreen extends StatefulWidget {
//   const ReportResultScreen({super.key});

//   @override
//   State<ReportResultScreen> createState() => _ReportResultScreenState();
// }

// class _ReportResultScreenState extends State<ReportResultScreen> {
//   // Dynamic color generation based on the number of entries
//   Color getColorForIndex(int index, int listLength) {
//     final List<Color> colors = [
//       Colors.blue,
//       Colors.green,
//       Colors.orange,
//       Colors.red,
//       Colors.purple,
//       Colors.cyan,
//       Colors.amber,
//       Colors.indigo,
//       Colors.teal,
//       Colors.lime,
//       Colors.pink,
//       Colors.brown,
//     ];
//     return colors[index % colors.length];
//   }

//   // Track the tapped slice's details
//   String tappedSliceInfo = '';

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Report Data"),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: BlocBuilder<GetGeneratedReportResultCubit,
//             GetGeneratedReportResultState>(
//           builder: (context, state) {
//             if (state is GetGeneratedReportResultSuccess) {
//               if (state.generatedReportScreen.isEmpty) {
//                 return const Center(
//                   child: Text("No Data"),
//                 );
//               }
//               return Column(
//                 children: [
//                   SizedBox(
//                     height: 250,
//                     child: PieChart(
//                       PieChartData(
//                         sections: state.generatedReportScreen
//                             .asMap()
//                             .entries
//                             .map((entry) {
//                           final index = entry.key;
//                           final data = entry.value;

//                           return PieChartSectionData(
//                             value: (data['NoVisits'] as int).toDouble(),
//                             title: '', // Remove title inside the slice
//                             color: getColorForIndex(
//                                 index, state.generatedReportScreen.length),
//                             radius: 60,
//                             borderSide:
//                                 BorderSide(color: Colors.white, width: 2),
//                             titleStyle: const TextStyle(
//                               fontSize: 14,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.white,
//                             ),
//                             // Set label outside the slice
//                             badgePositionPercentageOffset: 1.4,
//                             // Position outside the slice
//                             badgeWidget:
//                                 Text('${data['Name']} (${data['NoVisits']})'),
//                             showTitle: true,
//                           );
//                         }).toList(),
//                         centerSpaceRadius: 40, // Space in the center of the pie
//                         borderData: FlBorderData(show: false),
//                         sectionsSpace: 4, // Space between each section
//                         pieTouchData: PieTouchData(
//                           touchCallback: (p0, pieTouchResponse) {
//                             final touchedIndex = pieTouchResponse
//                                 ?.touchedSection?.touchedSectionIndex;
//                             if (touchedIndex != null && touchedIndex >= 0) {
//                               final touchedData =
//                                   state.generatedReportScreen[touchedIndex];
//                               setState(() {
//                                 tappedSliceInfo =
//                                     'Name: ${touchedData['Name']}\n'
//                                     'Procedure: ${touchedData['Procedure']}\n'
//                                     'No. of Visits: ${touchedData['NoVisits']}\n'
//                                     'Visit Date: ${touchedData['Visit_Date']}\n'
//                                     'Status: ${touchedData['Procedure_Status']}\n'
//                                     'Notes: ${touchedData['Notes']}';
//                               });
//                             }
//                           },
//                         ),
//                       ),
//                     ),
//                   ),
//                   if (tappedSliceInfo.isNotEmpty)
//                     Padding(
//                       padding: const EdgeInsets.all(16.0),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Text(
//                             'Detailed Information:',
//                             style: TextStyle(
//                                 fontSize: 18, fontWeight: FontWeight.bold),
//                           ),
//                           const SizedBox(height: 8),
//                           Text(tappedSliceInfo),
//                         ],
//                       ),
//                     ),
//                 ],
//               );
//             } else if (state is GetGeneratedReportResultFailed) {
//               return const Center(child: Text("Failed to load data"));
//             } else {
//               return const Center(child: CircularProgressIndicator());
//             }
//           },
//         ),
//       ),
//     );
//   }
// }

// import 'package:fl_chart/fl_chart.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:hand_write_notes/get_report_result_cubit/cubit/get_generated_report_result_cubit.dart';
// import 'package:hand_write_notes/reporting_screen_cubit/cubit/reporting_cubit.dart';

// class ReportResultScreen extends StatefulWidget {
//   const ReportResultScreen({super.key});

//   @override
//   State<ReportResultScreen> createState() => _ReportResultScreenState();
// }

// class _ReportResultScreenState extends State<ReportResultScreen> {
//   // Track the tapped slice's details
//   String tappedSliceInfo = '';

//   // Generate color dynamically based on index
//   Color _getColorForIndex(int index) {
//     const colors = [
//       Colors.blue, Colors.green, Colors.orange, Colors.red, Colors.purple,
//       Colors.cyan, Colors.amber, Colors.indigo, Colors.teal, Colors.lime,
//       Colors.pink, Colors.brown,
//     ];
//     return colors[index % colors.length];
//   }

//   // Handle slice touch callback
//   void _onSliceTapped(int index, List<dynamic> generatedReportScreen) {
//     final touchedData = generatedReportScreen[index];
//     setState(() {
//       tappedSliceInfo = _getDetailedInfo(touchedData);
//     });
//   }

//   // Format the detailed information for tapped slice
//   String _getDetailedInfo(Map<String, dynamic> data) {
//     return 'Name: ${data['Name']}\n'
//         'Procedure: ${data['Procedure']}\n'
//         'No. of Visits: ${data['NoVisits']}\n'
//         'Visit Date: ${data['Visit_Date']}\n'
//         'Status: ${data['Procedure_Status']}\n'
//         'Notes: ${data['Notes']}';
//   }

//   // Helper function to build the PieChart sections
//   List<PieChartSectionData> _buildPieChartSections(List<dynamic> generatedReportScreen) {
//     return generatedReportScreen.asMap().entries.map((entry) {
//       final index = entry.key;
//       final data = entry.value;

//       return PieChartSectionData(
//         value: (data['NoVisits'] as int).toDouble(),
//         title: '', // No need for title inside the slice
//         color: _getColorForIndex(index),
//         radius: 60,
//         borderSide: const BorderSide(color: Colors.white, width: 2),
//         badgePositionPercentageOffset: 1.4,
//         badgeWidget: Text('${data['Name']} (${data['NoVisits']})'),
//         showTitle: true,
//       );
//     }).toList();
//   }

//   // Method to build PieChart widget
//   Widget _buildPieChart(List<dynamic> generatedReportScreen) {
//     if (generatedReportScreen.isEmpty) {
//       return const Center(child: Text("No Data"));
//     }

//     return SizedBox(
//       height: 250,
//       child: PieChart(
//         PieChartData(
//           sections: _buildPieChartSections(generatedReportScreen),
//           centerSpaceRadius: 40, // Space in the center of the pie
//           borderData: FlBorderData(show: false),
//           sectionsSpace: 4, // Space between each section
//           pieTouchData: PieTouchData(touchCallback: (p0, pieTouchResponse) {
//             final touchedIndex = pieTouchResponse?.touchedSection?.touchedSectionIndex;
//             if (touchedIndex != null && touchedIndex >= 0) {
//               _onSliceTapped(touchedIndex, generatedReportScreen);
//             }
//           }),
//         ),
//       ),
//     );
//   }

//   // Method to build the Detailed Information view
//   Widget _buildDetailedInfo() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Detailed Information:',
//           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//         ),
//         const SizedBox(height: 8),
//         Text(tappedSliceInfo),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Report Data"),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: BlocBuilder<GetGeneratedReportResultCubit, GetGeneratedReportResultState>(
//           builder: (context, state) {
//             if (state is GetGeneratedReportResultSuccess) {
//               return Column(
//                 children: [
//                   _buildPieChart(state.generatedReportScreen),
//                   if (tappedSliceInfo.isNotEmpty) Padding(
//                     padding: const EdgeInsets.all(16.0),
//                     child: _buildDetailedInfo(),
//                   ),
//                 ],
//               );
//             } else if (state is GetGeneratedReportResultFailed) {
//               return const Center(child: Text("Failed to load data"));
//             } else {
//               return const Center(child: CircularProgressIndicator());
//             }
//           },
//         ),
//       ),
//     );
//   }
// }

// import 'package:fl_chart/fl_chart.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:hand_write_notes/get_report_result_cubit/cubit/get_generated_report_result_cubit.dart';
// class ReportResultScreen extends StatefulWidget {
//   const ReportResultScreen({super.key});
//   @override
//   State<ReportResultScreen> createState() => _ReportResultScreenState();
// }
// class _ReportResultScreenState extends State<ReportResultScreen> {
//   // Track the tapped slice's details
//   String tappedSliceInfo = '';
//   // Grouping threshold for smaller slices (e.g., if a slice is less than 5%, it will be grouped under "Others")
//   static const double groupingThreshold = 5.0;
//   // Generate color dynamically based on index
//   Color _getColorForIndex(int index) {
//     const colors = [
//       Colors.blue,
//       Colors.green,
//       Colors.orange,
//       Colors.red,
//       Colors.purple,
//       Colors.cyan,
//       Colors.amber,
//       Colors.indigo,
//       Colors.teal,
//       Colors.lime,
//       Colors.pink,
//       Colors.brown,
//     ];
//     return colors[index % colors.length];
//   }
//   // Group small slices into "Others"
//   List<Map<String, dynamic>> _groupData(List<dynamic> data) {
//     double total = 0.0;
//     data.forEach((entry) {
//       total += (entry['NoVisits'] as int).toDouble();
//     });
//     List<Map<String, dynamic>> groupedData = [];
//     double othersValue = 0.0;
//     for (var entry in data) {
//       double value = (entry['NoVisits'] as int).toDouble();
//       if (value / total * 100 < groupingThreshold) {
//         othersValue += value;
//       } else {
//         groupedData.add(entry);
//       }
//     }
//     if (othersValue > 0.0) {
//       groupedData.add({
//         'Name': 'Others',
//         'NoVisits': othersValue.toInt(),
//       });
//     }
//     return groupedData;
//   }
//   // Handle slice touch callback
//   void _onSliceTapped(int index, List<dynamic> generatedReportScreen) {
//     final touchedData = generatedReportScreen[index];
//     setState(() {
//       tappedSliceInfo = _getDetailedInfo(touchedData);
//     });
//   }
//   // Format the detailed information for tapped slice
//   String _getDetailedInfo(Map<String, dynamic> data) {
//     return 'Name: ${data['Name']}\n'
//         'Procedure: ${data['Procedure']}\n'
//         'No. of Visits: ${data['NoVisits']}\n'
//         'Visit Date: ${data['Visit_Date']}\n'
//         'Status: ${data['Procedure_Status']}\n'
//         'Notes: ${data['Notes']}';
//   }
//   // Helper function to build the PieChart sections
//   List<PieChartSectionData> _buildPieChartSections(
//       List<dynamic> generatedReportScreen) {
//     return generatedReportScreen.asMap().entries.map((entry) {
//       final index = entry.key;
//       final data = entry.value;
//       return PieChartSectionData(
//         value: (data['NoVisits'] as int).toDouble(),
//         title: '', // No need for title inside the slice
//         color: _getColorForIndex(index),
//         radius: 60,
//         borderSide: const BorderSide(color: Colors.white, width: 2),
//         badgePositionPercentageOffset: 1.4,
//         badgeWidget: Text('${data['Name']} (${data['NoVisits']})'),
//         showTitle: false, // Disable internal title rendering
//       );
//     }).toList();
//   }
//   // Method to build PieChart widget
//   Widget _buildPieChart(List<dynamic> generatedReportScreen) {
//     if (generatedReportScreen.isEmpty) {
//       return const Center(child: Text("No Data"));
//     }
//     return SizedBox(
//       height: 250,
//       child: PieChart(
//         PieChartData(
//           sections: _buildPieChartSections(generatedReportScreen),
//           centerSpaceRadius: 40, // Space in the center of the pie
//           borderData: FlBorderData(show: false),
//           sectionsSpace: 4, // Space between each section
//           pieTouchData: PieTouchData(
//             touchCallback: (p0, pieTouchResponse) {
//               final touchedIndex =
//                   pieTouchResponse?.touchedSection?.touchedSectionIndex;
//               if (touchedIndex != null && touchedIndex >= 0) {
//                 _onSliceTapped(touchedIndex, generatedReportScreen);
//               }
//             },
//           ),
//         ),
//       ),
//     );
//   }
//   // Method to build the Detailed Information view
//   Widget _buildDetailedInfo() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Detailed Information:',
//           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//         ),
//         const SizedBox(height: 8),
//         Text(tappedSliceInfo),
//       ],
//     );
//   }
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Report Data"),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: BlocBuilder<GetGeneratedReportResultCubit,
//             GetGeneratedReportResultState>(
//           builder: (context, state) {
//             if (state is GetGeneratedReportResultSuccess) {
//               List<dynamic> groupedData =
//                   _groupData(state.generatedReportScreen);
//               return Column(
//                 children: [
//                   _buildPieChart(groupedData),
//                   if (tappedSliceInfo.isNotEmpty)
//                     Padding(
//                       padding: const EdgeInsets.all(16.0),
//                       child: _buildDetailedInfo(),
//                     ),
//                 ],
//               );
//             } else if (state is GetGeneratedReportResultFailed) {
//               return const Center(child: Text("Failed to load data"));
//             } else {
//               return const Center(child: CircularProgressIndicator());
//             }
//           },
//         ),
//       ),
//     );
//   }
// }
