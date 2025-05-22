import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hand_write_notes/core/failed_msg_screen_widget.dart';
import '../../../../get_proc_cubit/cubit/get_proc_cubit.dart';
import '../../../data/proc_model.dart';

class ProcedureSelectionDialog extends StatefulWidget {
  const ProcedureSelectionDialog({super.key});

  @override
  _ProcedureSelectionDialogState createState() =>
      _ProcedureSelectionDialogState();
}

class _ProcedureSelectionDialogState extends State<ProcedureSelectionDialog> {
  List<bool> selectedProcedures = [];
  List<Procedures> procedures = [];
  List<Map<int, int>> percentageProc = [];
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Select Procedures"),
      content: SingleChildScrollView(
        child: BlocConsumer<GetProcCubit, GetProcState>(
          listener: (context, state) {
            if (state is GetProcSuccess) {
              selectedProcedures =
                  List.generate(state.proc.length, (index) => false);
              procedures = state.proc;
            }
          },
          builder: (context, state) {
            if (state is GetProcSuccess) {
              return Column(
                children: List.generate(state.proc.length, (index) {
                  return CheckboxListTile(
                    title: Text(state.proc[index].procedureDesc),
                    value: selectedProcedures[index],
                    onChanged: (bool? value) {
                      setState(() {
                        selectedProcedures[index] = value!;
                      });
                    },
                  );
                }),
              );
            } else if (state is GetProcFailed) {
              return Text('Failed to load procedures\n${state.error}');
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop([9999]);
          },
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () {
            List<int> selected = [];
            for (int i = 0; i < selectedProcedures.length; i++) {
              if (selectedProcedures[i]) {
                selected.add(procedures[i].procedureId);
              }
            }
            Navigator.of(context).pop(selected);
          },
          child: const Text("Upload"),
        ),
      ],
    );
  }
}

class ProceduresDialog extends StatefulWidget {
  const ProceduresDialog({super.key});

  @override
  _ProceduresDialogState createState() => _ProceduresDialogState();
}

class _ProceduresDialogState extends State<ProceduresDialog> {
  List<Procedures> procedures = []; // To store fetched procedures
  List<DropdownMenuItem<int>> procStatus = [
    const DropdownMenuItem(
      value: 1,
      child: Text('25%'),
    ),
    const DropdownMenuItem(
      value: 2,
      child: Text('50%'),
    ),
    const DropdownMenuItem(
      value: 3,
      child: Text('75%'),
    ),
    const DropdownMenuItem(
      value: 4,
      child: Text('100%'),
    ),
  ];
  late List<int?> vals;
  late List<TextEditingController>
      notesControllers; // Stores notes for procedures
  @override
  void initState() {
    super.initState();
    // Fetch procedures from the web
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Procedures'),
      content: SizedBox(
        width: double.maxFinite,
        child: BlocConsumer<GetProcCubit, GetProcState>(
          listener: (context, state) {
            if (state is GetProcSuccess) {
              setState(() {
                procedures = state.proc;
                vals = List.generate(state.proc.length, (index) => null);
                // .map((proc) => {
                //       'id': proc.procedureId,
                //       'name': proc.procedureDesc,
                //       'percentage': null
                //     })
                // .toList();
                notesControllers = procedures
                    .map((proc) => TextEditingController(text: null))
                    .toList();
              });
            } else if (state is GetProcFailed) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Failed to load procedures: ${state.error}')),
              );
            }
          },
          builder: (context, state) {
            if (state is GettingProc) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is GetProcSuccess) {
              return ListView.builder(
                shrinkWrap: true,
                itemCount: procedures.length,
                itemBuilder: (context, index) {
                  return ProcedureTile(
                    notesController: notesControllers[index],
                    procedure: procedures[index],
                    percentageOptions: procStatus,
                    val: vals[index],
                    onChanged: (selectedPercentage) {
                      setState(() {
                        vals[index] = selectedPercentage;
                      });
                    },
                  );
                },
              );
            } else {
              return const Center(child: Text('No procedures available.'));
            }
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close dialog without saving
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            // Filter and return only selected procedures with percentages
            final selectedProcedures = [];
            for (int i = 0; i < procedures.length; i++) {
              if (vals[i] != null) {
                selectedProcedures.add({
                  'procedureId': procedures[i].procedureId,
                  'percentage': vals[i],
                  'notes': notesControllers[i].text
                });
              }
            }
            Navigator.of(context).pop(selectedProcedures);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class ProcedureTile extends StatelessWidget {
  final Procedures procedure;
  final List<DropdownMenuItem<int>> percentageOptions;
  final ValueChanged<int?> onChanged;
  final TextEditingController notesController;
  final int? val;

  const ProcedureTile({
    super.key,
    required this.procedure,
    required this.percentageOptions,
    required this.onChanged,
    required this.notesController,
    this.val,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(procedure.procedureDesc,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(
                  child: DropdownButton<int>(
                    value: val,
                    hint: const Text('Select %'),
                    items: percentageOptions,
                    onChanged: onChanged,
                  ),
                ),
              ],
            ),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class ProcedureSelectionScreen extends StatefulWidget {
  const ProcedureSelectionScreen({super.key});

  @override
  _ProcedureSelectionScreenState createState() =>
      _ProcedureSelectionScreenState();
}

class _ProcedureSelectionScreenState extends State<ProcedureSelectionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  Map<String, List<Procedures>> categorizedProcedures =
      {}; // Main Category -> Procedures
  Map<int, int?> selectedPercentages = {};
  Map<int, TextEditingController> notesControllers = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Procedures")),
      body: BlocConsumer<GetProcCubit, GetProcState>(
        listener: (context, state) {
          if (state is GetProcSuccess) {
            // Categorizing procedures
            for (var proc in state.proc) {
              categorizedProcedures
                  .putIfAbsent(proc.mainProcedureDesc, () => [])
                  .add(proc);

              selectedPercentages[proc.procedureId] =
                  proc.procStatus > 0 ? proc.procStatus : null;

              notesControllers[proc.procedureId] =
                  TextEditingController(text: proc.notes);
            }

            // Create tab controller after fetching data
            _tabController = TabController(
                length: categorizedProcedures.keys.length, vsync: this);

            setState(() {});
          }
        },
        builder: (context, state) {
          if (state is GetProcSuccess && categorizedProcedures.isNotEmpty) {
            return DefaultTabController(
              length: categorizedProcedures.keys.length,
              child: Column(
                children: [
                  TabBar(
                    labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                    controller: _tabController,
                    isScrollable: true,
                    tabs: categorizedProcedures.keys
                        .map((category) => Tab(text: category))
                        .toList(),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: categorizedProcedures.entries.map((entry) {
                        return ListView.builder(
                          itemCount: entry.value.length,
                          itemBuilder: (context, index) {
                            var procedure = entry.value[index];
                            return ProcedureTile1(
                              procedure: procedure.procedureDesc,
                              onChanged: (percentage) {
                                setState(() {
                                  selectedPercentages[procedure.procedureId] =
                                      percentage;
                                });
                              },
                              onNoteChanged: (note) {
                                notesControllers[procedure.procedureId]?.text =
                                    note;
                              },
                              selectedPercentage:
                                  selectedPercentages[procedure.procedureId],
                              note:
                                  notesControllers[procedure.procedureId]?.text,
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          } else if (state is GetProcFailed) {
            return WarningMsgScreen(
                state: state, onRefresh: () async {}, msg: state.error);
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final List<Map<String, dynamic>> selectedProcedures = [];

// Iterate through all categories
          for (var entry in categorizedProcedures.entries) {
            List<Procedures> procedures =
                entry.value; // List of procedures in the category

            for (int i = 0; i < procedures.length; i++) {
              int procedureId = procedures[i].procedureId;
              int? selectedPercentage =
                  selectedPercentages[procedureId]; // Get selected percentage
              String notes = notesControllers[procedureId]?.text ??
                  ""; // Get notes (if any)

              if (selectedPercentage != null) {
                selectedProcedures.add({
                  'id': procedures[i].id,
                  'procedureId': procedureId,
                  'percentage': selectedPercentage,
                  'notes': notes
                });
              }
            }
          }

          Navigator.of(context).pop(selectedProcedures);
        },
        child: const Icon(Icons.save),
      ),
    );
  }
}

class ProcedureTile1 extends StatelessWidget {
  final String procedure;
  final ValueChanged<int?> onChanged;
  final ValueChanged<String> onNoteChanged;
  final int? selectedPercentage;
  final String? note;

  const ProcedureTile1({
    super.key,
    required this.procedure,
    required this.onChanged,
    required this.onNoteChanged,
    this.selectedPercentage,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(procedure,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var percent in [
                  {1: 25},
                  {2: 50},
                  {3: 75},
                  {4: 100}
                ])
                  ChoiceChip(
                    label: Text("${percent.values.first}%"),
                    selected: selectedPercentage == percent.keys.first,
                    onSelected: (selected) {
                      onChanged(selected ? percent.keys.first : null);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              onChanged: onNoteChanged,
              decoration: const InputDecoration(
                labelText: "Notes",
                border: OutlineInputBorder(),
              ),
              controller: TextEditingController(text: note),
            ),
          ],
        ),
      ),
    );
  }
}


// class ProcedureTile extends StatelessWidget {
//   final Procedures procedure;
//   final List<DropdownMenuItem<int>> percentageOptions;
//   final ValueChanged<int?> onChanged;
//   final int? val;
//   const ProcedureTile({
//     super.key,
//     required this.procedure,
//     required this.percentageOptions,
//     required this.onChanged,
//     this.val,
//   });
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(procedure.procedureDesc),
//           DropdownButton<int>(
//             value: val,
//             hint: const Text('Select %'),
//             items: percentageOptions,
//             // percentageOptions.map((percentage) {
//             //   return DropdownMenuItem<int>(
//             //     value: percentage,
//             //     child: Text('$percentage%'),
//             //   );
//             // }).toList(),
//             onChanged: onChanged,
//           ),
//         ],
//       ),
//     );
//   }
// }
// class ProceduresDialog extends StatefulWidget {
//   @override
//   _ProceduresDialogState createState() => _ProceduresDialogState();
// }
// class _ProceduresDialogState extends State<ProceduresDialog> {
//   List<Procedures> procedures = []; // To store fetched procedures
//   final List<int> _percentageOptions = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100];
//   final Map<int, int> selectedPercentages = {}; // Map to store procedureId -> percentage
//   @override
//   void initState() {
//     super.initState();
//     // Fetch procedures from the web
//   }
//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       title: const Text('Select Procedures'),
//       content: SizedBox(
//         width: double.maxFinite,
//         child: BlocConsumer<GetProcCubit, GetProcState>(
//           listener: (context, state) {
//             if (state is GetProcSuccess) {
//               setState(() {
//                 procedures = state.proc;
//               });
//             } else if (state is GetProcFailed) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(content: Text('Failed to load procedures: ${state.error}')),
//               );
//             }
//           },
//           builder: (context, state) {
//             if (state is GettingProc) {
//               return const Center(child: CircularProgressIndicator());
//             } else if (state is GetProcSuccess) {
//               return ListView.builder(
//                 shrinkWrap: true,
//                 itemCount: procedures.length,
//                 itemBuilder: (context, index) {
//                   final procedure = procedures[index];
//                   return ProcedureTile(
//                     procedure: procedure,
//                     percentageOptions: _percentageOptions,
//                     onChanged: (selectedPercentage) {
//                       setState(() {
//                         if (selectedPercentage != null) {
//                           selectedPercentages[procedure.procedureId] = selectedPercentage;
//                         } else {
//                           selectedPercentages.remove(procedure.procedureId);
//                         }
//                       });
//                     },
//                   );
//                 },
//               );
//             } else {
//               return const Center(child: Text('No procedures available.'));
//             }
//           },
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: () {
//             Navigator.of(context).pop(); // Close dialog without saving
//           },
//           child: const Text('Cancel'),
//         ),
//         TextButton(
//           onPressed: () {
//             // Return selected procedures as {procedureId: percentage}
//             Navigator.of(context).pop(selectedPercentages);
//           },
//           child: const Text('Save'),
//         ),
//       ],
//     );
//   }
// }
// class ProcedureTile extends StatelessWidget {
//   final Procedures procedure;
//   final List<int> percentageOptions;
//   final ValueChanged<int?> onChanged;
//   const ProcedureTile({
//     required this.procedure,
//     required this.percentageOptions,
//     required this.onChanged,
//   });
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(procedure.procedureDesc),
//           DropdownButton<int>(
//             value: null,
//             hint: const Text('Select %'),
//             items: percentageOptions.map((percentage) {
//               return DropdownMenuItem<int>(
//                 value: percentage,
//                 child: Text('$percentage%'),
//               );
//             }).toList(),
//             onChanged: onChanged,
//           ),
//         ],
//       ),
//     );
//   }
// }
// class ProcedureSelectionScreen extends StatefulWidget {
//   const ProcedureSelectionScreen({Key? key}) : super(key: key);
//   @override
//   _ProcedureSelectionScreenState createState() =>
//       _ProcedureSelectionScreenState();
// }
// class _ProcedureSelectionScreenState extends State<ProcedureSelectionScreen> {
//    Map<String, List<Procedures>> categorizedProcedures={};
//    Map<int, int?> selectedPercentages={};
//    Map<int, TextEditingController> notesControllers={};
//   List<DropdownMenuItem<int>> percentageOptions = [
//     const DropdownMenuItem(value: 25, child: Text('25%')),
//     const DropdownMenuItem(value: 50, child: Text('50%')),
//     const DropdownMenuItem(value: 75, child: Text('75%')),
//     const DropdownMenuItem(value: 100, child: Text('100%')),
//   ];
//   @override
//   void initState() {
//     super.initState();
//   }
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Select Procedures")),
//       body: BlocConsumer<GetProcCubit, GetProcState>(
//         listener: (context, state) {
//           if (state is GetProcSuccess) {
//    Map<String, List<Procedures>> categorizedProcedures={};
//    Map<int, int?> selectedPercentages={};
//    Map<int, TextEditingController> notesControllers={};
//             for (var proc in state.proc) {
//               categorizedProcedures
//                   .putIfAbsent(proc.mainProcedureDesc, () => [])
//                   .add(proc);
//               selectedPercentages[proc.procedureId] =
//                   proc.procStatus > 0 ? proc.procStatus : null;
//               notesControllers[proc.procedureId] =
//                   TextEditingController(text: proc.notes);
//             }
//           }
//         },
//         builder: (context, state) {
//           return ListView(
//             children: categorizedProcedures.entries.map((entry) {
//               return ExpansionTile(
//                 title: Text(entry.key,
//                     style: const TextStyle(fontWeight: FontWeight.bold)),
//                 children: entry.value.map((procedure) {
//                   return _buildProcedureTile(procedure);
//                 }).toList(),
//               );
//             }).toList(),
//           );
//         },
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed:(){}, //_saveProcedures,
//         child: const Icon(Icons.save),
//       ),
//     );
//   }
//   Widget _buildProcedureTile(Procedures procedure) {
//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//       child: Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(procedure.procedureDesc,
//                 style: const TextStyle(fontWeight: FontWeight.bold)),
//             Row(
//               children: [
//                 Expanded(
//                   child: DropdownButton<int>(
//                     value: selectedPercentages[procedure.procedureId],
//                     hint: const Text('Select %'),
//                     items: percentageOptions,
//                     onChanged: (value) {
//                       setState(() {
//                         selectedPercentages[procedure.procedureId] = value;
//                       });
//                     },
//                   ),
//                 ),
//               ],
//             ),
//             TextField(
//               controller: notesControllers[procedure.procedureId],
//               decoration: const InputDecoration(
//                   labelText: 'Notes', border: OutlineInputBorder()),
//               maxLines: 2,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//   // void _saveProcedures() {
//   //   List<Procedures> selectedProcedures = [];
//   //   selectedPercentages.forEach((procId, percentage) {
//   //     if (percentage != null) {
//   //       selectedProcedures.add(Procedures(
//   //         id: 0,
//   //         procedureId: procId,
//   //         procIdPv: 0,
//   //         patientId: 0,
//   //         procedureDesc: widget.allProcedures
//   //             .firstWhere((p) => p.procedureId == procId)
//   //             .procedureDesc,
//   //         mainProcedureDesc: widget.allProcedures
//   //             .firstWhere((p) => p.procedureId == procId)
//   //             .mainProcedureDesc,
//   //         mainProcedureId: widget.allProcedures
//   //             .firstWhere((p) => p.procedureId == procId)
//   //             .mainProcedureId,
//   //         procStatus: percentage,
//   //         visitDate: "", // Add actual visit date
//   //         notes: notesControllers[procId]?.text ?? "",
//   //       ));
//   //     }
//   //   });
//   //   Navigator.pop(context, selectedProcedures);
//   // }
// }
// class ProcedureTile1 extends StatelessWidget {
//   final String procedure;
//   final ValueChanged<int?> onChanged;
//   final ValueChanged<String> onNoteChanged;
//   final int? selectedPercentage;
//   final String? note;
//  ProcedureTile1({
//     required this.procedure,
//     required this.onChanged,
//     required this.onNoteChanged,
//     this.selectedPercentage,
//     this.note,
//   });
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
//       child: Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(procedure,
//                 style: const TextStyle(fontWeight: FontWeight.bold)),
//             const SizedBox(height: 10),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 for (var percent in [25, 50, 75, 100])
//                   ChoiceChip(
//                     label: Text("$percent%"),
//                     selected: selectedPercentage == percent,
//                     onSelected: (selected) {
//                       if (selected) {
//                         onChanged(percent);
//                       }
//                     },
//                   ),
//               ],
//             ),
//             const SizedBox(height: 10),
//             TextField(
//               onChanged: onNoteChanged,
//               decoration: const InputDecoration(
//                 labelText: "Notes",
//                 border: OutlineInputBorder(),
//               ),
//               controller: TextEditingController(text: note),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }