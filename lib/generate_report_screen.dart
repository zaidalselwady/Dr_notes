import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hand_write_notes/get_proc_cubit/cubit/get_proc_cubit.dart';
import 'package:hand_write_notes/get_report_result_cubit/cubit/get_generated_report_result_cubit.dart';
import 'package:hand_write_notes/report_result_screen.dart';
import 'package:hand_write_notes/reporting_screen_cubit/cubit/reporting_cubit.dart';

import 'core/repos/data_repo_impl.dart';
import 'core/utils/api_service.dart';
import 'search_fields_model.dart';

class ReportingScreen extends StatefulWidget {
  const ReportingScreen({super.key});

  @override
  State<ReportingScreen> createState() => _ReportingScreenState();
}

class _ReportingScreenState extends State<ReportingScreen> {
  final TextEditingController birthDateController = TextEditingController();
  final TextEditingController visitDateFromController = TextEditingController();
  final TextEditingController visitDateToController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  List<int> selectedProcedures = [];
  List<int> selectedProcedureStatuses = [];
  List<int> selectedFields = [];
  Map<int, String> proceduresMap = {};
  Map<int, Map> fieldsMap = {};
  String sqlStr = "";
  List<String?> fieldGroupList = [];
  List<String> procedures = [];
  List<FieldInfo> fields = [];
  final Map<int, String> procedureStatuses = {
    1: "25%",
    2: "50%",
    3: "75%",
    4: "100%"
  };
  // String buildDynamicSqlQuery(
  //     Map<String, dynamic> criteria,
  //     String baseQuery,
  //     List<String?> groupByFields,
  //     List<int> selectedFields,
  //     Map<int, Map> fieldsMap) {
  //   String sqlStr = baseQuery;
  //   List<String> conditions = [];
  //   // Add visit date range condition
  //   if (criteria.containsKey('Visit Date From') &&
  //       criteria.containsKey('Visit Date To')) {
  //     if (criteria['Visit Date From'] != null &&
  //         criteria['Visit Date To'] != null &&
  //         criteria['Visit Date From']!.isNotEmpty &&
  //         criteria['Visit Date To']!.isNotEmpty) {
  //       conditions.add(
  //           "Visit_Date BETWEEN '${criteria['Visit Date From']}' AND '${criteria['Visit Date To']}'");
  //     } else if (criteria['Visit Date From'] != null &&
  //         criteria['Visit Date From']!.isNotEmpt) {
  //       conditions.add("Visit_Date >= '${criteria['Visit Date From']}'");
  //     } else {
  //       conditions.add("Visit_Date <= '${criteria['Visit Date To']}'");
  //     }
  //   }
  //   if (criteria.containsKey('Birth Date') &&
  //       criteria['Birth Date']!.isNotEmpty &&
  //       criteria['Birth Date'] != null) {
  //     String birthDate = criteria['Birth Date'];
  //     conditions.add("birthDate LIKE '$birthDate'");
  //   }
  //   // Add procedures condition
  //   if (criteria.containsKey('Procedures') &&
  //       (criteria['Procedures'] as List).isNotEmpty) {
  //     String procedures = (criteria['Procedures'] as List).join(", ");
  //     conditions.add("Procedure_id IN ($procedures)");
  //   }
  //   // Add procedure statuses condition
  //   if (criteria.containsKey('Procedure Statuses') &&
  //       (criteria['Procedure Statuses'] as List).isNotEmpty) {
  //     String statuses = (criteria['Procedure Statuses'] as List).join(", ");
  //     conditions.add("Procedure_Status IN ($statuses)");
  //   }
  //   // Add notes condition
  //   if (criteria.containsKey('Notes') &&
  //       (criteria['Notes'] as String).isNotEmpty) {
  //     String notes = criteria['Notes'];
  //     conditions.add("Notes LIKE '%$notes%'");
  //   }
  //   // Append conditions to the base SQL query
  //   if (conditions.isNotEmpty) {
  //     sqlStr += " WHERE ${conditions.join(" AND ")}";
  //   }
  //   if (groupByFields.isNotEmpty) {
  //     sqlStr += " GROUP BY ${groupByFields.join(", ")}";
  //   }
  //   return sqlStr;
  // }

  String buildDynamicSqlQuery(
    Map<String, dynamic> criteria,
    String baseQuery,
    List<String?> groupByFields,
  ) {
    String sqlStr = baseQuery;
    List<String> conditions = [];
    // Add visit date range condition
    if (criteria.containsKey('Visit Date From') &&
        criteria.containsKey('Visit Date To')) {
      if (criteria['Visit Date From'] != null &&
          criteria['Visit Date To'] != null &&
          criteria['Visit Date From']!.isNotEmpty &&
          criteria['Visit Date To']!.isNotEmpty) {
        conditions.add(
            "Visit_Date BETWEEN '${criteria['Visit Date From']}' AND '${criteria['Visit Date To']}'");
      }
      if (criteria['Visit Date From']?.isNotEmpty ?? false) {
        conditions.add("Visit_Date >= '${criteria['Visit Date From']}'");
      }
      if (criteria['Visit Date To']?.isNotEmpty ?? false) {
        conditions.add("Visit_Date <= '${criteria['Visit Date To']}'");
      }
    }
    if (criteria.containsKey('Birth Date') &&
        criteria['Birth Date']!.isNotEmpty &&
        criteria['Birth Date'] != null) {
      String birthDate = criteria['Birth Date'];
      conditions.add("birthDate LIKE '$birthDate'");
    }
    // Add procedures condition
    if (criteria.containsKey('Procedures') &&
        (criteria['Procedures'] as List).isNotEmpty) {
      String procedures = (criteria['Procedures'] as List).join(", ");
      conditions.add("Procedure_id IN ($procedures)");
    }
    // Add procedure statuses condition
    if (criteria.containsKey('Procedure Statuses') &&
        (criteria['Procedure Statuses'] as List).isNotEmpty) {
      String statuses = (criteria['Procedure Statuses'] as List).join(", ");
      conditions.add("Procedure_Status IN ($statuses)");
    }
    // Add notes condition
    if (criteria.containsKey('Notes') &&
        (criteria['Notes'] as String).isNotEmpty) {
      String notes = criteria['Notes'];
      conditions.add("Notes LIKE '%$notes%'");
    }
    // Append conditions to the base SQL query
    if (conditions.isNotEmpty) {
      sqlStr += " WHERE ${conditions.join(" AND ")}";
    }
    if (groupByFields.isNotEmpty) {
      sqlStr += " GROUP BY ${groupByFields.join(", ")}";
    }
    return sqlStr;
  }

  String buildDynamicSqlQuery1(Map<String, dynamic> criteria, String baseQuery,
      List<String?> groupByFields) {
    String sqlStr = baseQuery;
    List<String> conditions = [];

    // ✅ Handle Visit Date conditions properly
    if (criteria['Visit Date From']?.isNotEmpty ?? false) {
      if (criteria['Visit Date To']?.isEmpty ?? false) {
        conditions.add("Visit_Date >= '${criteria['Visit Date From']}'");
      }
    }
    if (criteria['Visit Date To']?.isNotEmpty ?? false) {
      if (criteria['Visit Date From']?.isEmpty ?? false) {
        conditions.add("Visit_Date <= '${criteria['Visit Date To']}'");
      }
    }
    if ((criteria['Visit Date From']?.isNotEmpty ?? false) &&
        (criteria['Visit Date To']?.isNotEmpty ?? false)) {
      conditions.add(
          "Visit_Date BETWEEN '${criteria['Visit Date From']}' AND '${criteria['Visit Date To']}'");
    }

    // ✅ Handle Birth Date condition
    if (criteria['Birth Date']?.isNotEmpty ?? false) {
      conditions.add("birthDate LIKE '${criteria['Birth Date']}'");
    }

    // ✅ Handle Procedures condition
    if ((criteria['Procedures'] as List?)?.isNotEmpty ?? false) {
      String procedures =
          (criteria['Procedures'] as List).map((p) => "'$p'").join(", ");
      conditions.add("Procedure_id IN ($procedures)");
    }

    // ✅ Handle Procedure Statuses condition
    if ((criteria['Procedure Statuses'] as List?)?.isNotEmpty ?? false) {
      String statuses = (criteria['Procedure Statuses'] as List)
          .map((s) => "'$s'")
          .join(", ");
      conditions.add("Procedure_Status IN ($statuses)");
    }

    // ✅ Handle Notes condition
    if (criteria['Notes']?.isNotEmpty ?? false) {
      conditions.add("Notes LIKE '%${criteria['Notes']}%'");
    }

    // ✅ Append conditions if any exist
    if (conditions.isNotEmpty) {
      sqlStr += " WHERE ${conditions.join(" AND ")}";
    }

    // ✅ Append GROUP BY if any fields exist
    if (groupByFields.isNotEmpty) {
      sqlStr += " GROUP BY ${groupByFields.join(", ")}";
    }

    return sqlStr;
  }

  String buildBaseSelectStatement(List<FieldInfo> fields) {
    // Filter the fields where isVisible is true
    final visibleFields = fields.where((field) => field.isVisible).toList();

    // Sort fields by fieldOrder
    visibleFields.sort((a, b) => a.fieldOrder.compareTo(b.fieldOrder));

    // Build the SELECT clause
    final selectFields = visibleFields.map((field) {
      if (field.fieldPreName != null && field.fieldPreName!.isNotEmpty) {
        // Use fieldPreName and alias with fieldName
        return '${field.fieldPreName} ${field.fieldName}';
      } else {
        // Use fieldName directly
        return field.fieldName;
      }
    }).join(', ');

    // Build the GROUP BY clause
    final groupByFields = visibleFields
        .where(
            (field) => field.fieldGroup != null && field.fieldGroup!.isNotEmpty)
        .map((field) => field.fieldGroup)
        .toList();
    fieldGroupList = groupByFields;

    // Return the SELECT statement with the GROUP BY clause
    return 'SELECT $selectFields FROM Patients_Visits pv INNER JOIN Patients_Info pi ON pv.Patient_Id = pi.Patient_Id';
  }

  String buildBaseSelectStatement2(List<FieldInfo> fields,
      Map<int, Map> fieldsMap, List<int> selectedFields) {
    // Create a map from the list for easier access by field id
    Map<int, FieldInfo> fieldsMapCopy = {
      for (var field in fields) field.id: field,
    };

    // Remove fields that are not selected
    // fieldsMap.removeWhere((key, value) => !selectedFields.contains(key));

    // Create a list of the updated fields (now only the selected ones)
    List<FieldInfo> updatedFields = fieldsMapCopy.entries
        .where((entry) => selectedFields.contains(entry.key))
        .map((entry) => entry.value)
        .toList();

    // Filter the fields where isVisible is true
    final visibleFields =
        updatedFields.where((field) => field.isVisible).toList();

    // Sort fields by fieldOrder
    visibleFields.sort((a, b) => a.fieldOrder.compareTo(b.fieldOrder));

    // Build the SELECT clause
    final selectFields = visibleFields.map((field) {
      if (field.fieldPreName != null && field.fieldPreName!.isNotEmpty) {
        // Use fieldPreName and alias with fieldName
        return '${field.fieldPreName} ${field.fieldName}';
      } else {
        // Use fieldName directly
        return field.fieldName;
      }
    }).join(', ');

    // Build the GROUP BY clause
    final groupByFields = visibleFields
        .where(
            (field) => field.fieldGroup != null && field.fieldGroup!.isNotEmpty)
        .map((field) => field.fieldGroup)
        .toList();
    fieldGroupList = groupByFields;

    // Return the SELECT statement with the GROUP BY clause
    return 'SELECT $selectFields FROM Patients_Visits pv INNER JOIN Patients_Info pi ON pv.Patient_Id = pi.Patient_Id';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reports"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BlocConsumer<GetSearchFields, GetSearchFieldsState>(
                listener: (context, state) {
                  if (state is GetSearchFieldsSuccess) {
                    // sqlStr = buildBaseSelectStatement2(
                    //     state.searchFields, fieldsMap, selectedFields);
                    fieldsMap = {
                      for (var proc in state.searchFields)
                        proc.id: {
                          "desc": proc.fieldDesc,
                          "visible": proc.isVisible
                        },
                    };
                    selectedFields = fieldsMap.entries
                        .where((entry) => entry.value["visible"] == true)
                        .map((entry) => entry.key)
                        .toList();
                    fields = state.searchFields;
                  }
                },
                builder: (context, state) {
                  if (state is GetSearchFieldsSuccess) {
                    return MultiSelectChip(
                      title: "Fields",
                      options: fieldsMap,
                      selectedItems: selectedFields,
                      onSelectionChanged: (selected) {
                        setState(() {
                          selectedFields = selected;
                        });
                      },
                    );
                  } else {
                    return const CircularProgressIndicator();
                  }
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      birthDateController.text =
                          pickedDate.toIso8601String().split('T').first;
                    });
                  }
                },
                child: IgnorePointer(
                  child: TextFormField(
                    controller: birthDateController,
                    decoration: const InputDecoration(
                      labelText: "Birth Date",
                      hintText: "YYYY-MM-DD",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime(2100),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            visitDateFromController.text =
                                pickedDate.toIso8601String().split('T').first;

                            // Validate date range
                            if (visitDateToController.text.isNotEmpty) {
                              DateTime visitDateTo =
                                  DateTime.parse(visitDateToController.text);
                              if (pickedDate.isAfter(visitDateTo)) {
                                visitDateFromController.clear();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        "Visit Date From cannot be after Visit Date To."),
                                  ),
                                );
                              }
                            }
                          });
                        }
                      },
                      child: IgnorePointer(
                        child: TextFormField(
                          controller: visitDateFromController,
                          decoration: const InputDecoration(
                            labelText: "Visit Date From",
                            hintText: "YYYY-MM-DD",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime(2100),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            visitDateToController.text =
                                pickedDate.toIso8601String().split('T').first;

                            // Validate date range
                            if (visitDateFromController.text.isNotEmpty) {
                              DateTime visitDateFrom =
                                  DateTime.parse(visitDateFromController.text);
                              if (visitDateFrom.isAfter(pickedDate)) {
                                visitDateToController.clear();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        "Visit Date To cannot be before Visit Date From."),
                                  ),
                                );
                              }
                            }
                          });
                        }
                      },
                      child: IgnorePointer(
                        child: TextFormField(
                          controller: visitDateToController,
                          decoration: const InputDecoration(
                            labelText: "Visit Date To",
                            hintText: "YYYY-MM-DD",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              BlocConsumer<GetProcCubit, GetProcState>(
                listener: (context, state) {
                  if (state is GetProcSuccess) {
                    proceduresMap = {
                      for (var proc in state.proc)
                        proc.procedureId: proc.procedureDesc,
                    };
                    // procedures =
                    //     state.proc.map((proc) => proc.procedureDesc).toList();
                  }
                },
                builder: (context, state) {
                  if (state is GetProcSuccess) {
                    return MultiSelectChip(
                      title: "Procedures",
                      options: proceduresMap,
                      selectedItems: selectedProcedures,
                      onSelectionChanged: (selected) {
                        setState(() {
                          selectedProcedures = selected;
                        });
                      },
                    );
                  } else if (state is GetProcFailed) {
                    return const Text("Failed to load procedures");
                  } else {
                    return const CircularProgressIndicator();
                  }
                },
              ),
              const SizedBox(height: 16),
              MultiSelectChip(
                title: "Procedure Statuses",
                options: procedureStatuses,
                selectedItems: selectedProcedureStatuses,
                onSelectionChanged: (selected) {
                  setState(() {
                    selectedProcedureStatuses = selected;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: "Notes",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  CustomElevatedButton(
                    onPressed: () {
                      // Validate visit date range
                      if (visitDateFromController.text.isNotEmpty &&
                          visitDateToController.text.isNotEmpty) {
                        DateTime visitDateFrom =
                            DateTime.parse(visitDateFromController.text);
                        DateTime visitDateTo =
                            DateTime.parse(visitDateToController.text);

                        if (visitDateFrom.isAfter(visitDateTo)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  "Visit Date From cannot be after Visit Date To."),
                            ),
                          );
                          return;
                        }
                      }

                      // Logic to generate the report based on criteria
                      final criteria = {
                        "Birth Date": birthDateController.text,
                        "Visit Date From": visitDateFromController.text,
                        "Visit Date To": visitDateToController.text,
                        "Procedures": selectedProcedures,
                        "Procedure Statuses": selectedProcedureStatuses,
                        "Notes": notesController.text,
                      };

                      sqlStr = buildBaseSelectStatement2(
                          fields, fieldsMap, selectedFields);
                      String fullSqlStr = buildDynamicSqlQuery1(
                          criteria, sqlStr, fieldGroupList);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BlocProvider(
                            create: (context) => GetGeneratedReportResultCubit(
                              DataRepoImpl(
                                ApiService(
                                  Dio(),
                                ),
                              ),
                            )..fetchPatientsWithSoapRequest(fullSqlStr),
                            child: const ReportResultScreen(),
                          ),
                        ),
                      );
                    },
                    text: "Generate Report",
                  ),
                  CustomElevatedButton(
                    onPressed: () {
                      setState(() {
                        birthDateController.clear();
                        visitDateFromController.clear();
                        visitDateToController.clear();
                        selectedProcedures.clear();
                        selectedProcedureStatuses.clear();
                        notesController.clear();
                      });
                    },
                    text: "Clear",
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomElevatedButton extends StatelessWidget {
  const CustomElevatedButton({
    super.key,
    required this.onPressed,
    required this.text,
  });
  final Function() onPressed;
  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: ElevatedButton(
        onPressed: onPressed,
        //() {
        // // Validate visit date range
        // if (visitDateFromController.text.isNotEmpty &&
        //     visitDateToController.text.isNotEmpty) {
        //   DateTime visitDateFrom =
        //       DateTime.parse(visitDateFromController.text);
        //   DateTime visitDateTo =
        //       DateTime.parse(visitDateToController.text);

        //   if (visitDateFrom.isAfter(visitDateTo)) {
        //     ScaffoldMessenger.of(context).showSnackBar(
        //       const SnackBar(
        //         content: Text(
        //             "Visit Date From cannot be after Visit Date To."),
        //       ),
        //     );
        //     return;
        //   }
        // }

        // // Logic to generate the report based on criteria
        // final criteria = {
        //   "Birth Date": birthDateController.text,
        //   "Visit Date From": visitDateFromController.text,
        //   "Visit Date To": visitDateToController.text,
        //   "Procedures": selectedProcedures,
        //   "Procedure Statuses": selectedProcedureStatuses,
        //   "Notes": notesController.text,
        // };

        // String fullSqlStr =
        //     buildDynamicSqlQuery(criteria, sqlStr, fieldGroupList);

        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => BlocProvider(
        //       create: (context) => GetGeneratedReportResultCubit(
        //         DataRepoImpl(
        //           ApiService(
        //             Dio(),
        //           ),
        //         ),
        //       )..fetchPatientsWithSoapRequest(fullSqlStr),
        //       child: const ReportResultScreen(),
        //     ),
        //   ),
        // );
        //},
        child: Text(text),
      ),
    );
  }
}

class MultiSelectChip extends StatelessWidget {
  final String title;
  final Map<int, dynamic> options; // Options as a Map (procId: procDesc)
  final List<int> selectedItems; // Selected items as a List<int> (procIds)
  final ValueChanged<List<int>> onSelectionChanged;

  const MultiSelectChip({
    super.key,
    required this.title,
    required this.options,
    required this.selectedItems,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Wrap(
          spacing: 8.0,
          children: options.entries.map((entry) {
            final procId = entry.key; // Convert procId to int
            final isSelected =
                selectedItems.contains(procId); // Check if procId is selected
            final label = entry.value;

            return ChoiceChip(
              label: Text(
                  label is Map ? label['desc'] : label), // Display the procDesc
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  // Add the procId to the selectedItems list
                  onSelectionChanged([...selectedItems, procId]);
                } else {
                  // Remove the procId from the selectedItems list
                  onSelectionChanged(
                      selectedItems.where((item) => item != procId).toList());
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
