// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:hand_write_notes/core/failed_msg_screen_widget.dart';
// import '../../../../get_proc_cubit/cubit/get_proc_cubit.dart';
// import '../../../../patients_visits_insert_cubit/cubit/upload_patient_visits_cubit.dart';
// import '../../../../settings.dart';
// import '../../../data/proc_model.dart';

// /// Main screen for procedure selection
// class ProcedureSelectionScreen extends StatefulWidget {
//   const ProcedureSelectionScreen({super.key});

//   @override
//   State<ProcedureSelectionScreen> createState() =>
//       _ProcedureSelectionScreenState();
// }

// class _ProcedureSelectionScreenState extends State<ProcedureSelectionScreen>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   final Map<String, List<Procedures>> _categorizedProcedures = {};
//   final Map<int, int?> _selectedPercentages = {};
//   final Map<int, TextEditingController> _notesControllers = {};
//   bool _hidePercentage = false;
//   final _settings = SettingsService();

//   @override
//   void initState() {
//     super.initState();
//     _loadData();
//     _loadSettings();
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     _notesControllers.values.forEach((controller) => controller.dispose());
//     super.dispose();
//   }

//   void _loadData() {
//     context.read<GetProcCubit>().fetchPatientsWithSoapRequest(
//         "SELECT mp.Main_Procedure_id,mp.Main_Procedure_Desc,pp.Procedure_Desc,pp.Procedure_id "
//         "FROM Patients_Main_Procedures mp "
//         "INNER JOIN Patients_Procedures pp ON mp.Main_Procedure_id = pp.Main_Procedure_id");
//   }

//   Future<void> _loadSettings() async {
//     await _settings.init();
//     setState(() {
//       _hidePercentage = _settings.getBool(AppSettingsKeys.hidePercentage);
//     });
//   }

//   void _handleProceduresLoaded(List<Procedures> procedures) {
//     _categorizedProcedures.clear();

//     for (var proc in procedures) {
//       _categorizedProcedures
//           .putIfAbsent(proc.mainProcedureDesc, () => [])
//           .add(proc);

//       _selectedPercentages[proc.procedureId] =
//           proc.procStatus > 0 ? proc.procStatus : null;

//       _notesControllers[proc.procedureId] =
//           TextEditingController(text: proc.notes);
//     }

//     _tabController =
//         TabController(length: _categorizedProcedures.keys.length, vsync: this);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Select Procedures"),
//       ),
//       body: BlocConsumer<GetProcCubit, GetProcState>(
//         listener: (context, state) {
//           if (state is GetProcSuccess) {
//             _handleProceduresLoaded(state.proc);
//           }
//         },
//         builder: (context, state) {
//           if (state is GetProcSuccess && _categorizedProcedures.isNotEmpty) {
//             return _buildProceduresList();
//           } else if (state is GetProcFailed) {
//             return WarningMsgScreen(
//                 state: state, onRefresh: () async {}, msg: state.error);
//           }
//           return const Center(child: CircularProgressIndicator());
//         },
//       ),
//       floatingActionButton:
//           BlocConsumer<UploadPatientVisitsCubit, UploadPatientVisitsState>(
//         listener: (context, state) {
//           if (state is UploadPatientVisitsSuccess) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(
//                   content: Text('Procedures uploaded successfully!')),
//             );
//             Navigator.of(context).pop(); // Close dialog on success
//           } else if (state is UploadPatientVisitsFailed) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(content: Text('Upload Failed: ${state.error}')),
//             );
//           }
//         },
//         builder: (context, state) {
//           if (state is UploadingPatientVisits) {
//             return const CircularProgressIndicator();
//           }
//           return FloatingActionButton(
//             onPressed: _saveProcedures,
//             child: const Icon(Icons.save),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildProceduresList() {
//     return DefaultTabController(
//       length: _categorizedProcedures.keys.length,
//       child: Column(
//         children: [
//           _buildTabBar(),
//           Expanded(child: _buildTabBarView()),
//         ],
//       ),
//     );
//   }

//   Widget _buildTabBar() {
//     return TabBar(
//       labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//       controller: _tabController,
//       isScrollable: true,
//       tabs: _categorizedProcedures.keys
//           .map((category) => Tab(text: category))
//           .toList(),
//     );
//   }

//   Widget _buildTabBarView() {
//     return TabBarView(
//       controller: _tabController,
//       children: _categorizedProcedures.entries.map((entry) {
//         return ListView.builder(
//           itemCount: entry.value.length,
//           itemBuilder: (context, index) =>
//               _buildProcedureTile(entry.value[index]),
//         );
//       }).toList(),
//     );
//   }

//   Widget _buildProcedureTile(Procedures procedure) {
//     return ProcedureTileWidget(
//       procedure: procedure.procedureDesc,
//       onChanged: (percentage) {
//         setState(() {
//           _selectedPercentages[procedure.procedureId] = percentage;
//         });
//       },
//       onNoteChanged: (note) {
//         _notesControllers[procedure.procedureId]?.text = note;
//       },
//       selectedPercentage: _selectedPercentages[procedure.procedureId],
//       note: _notesControllers[procedure.procedureId]?.text,
//       hidePercentage: _hidePercentage,
//     );
//   }

//   void _saveProcedures() {
//     final selectedProcedures = <Map<String, dynamic>>[];

//     for (var procedures in _categorizedProcedures.values) {
//       for (var proc in procedures) {
//         final percentage = _selectedPercentages[proc.procedureId];
//         final notes = _notesControllers[proc.procedureId]?.text ?? '';

//         if (percentage != null || notes.isNotEmpty) {
//           selectedProcedures.add({
//             'id': proc.id,
//             'procedureId': proc.procedureId,
//             'percentage': percentage,
//             'notes': notes
//           });
//         }
//       }
//     }

//     uploadSelectedProcedures(selectedProcedures);
//   }

//   void uploadSelectedProcedures(selectedProcedures) async {
//     await context.read<UploadPatientVisitsCubit>().uploadPatientVisits(
//           0,
//           selectedProcedures,
//           "imageName",
//           "",
//         );
//     ();
//   }
// }

// class ProcedureTileWidget extends StatefulWidget {
//   final String procedure;
//   final ValueChanged<int?> onChanged;
//   final ValueChanged<String> onNoteChanged;
//   final int? selectedPercentage;
//   final String? note;
//   final bool hidePercentage;

//   const ProcedureTileWidget({
//     super.key,
//     required this.procedure,
//     required this.onChanged,
//     required this.onNoteChanged,
//     required this.hidePercentage,
//     this.selectedPercentage,
//     this.note,
//   });

//   @override
//   State<ProcedureTileWidget> createState() => _ProcedureTileWidgetState();
// }

// class _ProcedureTileWidgetState extends State<ProcedureTileWidget> {
//   bool _isSelected = false;
//   late final TextEditingController _noteController;

//   @override
//   void initState() {
//     super.initState();
//     _noteController = TextEditingController(text: widget.note);
//     _isSelected = widget.selectedPercentage != null;
//   }

//   @override
//   void dispose() {
//     _noteController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
//       child: Padding(
//         padding: const EdgeInsets.all(12.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(widget.procedure,
//                 style:
//                     const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//             const SizedBox(height: 12),
//             if (!widget.hidePercentage)
//               _buildPercentageSelector()
//             else
//               _buildCheckbox(),
//             const SizedBox(height: 12),
//             _buildNotesField(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildPercentageSelector() {
//     final percentages = [
//       {1: 25},
//       {2: 50},
//       {3: 75},
//       {4: 100}
//     ];

//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: percentages.map((percent) {
//         final key = percent.keys.first;
//         final value = percent.values.first;

//         return ChoiceChip(
//           label: Text("$value%"),
//           selected: widget.selectedPercentage == key,
//           onSelected: (selected) {
//             widget.onChanged(selected ? key : null);
//           },
//         );
//       }).toList(),
//     );
//   }

//   Widget _buildCheckbox() {
//     return Row(
//       children: [
//         Checkbox(
//           value: _isSelected,
//           onChanged: (selected) {
//             setState(() {
//               _isSelected = selected ?? false;
//               widget.onChanged(_isSelected ? 4 : null);
//             });
//           },
//         ),
//         const Text("Select")
//       ],
//     );
//   }

//   Widget _buildNotesField() {
//     return TextField(
//       controller: _noteController,
//       onChanged: widget.onNoteChanged,
//       decoration: const InputDecoration(
//         labelText: "Notes",
//         border: OutlineInputBorder(),
//       ),
//       maxLines: 2,
//     );
//   }
// }














































































import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hand_write_notes/core/failed_msg_screen_widget.dart';
import '../../../../get_proc_cubit/cubit/get_proc_cubit.dart';
import '../../../../patients_visits_insert_cubit/cubit/upload_patient_visits_cubit.dart';
import '../../../../settings.dart';
import '../../../data/proc_model.dart';

/// Enhanced procedure selection screen with modern UI/UX
class ProcedureSelectionScreen extends StatefulWidget {
  const ProcedureSelectionScreen({super.key});

  @override
  State<ProcedureSelectionScreen> createState() =>
      _ProcedureSelectionScreenState();
}

class _ProcedureSelectionScreenState extends State<ProcedureSelectionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, List<Procedures>> _categorizedProcedures = {};
  final Map<String, List<Procedures>> _filteredProcedures = {};
  final Map<int, int?> _selectedPercentages = {};
  final Map<int, TextEditingController> _notesControllers = {};
  final TextEditingController _searchController = TextEditingController();
  bool _hidePercentage = false;
  bool _isSearchActive = false;
  final _settings = SettingsService();

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadSettings();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _notesControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  void _loadData() {
    context.read<GetProcCubit>().fetchPatientsWithSoapRequest(
        "SELECT mp.Main_Procedure_id,mp.Main_Procedure_Desc,pp.Procedure_Desc,pp.Procedure_id "
        "FROM Patients_Main_Procedures mp "
        "INNER JOIN Patients_Procedures pp ON mp.Main_Procedure_id = pp.Main_Procedure_id");
  }

  Future<void> _loadSettings() async {
    await _settings.init();
    setState(() {
      _hidePercentage = _settings.getBool(AppSettingsKeys.hidePercentage);
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredProcedures.clear();
        _filteredProcedures.addAll(_categorizedProcedures);
      } else {
        _filteredProcedures.clear();
        _categorizedProcedures.forEach((category, procedures) {
          final filtered = procedures
              .where((proc) =>
                  proc.procedureDesc.toLowerCase().contains(query) ||
                  category.toLowerCase().contains(query))
              .toList();
          if (filtered.isNotEmpty) {
            _filteredProcedures[category] = filtered;
          }
        });
      }
    });
  }

  void _handleProceduresLoaded(List<Procedures> procedures) {
    _categorizedProcedures.clear();
    _filteredProcedures.clear();

    for (var proc in procedures) {
      _categorizedProcedures
          .putIfAbsent(proc.mainProcedureDesc, () => [])
          .add(proc);

      _selectedPercentages[proc.procedureId] =
          proc.procStatus > 0 ? proc.procStatus : null;

      _notesControllers[proc.procedureId] =
          TextEditingController(text: proc.notes);
    }

    _filteredProcedures.addAll(_categorizedProcedures);

    _tabController = TabController(
        length: _filteredProcedures.keys.length, vsync: this);
  }

  Future<void> _onRefresh() async {
    _loadData();
  }

  int get _selectedCount {
    return _selectedPercentages.values.where((v) => v != null).length +
        _notesControllers.values.where((c) => c.text.isNotEmpty).length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _isSearchActive
              ? TextField(
                  key: const ValueKey('search'),
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search procedures...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
                  ),
                  style: theme.textTheme.titleLarge,
                )
              : Text(
                  'Select Procedures',
                  key: const ValueKey('title'),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
        actions: [
          IconButton(
            icon: Icon(_isSearchActive ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearchActive = !_isSearchActive;
                if (!_isSearchActive) {
                  _searchController.clear();
                }
              });
            },
          ),
          if (_selectedCount > 0)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '$_selectedCount selected',
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: BlocConsumer<GetProcCubit, GetProcState>(
        listener: (context, state) {
          if (state is GetProcSuccess) {
            _handleProceduresLoaded(state.proc);
          }
        },
        builder: (context, state) {
          if (state is GetProcSuccess && _filteredProcedures.isNotEmpty) {
            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: _buildProceduresList(),
            );
          } else if (state is GetProcSuccess && _filteredProcedures.isEmpty) {
            return _buildEmptyState();
          } else if (state is GetProcFailed) {
            return _buildErrorState(state);
          }
          return _buildLoadingState();
        },
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        Container(
          height: 48,
          margin: const EdgeInsets.all(16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 4,
            itemBuilder: (context, index) => Container(
              margin: const EdgeInsets.only(right: 12),
              child: _buildShimmerTab(),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 6,
            itemBuilder: (context, index) => _buildShimmerCard(),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerTab() {
    return Container(
      width: 120,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(
        child: SizedBox(
          width: 80,
          height: 16,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 20,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(
                4,
                (index) => Container(
                  margin: const EdgeInsets.only(right: 8),
                  width: 60,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 48,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchController.text.isNotEmpty
                ? 'No procedures found'
                : 'No procedures available',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty
                ? 'Try adjusting your search terms'
                : 'Pull to refresh or try again later',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchController.text.isNotEmpty) ...[
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                _searchController.clear();
              },
              icon: const Icon(Icons.clear),
              label: const Text('Clear search'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState(GetProcFailed state) {
    return WarningMsgScreen(
      state: state,
      onRefresh: _onRefresh,
      msg: state.error,
    );
  }

  Widget _buildProceduresList() {
    return Column(
      children: [
        if (_filteredProcedures.keys.length > 1) _buildTabBar(),
        Expanded(child: _buildTabBarView()),
      ],
    );
  }

  Widget _buildTabBar() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicator: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(24),
        ),
        labelColor: colorScheme.onPrimaryContainer,
        unselectedLabelColor: colorScheme.onSurface.withOpacity(0.7),
        labelStyle: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: theme.textTheme.labelLarge,
        tabs: _filteredProcedures.keys.map((category) {
          final count = _filteredProcedures[category]?.length ?? 0;
          return Tab(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(category),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.outline.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$count',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabBarView() {
    if (_filteredProcedures.keys.length == 1) {
      final procedures = _filteredProcedures.values.first;
      return _buildProcedureList(procedures);
    }

    return TabBarView(
      controller: _tabController,
      children: _filteredProcedures.entries.map((entry) {
        return _buildProcedureList(entry.value);
      }).toList(),
    );
  }

  Widget _buildProcedureList(List<Procedures> procedures) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: procedures.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildProcedureTile(procedures[index]),
      ),
    );
  }

  Widget _buildProcedureTile(Procedures procedure) {
    return ProcedureTileWidget(
      key: ValueKey(procedure.procedureId),
      procedure: procedure.procedureDesc,
      onChanged: (percentage) {
        setState(() {
          _selectedPercentages[procedure.procedureId] = percentage;
        });
      },
      onNoteChanged: (note) {
        _notesControllers[procedure.procedureId]?.text = note;
      },
      selectedPercentage: _selectedPercentages[procedure.procedureId],
      note: _notesControllers[procedure.procedureId]?.text,
      hidePercentage: _hidePercentage,
    );
  }

  Widget _buildFloatingActionButton() {
    return BlocConsumer<UploadPatientVisitsCubit, UploadPatientVisitsState>(
      listener: (context, state) {
        if (state is UploadPatientVisitsSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Procedures uploaded successfully!'),
                ],
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        } else if (state is UploadPatientVisitsFailed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Upload Failed: ${state.error}')),
                ],
              ),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: _saveProcedures,
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is UploadingPatientVisits) {
          return const FloatingActionButton(
            onPressed: null,
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          );
        }

        return FloatingActionButton.extended(
          onPressed: _selectedCount > 0 ? _showSaveConfirmation : null,
          icon: const Icon(Icons.save),
          label: Text('Save ($_selectedCount)'),
        );
      },
    );
  }

  void _showSaveConfirmation() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Procedures'),
        content: Text(
          'Are you sure you want to save $_selectedCount selected procedures?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _saveProcedures();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _saveProcedures() {
    final selectedProcedures = <Map<String, dynamic>>[];

    for (var procedures in _categorizedProcedures.values) {
      for (var proc in procedures) {
        final percentage = _selectedPercentages[proc.procedureId];
        final notes = _notesControllers[proc.procedureId]?.text ?? '';

        if (percentage != null || notes.isNotEmpty) {
          selectedProcedures.add({
            'id': proc.id,
            'procedureId': proc.procedureId,
            'percentage': percentage,
            'notes': notes
          });
        }
      }
    }

    uploadSelectedProcedures(selectedProcedures);
  }

  void uploadSelectedProcedures(selectedProcedures) async {
    await context.read<UploadPatientVisitsCubit>().uploadPatientVisits(
          0,
          selectedProcedures,
          "imageName",
          "",
        );
  }
}

class ProcedureTileWidget extends StatefulWidget {
  final String procedure;
  final ValueChanged<int?> onChanged;
  final ValueChanged<String> onNoteChanged;
  final int? selectedPercentage;
  final String? note;
  final bool hidePercentage;

  const ProcedureTileWidget({
    super.key,
    required this.procedure,
    required this.onChanged,
    required this.onNoteChanged,
    required this.hidePercentage,
    this.selectedPercentage,
    this.note,
  });

  @override
  State<ProcedureTileWidget> createState() => _ProcedureTileWidgetState();
}

class _ProcedureTileWidgetState extends State<ProcedureTileWidget>
    with SingleTickerProviderStateMixin {
  bool _isSelected = false;
  bool _isExpanded = false;
  late final TextEditingController _noteController;
  late final AnimationController _animationController;
  late final Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.note);
    _isSelected = widget.selectedPercentage != null;
    _isExpanded = widget.note?.isNotEmpty ?? false;
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    if (_isExpanded) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = widget.selectedPercentage != null || 
                      (_noteController.text.isNotEmpty);

    return Card(
      elevation: isSelected ? 4 : 1,
      surfaceTintColor: isSelected ? colorScheme.primary : null,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: colorScheme.primary, width: 2)
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.medical_services_outlined,
                    color: isSelected 
                        ? colorScheme.primary 
                        : colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.procedure,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? colorScheme.primary : null,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Selected',
                        style: TextStyle(
                          color: colorScheme.onPrimaryContainer,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (!widget.hidePercentage)
                _buildPercentageSelector()
              else
                _buildCheckbox(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.note_add_outlined,
                    size: 20,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Notes',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _toggleExpanded,
                    icon: AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: const Icon(Icons.expand_more),
                    ),
                  ),
                ],
              ),
              SizeTransition(
                sizeFactor: _expandAnimation,
                child: _buildNotesField(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPercentageSelector() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final percentages = [
      {1: 25},
      {2: 50},
      {3: 75},
      {4: 100}
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: percentages.map((percent) {
        final key = percent.keys.first;
        final value = percent.values.first;
        final isSelected = widget.selectedPercentage == key;

        return FilterChip(
          label: Text('$value%'),
          selected: isSelected,
          onSelected: (selected) {
            widget.onChanged(selected ? key : null);
          },
          showCheckmark: false,
          selectedColor: colorScheme.primaryContainer,
          backgroundColor: colorScheme.surfaceVariant.withOpacity(0.5),
          labelStyle: TextStyle(
            color: isSelected 
                ? colorScheme.onPrimaryContainer 
                : colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCheckbox() {
    final theme = Theme.of(context);
    return Row(
      children: [
        Checkbox(
          value: _isSelected,
          onChanged: (selected) {
            setState(() {
              _isSelected = selected ?? false;
              widget.onChanged(_isSelected ? 4 : null);
            });
          },
        ),
        const SizedBox(width: 8),
        Text(
          'Select this procedure',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TextField(
        controller: _noteController,
        onChanged: widget.onNoteChanged,
        decoration: InputDecoration(
          hintText: 'Add notes for this procedure...',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
          counterText: '${_noteController.text.length}/500',
        ),
        maxLines: 3,
        maxLength: 500,
      ),
    );
  }
}






















// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:hand_write_notes/core/failed_msg_screen_widget.dart';
// import '../../../../get_proc_cubit/cubit/get_proc_cubit.dart';
// import '../../../../settings.dart';
// import '../../../data/proc_model.dart';
// class ProcedureSelectionDialog extends StatefulWidget {
//   const ProcedureSelectionDialog({super.key});
//   @override
//   _ProcedureSelectionDialogState createState() =>
//       _ProcedureSelectionDialogState();
// }
// class _ProcedureSelectionDialogState extends State<ProcedureSelectionDialog> {
//   List<bool> selectedProcedures = [];
//   List<Procedures> procedures = [];
//   List<Map<int, int>> percentageProc = [];
//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       title: const Text("Select Procedures"),
//       content: SingleChildScrollView(
//         child: BlocConsumer<GetProcCubit, GetProcState>(
//           listener: (context, state) {
//             if (state is GetProcSuccess) {
//               selectedProcedures =
//                   List.generate(state.proc.length, (index) => false);
//               procedures = state.proc;
//             }
//           },
//           builder: (context, state) {
//             if (state is GetProcSuccess) {
//               return Column(
//                 children: List.generate(state.proc.length, (index) {
//                   return CheckboxListTile(
//                     title: Text(state.proc[index].procedureDesc),
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
//         TextButton(
//           onPressed: () {
//             Navigator.of(context).pop([9999]);
//           },
//           child: const Text("Cancel"),
//         ),
//         TextButton(
//           onPressed: () {
//             List<int> selected = [];
//             for (int i = 0; i < selectedProcedures.length; i++) {
//               if (selectedProcedures[i]) {
//                 selected.add(procedures[i].procedureId);
//               }
//             }
//             Navigator.of(context).pop(selected);
//           },
//           child: const Text("Upload"),
//         ),
//       ],
//     );
//   }
// }
// class ProceduresDialog extends StatefulWidget {
//   const ProceduresDialog({super.key});
//   @override
//   _ProceduresDialogState createState() => _ProceduresDialogState();
// }
// class _ProceduresDialogState extends State<ProceduresDialog> {
//   List<Procedures> procedures = []; // To store fetched procedures
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
//   late List<int?> vals;
//   late List<TextEditingController>
//       notesControllers; // Stores notes for procedures
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
//                 vals = List.generate(state.proc.length, (index) => null);
//                 // .map((proc) => {
//                 //       'id': proc.procedureId,
//                 //       'name': proc.procedureDesc,
//                 //       'percentage': null
//                 //     })
//                 // .toList();
//                 notesControllers = procedures
//                     .map((proc) => TextEditingController(text: null))
//                     .toList();
//               });
//             } else if (state is GetProcFailed) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(
//                     content: Text('Failed to load procedures: ${state.error}')),
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
//                   return ProcedureTile(
//                     notesController: notesControllers[index],
//                     procedure: procedures[index],
//                     percentageOptions: procStatus,
//                     val: vals[index],
//                     onChanged: (selectedPercentage) {
//                       setState(() {
//                         vals[index] = selectedPercentage;
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
//             // Filter and return only selected procedures with percentages
//             final selectedProcedures = [];
//             for (int i = 0; i < procedures.length; i++) {
//               if (vals[i] != null) {
//                 selectedProcedures.add({
//                   'procedureId': procedures[i].procedureId,
//                   'percentage': vals[i],
//                   'notes': notesControllers[i].text
//                 });
//               }
//             }
//             Navigator.of(context).pop(selectedProcedures);
//           },
//           child: const Text('Save'),
//         ),
//       ],
//     );
//   }
// }
// class ProcedureTile extends StatelessWidget {
//   final Procedures procedure;
//   final List<DropdownMenuItem<int>> percentageOptions;
//   final ValueChanged<int?> onChanged;
//   final TextEditingController notesController;
//   final int? val;
//   const ProcedureTile({
//     super.key,
//     required this.procedure,
//     required this.percentageOptions,
//     required this.onChanged,
//     required this.notesController,
//     this.val,
//   });
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: const EdgeInsets.symmetric(vertical: 8.0),
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
//                     value: val,
//                     hint: const Text('Select %'),
//                     items: percentageOptions,
//                     onChanged: onChanged,
//                   ),
//                 ),
//               ],
//             ),
//             TextField(
//               controller: notesController,
//               decoration: const InputDecoration(
//                 labelText: 'Notes',
//                 border: OutlineInputBorder(),
//               ),
//               maxLines: 2,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
// class ProcedureSelectionScreen extends StatefulWidget {
//   const ProcedureSelectionScreen({super.key});
//   @override
//   _ProcedureSelectionScreenState createState() =>
//       _ProcedureSelectionScreenState();
// }
// class _ProcedureSelectionScreenState extends State<ProcedureSelectionScreen>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   Map<String, List<Procedures>> categorizedProcedures =
//       {}; // Main Category -> Procedures
//   Map<int, int?> selectedPercentages = {};
//   Map<int, TextEditingController> notesControllers = {};
//   bool hidePercentage = false;
//   final _settings = SettingsService();
//   Future<void> _loadSetting() async {
//     await _settings.init();
//     setState(() {
//       hidePercentage = _settings.getBool(AppSettingsKeys.hidePercentage);
//     });
//   }
//   @override
//   void initState() {
//     super.initState();
//     _loadSetting();
//   }
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Select Procedures")),
//       body: BlocConsumer<GetProcCubit, GetProcState>(
//         listener: (context, state) {
//           if (state is GetProcSuccess) {
//             // Categorizing procedures
//             for (var proc in state.proc) {
//               categorizedProcedures
//                   .putIfAbsent(proc.mainProcedureDesc, () => [])
//                   .add(proc);
//               selectedPercentages[proc.procedureId] =
//                   proc.procStatus > 0 ? proc.procStatus : null;
//               notesControllers[proc.procedureId] =
//                   TextEditingController(text: proc.notes);
//             }
//             // Create tab controller after fetching data
//             _tabController = TabController(
//                 length: categorizedProcedures.keys.length, vsync: this);
//             setState(() {});
//           }
//         },
//         builder: (context, state) {
//           if (state is GetProcSuccess && categorizedProcedures.isNotEmpty) {
//             return DefaultTabController(
//               length: categorizedProcedures.keys.length,
//               child: Column(
//                 children: [
//                   TabBar(
//                     labelStyle: const TextStyle(
//                         fontWeight: FontWeight.bold, fontSize: 16),
//                     controller: _tabController,
//                     isScrollable: true,
//                     tabs: categorizedProcedures.keys
//                         .map((category) => Tab(text: category))
//                         .toList(),
//                   ),
//                   Expanded(
//                     child: TabBarView(
//                       controller: _tabController,
//                       children: categorizedProcedures.entries.map((entry) {
//                         return ListView.builder(
//                           itemCount: entry.value.length,
//                           itemBuilder: (context, index) {
//                             var procedure = entry.value[index];
//                             return ProcedureTile1(
//                               procedure: procedure.procedureDesc,
//                               onChanged: (percentage) {
//                                 setState(() {
//                                   selectedPercentages[procedure.procedureId] =
//                                       percentage;
//                                 });
//                               },
//                               onNoteChanged: (note) {
//                                 notesControllers[procedure.procedureId]?.text =
//                                     note;
//                               },
//                               selectedPercentage:
//                                   selectedPercentages[procedure.procedureId],
//                               note:
//                                   notesControllers[procedure.procedureId]?.text,
//                               hidePercentage: hidePercentage,
//                             );
//                           },
//                         );
//                       }).toList(),
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           } else if (state is GetProcFailed) {
//             return WarningMsgScreen(
//                 state: state, onRefresh: () async {}, msg: state.error);
//           } else {
//             return const Center(child: CircularProgressIndicator());
//           }
//         },
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           final List<Map<String, dynamic>> selectedProcedures = [];

// // Iterate through all categories
//           for (var entry in categorizedProcedures.entries) {
//             List<Procedures> procedures =
//                 entry.value; // List of procedures in the category

//             for (int i = 0; i < procedures.length; i++) {
//               int procedureId = procedures[i].procedureId;
//               int? selectedPercentage =
//                   selectedPercentages[procedureId]; // Get selected percentage
//               String notes = notesControllers[procedureId]?.text ??
//                   ""; // Get notes (if any)

//               if (selectedPercentage != null || notes.isNotEmpty) {
//                 selectedProcedures.add({
//                   'id': procedures[i].id,
//                   'procedureId': procedureId,
//                   'percentage': selectedPercentage,
//                   'notes': notes
//                 });
//               }
//             }
//           }

//           Navigator.of(context).pop(selectedProcedures);
//         },
//         child: const Icon(Icons.save),
//       ),
//     );
//   }
// }

// class ProcedureTile1 extends StatefulWidget {
//   final String procedure;
//   final ValueChanged<int?> onChanged;
//   final ValueChanged<String> onNoteChanged;
//   final int? selectedPercentage;
//   final String? note;
//   final bool hidePercentage;

//   const ProcedureTile1({
//     super.key,
//     required this.procedure,
//     required this.onChanged,
//     required this.onNoteChanged,
//     this.selectedPercentage,
//     this.note,
//     required this.hidePercentage,
//   });

//   @override
//   State<ProcedureTile1> createState() => _ProcedureTile1State();
// }

// class _ProcedureTile1State extends State<ProcedureTile1> {
//   bool isSelected = false;
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
//       child: Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(widget.procedure,
//                 style:
//                     const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//             const SizedBox(height: 10),
//             if (!widget.hidePercentage)
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   for (var percent in [
//                     {1: 25},
//                     {2: 50},
//                     {3: 75},
//                     {4: 100}
//                   ])
//                     ChoiceChip(
//                       label: Text("${percent.values.first}%"),
//                       selected: widget.selectedPercentage == percent.keys.first,
//                       onSelected: (selected) {
//                         widget.onChanged(selected ? percent.keys.first : null);
//                       },
//                     ),
//                 ],
//               ),
//             if (widget.hidePercentage)
//               Row(
//                 children: [
//                   Checkbox(
//                     value: isSelected,
//                     onChanged: (selected) {
//                       widget.onChanged((selected ?? false) ? 4 : null);
//                       setState(() {
//                         isSelected = selected ?? false;
//                       });
//                     },
//                   ),
//                   const Text("Select")
//                 ],
//               ),
//             const SizedBox(height: 10),
//             TextField(
//               onChanged: widget.onNoteChanged,
//               decoration: const InputDecoration(
//                 labelText: "Notes",
//                 border: OutlineInputBorder(),
//               ),
//               controller: TextEditingController(text: widget.note),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }





















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






