import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../get_proc_cubit/cubit/get_proc_cubit.dart';
import '../../../data/proc_model.dart';

class ProceduresDialog extends StatefulWidget {
  const ProceduresDialog(
      {super.key, required this.visitDate, required this.patientId});

  final String visitDate;
  final int patientId;

  @override
  _ProceduresDialogState createState() => _ProceduresDialogState();
}

class _ProceduresDialogState extends State<ProceduresDialog> {
  List<Procedures> procedures = [];
  late List<int?>
      selectedStatuses; // Stores the selected statuses for dropdowns
  late List<TextEditingController>
      notesControllers; // Stores notes for procedures

  List<DropdownMenuItem<int>> procStatus = [
    const DropdownMenuItem(value: 1, child: Text('25%')),
    const DropdownMenuItem(value: 2, child: Text('50%')),
    const DropdownMenuItem(value: 3, child: Text('75%')),
    const DropdownMenuItem(value: 4, child: Text('100%')),
  ];

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

                // Initialize selected statuses and notes controllers
                selectedStatuses = procedures
                    .map(
                        (proc) => proc.procStatus != 0 ? proc.procStatus : null)
                    .toList();

                notesControllers = procedures
                    .map((proc) => TextEditingController(text: proc.notes))
                    .toList();
              });
            } else if (state is GetProcFailed) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to load procedures: ${state.error}'),
                ),
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
                  final procedure = procedures[index];
                  return ProcedureTile(
                    procedure: procedure,
                    percentageOptions: procStatus,
                    val: selectedStatuses[index],
                    notesController: notesControllers[index],
                    onChanged: (selectedPercentage) {
                      setState(() {
                        selectedStatuses[index] = selectedPercentage;
                      });
                    },
                  );
                },
              );
            } else {
              return const Center(
                child: Text('No procedures available.'),
              );
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
            // Collect all updated procedures
            final updatedProcedures = [];
            for (int i = 0; i < procedures.length; i++) {
              if (selectedStatuses[i] != null) {
                updatedProcedures.add({
                  'id': procedures[i].id,
                  'procedureId': procedures[i].procedureId,
                  'percentage': selectedStatuses[i],
                  'notes': notesControllers[i].text,
                  'procIdPv': procedures[i].procIdPv,
                  'visitDate': procedures[i].visitDate,
                  'patientId': procedures[i].patientId,
                });
              }
            }
            Navigator.of(context).pop(updatedProcedures);
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(procedure.procedureDesc,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                procedure.procIdPv != 0
                    ? const Icon(
                        Icons.check,
                        color: Colors.green,
                      )
                    : const SizedBox()
              ],
            ),
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

// class ShowProcDialogResult extends StatefulWidget {
//   const ShowProcDialogResult(
//       {super.key, required this.visitDate, required this.patientId});
//   final String visitDate;
//   final int patientId;
//   @override
//   _ShowProcDialogResultState createState() => _ShowProcDialogResultState();
// }
// class _ShowProcDialogResultState extends State<ShowProcDialogResult> {
//   List<bool> selectedProcedures = []; // False means not selected
//   List<Procedures> procedures = [];
//   List<DropdownMenuItem<int>> procStatus = [
//     const DropdownMenuItem(
//       value: 1,
//       child: Text('25%'),
//     ),
//     const DropdownMenuItem(
//       value: 2,
//       child: Text('50%'),
//     ),
//     const DropdownMenuItem(
//       value: 3,
//       child: Text('75%'),
//     ),
//     const DropdownMenuItem(
//       value: 4,
//       child: Text('100%'),
//     ),
//   ];
//   int? selectedPercentage;
//   TextEditingController notesController = TextEditingController();
//   @override
//   Widget build(BuildContext context) {
//     var updateCubit = BlocProvider.of<UpdatePatientStateCubit>(context);
//     return AlertDialog(
//       title: const Text("Procedures result"),
//       content: SingleChildScrollView(
//         child: BlocConsumer<GetProcCubit, GetProcState>(
//           listener: (context, state) {
//             if (state is GetProcSuccess) {
//               selectedProcedures = List.generate(state.proc.length,
//                   (index) => state.proc[index].procIdPv != 0);
//               procedures = state.proc;
//               state.proc.forEach(
//                 (element) {
//                   notesController.text += element.notes;
//                 },
//               );
//             }
//           },
//           builder: (context, state) {
//             if (state is GetProcSuccess) {
//               return Column(
//                 children: List.generate(state.proc.length, (index) {
//                   String? statusText = (procStatus
//                           .firstWhere(
//                             (element) =>
//                                 element.value == state.proc[index].procStatus,
//                             orElse: () => const DropdownMenuItem(
//                                 value: 0, child: Text('-')),
//                           )
//                           .child as Text)
//                       .data;
//                   return CheckboxListTile(
//                     title: Text(state.proc[index].procedureDesc),
//                     subtitle: Text(statusText!),
//                     value: selectedProcedures[index],
//                     onChanged: (bool? value) {
//                       setState(() {
//                         selectedProcedures[index] = value!;
//                       });
//                     },
//                   );
//                 }),
//               );
//             } else if (state is GetProcFailed) {
//               return Text('Failed to load procedures\n${state.error}');
//             } else {
//               return const Center(child: CircularProgressIndicator());
//             }
//           },
//         ),
//       ),
//       actions: [
//         Column(
//           children: [
//             Row(
//               children: [
//                 DropdownButton<int>(
//                   value: selectedPercentage,
//                   items: procStatus,
//                   onChanged: (value) {
//                     setState(() {
//                       selectedPercentage = value;
//                     });
//                   },
//                   elevation: 10,
//                   hint: const Text("Status"),
//                 ),
//                 TextButton(
//                   onPressed: () {
//                     Navigator.of(context).pop([9999]);
//                   },
//                   child: const Text("Cancel"),
//                 ),
//                 BlocConsumer<UpdatePatientStateCubit, UpdatePatientStateState>(
//                   listener: (context, state) {
//                     if (state is UpdatePatientStateSuccess) {
//                       Navigator.of(context).pop();
//                     } else if (state is UpdatePatientStateFaild) {
//                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//                           content: Text('Failed to update patient status')));
//                     }
//                   },
//                   builder: (context, state) {
//                     if (state is UpdatingPatientState) {
//                       return const CircularProgressIndicator();
//                     }
//                     return TextButton(
//                       onPressed: () {
//                         if (selectedPercentage != null) {
//                           updateCubit.updateClientsWithSoapRequest(
//                               "UPDATE Patients_Visits SET Procedure_Status = $selectedPercentage,Notes='${notesController.text}' WHERE Patient_Id=${widget.patientId} AND Visit_Date='${widget.visitDate}'");
//                         } else {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                               const SnackBar(
//                                   content: Text('Please select a status')));
//                         }
//                         // List<int> selected = [];
//                         // for (int i = 0; i < selectedProcedures.length; i++) {
//                         //   if (selectedProcedures[i]) {
//                         //     selected.add(procedures[i].procedureId);
//                         //   }
//                         // }
//                         // Navigator.of(context).pop(selected);
//                       },
//                       child: const Text("Upload"),
//                     );
//                   },
//                 ),
//               ],
//             ),
//             TextField(
//               controller: notesController,
//               maxLines:
//                   null, // Allows the field to expand vertically for multiline input
//               decoration: const InputDecoration(
//                 labelText: 'Notes',
//                 hintText: 'Type here...',
//                 border:
//                     OutlineInputBorder(), // Adds a border around the TextField
//                 focusedBorder: OutlineInputBorder(
//                   borderSide: BorderSide(color: Colors.blue, width: 2.0),
//                 ),
//                 enabledBorder: OutlineInputBorder(
//                   borderSide: BorderSide(color: Colors.grey, width: 1.0),
//                 ),
//               ),
//               keyboardType: TextInputType.multiline,
//             ),
//           ],
//         ),
//       ],
//     );
//   }
// }
