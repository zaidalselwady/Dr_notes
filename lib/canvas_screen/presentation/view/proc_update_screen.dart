import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hand_write_notes/core/failed_msg_screen_widget.dart';
import '../../../../get_proc_cubit/cubit/get_proc_cubit.dart';
import '../../../update_patient_state_cubit/cubit/update_patient_state_cubit.dart';
import '../../data/proc_model.dart';

/// Screen for managing procedures and categories
///
/// IMPORTANT: Database relationships are ID-based, not description-based:
/// - Procedure_id: Primary key that other tables link to
/// - Main_Procedure_id: Foreign key linking to Patients_Main_Procedures.Main_Procedure_id
/// - Descriptions (Procedure_Desc, Main_Procedure_Desc) are for display only
///
/// Operations:
/// - Edit Name: Changes description only, preserves all ID relationships
/// - Change Category: Updates Main_Procedure_id foreign key, affects table relationships
/// - Delete: Removes Procedure_id, may break references in other tables
class ProcedureManagementScreen extends StatefulWidget {
  const ProcedureManagementScreen({super.key});

  @override
  State<ProcedureManagementScreen> createState() =>
      _ProcedureManagementScreenState();
}

class _ProcedureManagementScreenState extends State<ProcedureManagementScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final List<Procedures> _allProcedures = [];
  List<Procedures> _filteredProcedures = [];
  List<String> _categories = [];
  Map<String, int> _categoryIdMap =
      {}; // Maps category name to Main_Procedure_id
  Set<String> _editingProcedures = {};
  Map<int, TextEditingController> _editControllers = {};
  String _selectedFilter = 'All Categories';

  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterProcedures);
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeOut),
    );
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fabAnimationController.dispose();
    _editControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  void _loadData() {
    // Fetch procedures with main procedure information
    context.read<GetProcCubit>().fetchPatientsWithSoapRequest(
        "SELECT pp.Procedure_id, pp.Procedure_Desc, pp.Main_Procedure_id, "
        "mp.Main_Procedure_Desc "
        "FROM Patients_Procedures pp "
        "LEFT JOIN Patients_Main_Procedures mp ON pp.Main_Procedure_id = mp.Main_Procedure_id "
        "ORDER BY mp.Main_Procedure_Desc, pp.Procedure_Desc");
  }

  void _loadMainProcedures() {
    // Fetch all main procedures for category management
    context.read<GetProcCubit>().fetchPatientsWithSoapRequest(
        "SELECT Main_Procedure_id, Main_Procedure_Desc "
        "FROM Patients_Main_Procedures "
        "ORDER BY Main_Procedure_Desc");
  }

  Future<void> _onRefresh() async {
    _loadData();
  }

  void _handleProceduresLoaded(List<Procedures> procedures) {
    _allProcedures.clear();
    _allProcedures.addAll(procedures);

    // Build category mappings
    _categoryIdMap.clear();
    final uniqueCategories = <String>{};

    for (var proc in procedures) {
      if (proc.mainProcedureDesc.isNotEmpty) {
        uniqueCategories.add(proc.mainProcedureDesc);
        _categoryIdMap[proc.mainProcedureDesc] = proc.mainProcedureId;
      }
    }

    _categories = ['All Categories', ...uniqueCategories.toList()..sort()];
    _filterProcedures();

    _fabAnimationController.forward();
  }

  void _filterProcedures() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProcedures = _allProcedures.where((procedure) {
        final matchesSearch =
            procedure.procedureDesc.toLowerCase().contains(query) ||
                procedure.mainProcedureDesc.toLowerCase().contains(query);
        final matchesCategory = _selectedFilter == 'All Categories' ||
            procedure.mainProcedureDesc == _selectedFilter;
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  void _startEditing(Procedures procedure) {
    setState(() {
      _editingProcedures.add('${procedure.procedureId}');
      _editControllers[procedure.procedureId] =
          TextEditingController(text: procedure.procedureDesc);
    });
  }

  void _cancelEditing(int procedureId) {
    setState(() {
      _editingProcedures.remove('$procedureId');
      _editControllers[procedureId]?.dispose();
      _editControllers.remove(procedureId);
    });
  }

  void _saveEdit(Procedures procedure) async {
    final newName = _editControllers[procedure.procedureId]?.text.trim();
    if (newName == null || newName.isEmpty) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white)),
            ),
            SizedBox(width: 12),
            Text('Updating description only (ID relationships preserved)...'),
          ],
        ),
      ),
    );

    try {
      // NOTE: This only updates the display description, not the Procedure_id
      // All table relationships remain intact as they link via Procedure_id
      final updateQuery =
          "UPDATE Patients_Procedures SET Procedure_Desc = '$newName' WHERE Procedure_id = ${procedure.procedureId}";

      // You'll need to implement this method in your cubit
      await context
          .read<UpdatePatientStateCubit>()
          .updatePatient(updateQuery, true);

      // Update the procedure locally
      // final index = _allProcedures
      //     .indexWhere((p) => p.procedureId == procedure.procedureId);
      // if (index != -1) {
      //   setState(() {
      //     _allProcedures[index] = Procedures(
      //       id: procedure.id,
      //       procedureId: procedure
      //           .procedureId, // ID stays the same - relationships preserved
      //       procedureDesc: newName, // Only description changes
      //       mainProcedureDesc: procedure.mainProcedureDesc,
      //       mainProcedureId: procedure.mainProcedureId,
      //       procStatus: procedure.procStatus,
      //       visitDate: procedure.visitDate,
      //       notes: procedure.notes,
      //       procIdPv: procedure.procIdPv,
      //       patientId: procedure.patientId,
      //     );
      //     _editingProcedures.remove('${procedure.procedureId}');
      //     _editControllers[procedure.procedureId]?.dispose();
      //     _editControllers.remove(procedure.procedureId);
      //   });
      //   _filterProcedures();

      //   scaffoldMessenger.hideCurrentSnackBar();
      //   scaffoldMessenger.showSnackBar(
      //     const SnackBar(
      //       content: Row(
      //         children: [
      //           Icon(Icons.check_circle, color: Colors.white),
      //           SizedBox(width: 12),
      //           Text('Description updated (all ID relationships preserved)!'),
      //         ],
      //       ),
      //       backgroundColor: Colors.green,
      //     ),
      //   );
      // }
    } catch (e) {
      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Text('Failed to update: ${e.toString()}'),
            ],
          ),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () => _saveEdit(procedure),
          ),
        ),
      );
    }
  }

  void _updateCategory(Procedures procedure, String newCategoryName) async {
    final newMainProcedureId = _categoryIdMap[newCategoryName];
    if (newMainProcedureId == null) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                  'Updating relationship: Procedure ${procedure.procedureId} → Main Procedure $newMainProcedureId'),
            ),
          ],
        ),
      ),
    );

    try {
      // IMPORTANT: This updates the foreign key relationship, not just display
      // All tables linked to this Procedure_id will now reference the new Main_Procedure_id
      final updateQuery =
          "UPDATE Patients_Procedures SET Main_Procedure_id = $newMainProcedureId WHERE Procedure_id = ${procedure.procedureId}";

      // You'll need to implement this method in your cubit
      await context
          .read<UpdatePatientStateCubit>()
          .updatePatient(updateQuery, true);

      // Update the procedure category locally
      final index = _allProcedures
          .indexWhere((p) => p.procedureId == procedure.procedureId);
      if (index != -1) {
        setState(() {
          _allProcedures[index] = Procedures(
            id: procedure.id,
            procedureId: procedure.procedureId,
            procedureDesc: procedure.procedureDesc,
            mainProcedureDesc: newCategoryName,
            mainProcedureId: newMainProcedureId,
            procStatus: procedure.procStatus,
            visitDate: procedure.visitDate,
            notes: procedure.notes,
            procIdPv: procedure.procIdPv,
            patientId: procedure.patientId,
          );
        });
        _filterProcedures();

        scaffoldMessenger.hideCurrentSnackBar();
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Procedure relationship updated successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Text('Failed to update: ${e.toString()}'),
            ],
          ),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () => _updateCategory(procedure, newCategoryName),
          ),
        ),
      );
    }
  }

  void _deleteProcedure(Procedures procedure) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Procedure'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Are you sure you want to delete "${procedure.procedureDesc}"?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border.all(color: Colors.orange.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning,
                          color: Colors.orange.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Important:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This will permanently delete Procedure ID: ${procedure.procedureId}\n\n'
                    'All tables linked to this ID will lose their references. '
                    'This could affect patient visits, billing, and other related records.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'This action cannot be undone.',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);

              final scaffoldMessenger = ScaffoldMessenger.of(context);
              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white)),
                      ),
                      SizedBox(width: 12),
                      Text('Deleting procedure...'),
                    ],
                  ),
                ),
              );

              try {
                // Execute DELETE query
                final deleteQuery =
                    "DELETE FROM Patients_Procedures WHERE Procedure_id = ${procedure.procedureId}";

                // You'll need to implement this method in your cubit
                // await context.read<GetProcCubit>().executeUpdateQuery(deleteQuery);

                // For now, simulating the API call
                await Future.delayed(const Duration(seconds: 1));

                setState(() {
                  _allProcedures.removeWhere(
                      (p) => p.procedureId == procedure.procedureId);
                });
                _filterProcedures();

                scaffoldMessenger.hideCurrentSnackBar();
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 12),
                        Text('Procedure deleted successfully!'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                scaffoldMessenger.hideCurrentSnackBar();
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.white),
                        const SizedBox(width: 12),
                        Text('Failed to delete: ${e.toString()}'),
                      ],
                    ),
                    backgroundColor: Colors.red,
                    action: SnackBarAction(
                      label: 'Retry',
                      textColor: Colors.white,
                      onPressed: () => _deleteProcedure(procedure),
                    ),
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddProcedureDialog() {
    final nameController = TextEditingController();
    final categoryController = TextEditingController();
    String? selectedCategory;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New Procedure'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Procedure Name',
                    border: OutlineInputBorder(),
                    hintText: 'Enter procedure description',
                  ),
                  maxLength: 75, // Based on nvarchar(75) in database
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    ..._categories.where((c) => c != 'All Categories').map(
                          (category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ),
                        ),
                    const DropdownMenuItem(
                      value: 'new',
                      child: Text('+ Create New Category'),
                    ),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedCategory = value;
                    });
                  },
                ),
                if (selectedCategory == 'new') ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: categoryController,
                    decoration: const InputDecoration(
                      labelText: 'New Category Name',
                      border: OutlineInputBorder(),
                      hintText: 'Enter main procedure description',
                    ),
                    maxLength: 75, // Based on nvarchar(75) in database
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final category = selectedCategory == 'new'
                    ? categoryController.text.trim()
                    : selectedCategory;

                if (name.isNotEmpty &&
                    category != null &&
                    category.isNotEmpty) {
                  Navigator.pop(context);

                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white)),
                          ),
                          SizedBox(width: 12),
                          Text('Adding procedure...'),
                        ],
                      ),
                    ),
                  );

                  try {
                    int mainProcedureId;

                    if (selectedCategory == 'new') {
                      // First, add the new main procedure category
                      final insertMainProcQuery =
                          "INSERT INTO Patients_Main_Procedures (Main_Procedure_Desc) VALUES ('$category')";

                      // You'll need to implement this and get the inserted ID
                      // mainProcedureId = await context.read<GetProcCubit>().executeInsertQuery(insertMainProcQuery);

                      // For simulation, use a timestamp as ID
                      mainProcedureId = DateTime.now().millisecondsSinceEpoch %
                          32767; // smallint max
                    } else {
                      mainProcedureId = _categoryIdMap[category] ?? 1;
                    }

                    // Then add the procedure
                    final insertProcQuery =
                        "INSERT INTO Patients_Procedures (Procedure_Desc, Main_Procedure_id) VALUES ('$name', $mainProcedureId)";

                    // You'll need to implement this
                    // await context.read<GetProcCubit>().executeInsertQuery(insertProcQuery);

                    // For now, simulating the API call
                    await Future.delayed(const Duration(seconds: 1));

                    // Reload data from server to get the latest
                    _loadData();

                    scaffoldMessenger.hideCurrentSnackBar();
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.white),
                            SizedBox(width: 12),
                            Text('Procedure added successfully!'),
                          ],
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    scaffoldMessenger.hideCurrentSnackBar();
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.error, color: Colors.white),
                            const SizedBox(width: 12),
                            Text('Failed to add: ${e.toString()}'),
                          ],
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
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
        title: Text(
          'Manage Procedures',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _onRefresh,
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
          return Column(
            children: [
              _buildSearchAndFilter(),
              if (state is GetProcSuccess && _allProcedures.isNotEmpty)
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _onRefresh,
                    child: _filteredProcedures.isEmpty
                        ? _buildEmptyState()
                        : _buildProceduresList(),
                  ),
                )
              else if (state is GetProcSuccess && _allProcedures.isEmpty)
                Expanded(child: _buildEmptyState())
              else if (state is GetProcFailed)
                Expanded(child: _buildErrorState(state))
              else
                Expanded(child: _buildLoadingState()),
            ],
          );
        },
      ),
      // floatingActionButton: BlocBuilder<GetProcCubit, GetProcState>(
      //   builder: (context, state) {
      //     if (state is GetProcSuccess) {
      //       return ScaleTransition(
      //         scale: _fabAnimation,
      //         child: FloatingActionButton.extended(
      //           onPressed: _showAddProcedureDialog,
      //           icon: const Icon(Icons.add),
      //           label: const Text('Add Procedure'),
      //         ),
      //       );
      //     }
      //     return const SizedBox.shrink();
      //   },
      // ),
    );
  }

  Widget _buildSearchAndFilter() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search procedures...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
            ),
          ),
          if (_categories.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = category == _selectedFilter;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = category;
                        });
                        _filterProcedures();
                      },
                      showCheckmark: false,
                      selectedColor: colorScheme.primaryContainer,
                      backgroundColor:
                          colorScheme.surfaceVariant.withOpacity(0.5),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurface,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 8,
      itemBuilder: (context, index) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 16,
                width: 120,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 14,
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
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
              _searchController.text.isNotEmpty
                  ? Icons.search_off
                  : Icons.medical_services_outlined,
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
                ? 'Try adjusting your search terms or filter'
                : 'Pull to refresh to load procedures from server',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _searchController.text.isNotEmpty
                ? () => _searchController.clear()
                : _onRefresh,
            icon: Icon(_searchController.text.isNotEmpty
                ? Icons.clear
                : Icons.refresh),
            label: Text(
                _searchController.text.isNotEmpty ? 'Clear search' : 'Refresh'),
          ),
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
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredProcedures.length,
      itemBuilder: (context, index) {
        final procedure = _filteredProcedures[index];
        return _buildProcedureTile(procedure);
      },
    );
  }

  Widget _buildProcedureTile(Procedures procedure) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEditing = _editingProcedures.contains('${procedure.procedureId}');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.medical_services_outlined,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                if (!isEditing)
                  Tooltip(
                    message: 'Display name only - ID relationships preserved',
                    child: Icon(
                      Icons.text_fields,
                      size: 16,
                      color: colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                const SizedBox(width: 4),
                Expanded(
                  child: isEditing
                      ? TextField(
                          controller: _editControllers[procedure.procedureId],
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            isDense: true,
                            helperText: 'Description only - IDs preserved',
                          ),
                          autofocus: true,
                          maxLength: 75,
                          onSubmitted: (_) => _saveEdit(procedure),
                        )
                      : Text(
                          procedure.procedureDesc,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                if (isEditing) ...[
                  BlocListener<UpdatePatientStateCubit,
                      UpdatePatientStateState>(
                    listener: (context, state) {
                      if (state is UpdatePatientStateSuccess) {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        _loadData();
                        _cancelEditing(procedure.procedureId);
                      }
                    },
                    child: IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () => _saveEdit(procedure),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => _cancelEditing(procedure.procedureId),
                  ),
                ] else ...[
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _startEditing(procedure),
                    tooltip: 'Edit description only',
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deleteProcedure(procedure);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('Delete'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.category_outlined,
                  size: 20,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 8),
                Text(
                  'Category:',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(width: 4),
                Tooltip(
                  message: 'Changes Main_Procedure_id relationship',
                  child: Icon(
                    Icons.info_outline,
                    size: 14,
                    color: colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: procedure.mainProcedureDesc.isNotEmpty
                          ? procedure.mainProcedureDesc
                          : null,
                      isDense: true,
                      hint: const Text('Select category'),
                      items: _categories
                          .where((c) => c != 'All Categories')
                          .map((category) => DropdownMenuItem(
                                value: category,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color:
                                        category == procedure.mainProcedureDesc
                                            ? colorScheme.primaryContainer
                                            : colorScheme.surfaceVariant,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    category,
                                    style: TextStyle(
                                      color: category ==
                                              procedure.mainProcedureDesc
                                          ? colorScheme.onPrimaryContainer
                                          : colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ))
                          .toList(),
                      onChanged: (newCategory) {
                        if (newCategory != null &&
                            newCategory != procedure.mainProcedureDesc) {
                          _updateCategory(procedure, newCategory);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Row(
            //   children: [
            //     Container(
            //       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            //       decoration: BoxDecoration(
            //         color: colorScheme.primaryContainer.withOpacity(0.7),
            //         borderRadius: BorderRadius.circular(12),
            //       ),
            //       child: Row(
            //         mainAxisSize: MainAxisSize.min,
            //         children: [
            //           Icon(
            //             Icons.key,
            //             size: 16,
            //             color: colorScheme.onPrimaryContainer,
            //           ),
            //           const SizedBox(width: 4),
            //           Text(
            //             'Link ID: ${procedure.procedureId}',
            //             style: theme.textTheme.bodySmall?.copyWith(
            //               color: colorScheme.onPrimaryContainer,
            //               fontFamily: 'monospace',
            //               fontWeight: FontWeight.bold,
            //             ),
            //           ),
            //         ],
            //       ),
            //     ),
            //     const SizedBox(width: 12),
            //     Container(
            //       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            //       decoration: BoxDecoration(
            //         color: colorScheme.secondaryContainer.withOpacity(0.7),
            //         borderRadius: BorderRadius.circular(12),
            //       ),
            //       child: Row(
            //         mainAxisSize: MainAxisSize.min,
            //         children: [
            //           Icon(
            //             Icons.category,
            //             size: 16,
            //             color: colorScheme.onSecondaryContainer,
            //           ),
            //           const SizedBox(width: 4),
            //           Text(
            //             'Category ID: ${procedure.mainProcedureId}',
            //             style: theme.textTheme.bodySmall?.copyWith(
            //               color: colorScheme.onSecondaryContainer,
            //               fontFamily: 'monospace',
            //               fontWeight: FontWeight.bold,
            //             ),
            //           ),
            //         ],
            //       ),
            //     ),
            //   ],
            // ),
          ],
        ),
      ),
    );
  }
}
