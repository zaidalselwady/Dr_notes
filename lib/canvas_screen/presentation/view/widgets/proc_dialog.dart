import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
            Navigator.of(context).pop([99999]); // Close dialog without saving
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

