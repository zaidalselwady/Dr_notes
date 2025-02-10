import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hand_write_notes/show_info_screen/presentation/manger/update_patient_info_cubit/cubit/update_patient_info_cubit.dart';

import '../../../information_screen/data/child_info_model.dart';

class ShowInfoScreen extends StatefulWidget {
  final PatientInfo patientInfo;

  const ShowInfoScreen({
    super.key,
    required this.patientInfo,
  });

  @override
  _ShowInfoScreenState createState() => _ShowInfoScreenState();
}

class _ShowInfoScreenState extends State<ShowInfoScreen> {
  bool isEditMode = false;

  late TextEditingController addressController;
  late TextEditingController phoneController;
  late TextEditingController emailController;
  late TextEditingController schoolController;
  late TextEditingController nameController;
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController middleNameController;

  @override
  void initState() {
    super.initState();
    addressController = TextEditingController(text: widget.patientInfo.address);
    phoneController = TextEditingController(text: widget.patientInfo.phone);
    emailController = TextEditingController(text: widget.patientInfo.email);
    schoolController = TextEditingController(text: widget.patientInfo.school);
    nameController = TextEditingController(text: widget.patientInfo.name);
    firstNameController =
        TextEditingController(text: widget.patientInfo.firstName);
    lastNameController =
        TextEditingController(text: widget.patientInfo.lastName);
    middleNameController =
        TextEditingController(text: widget.patientInfo.midName);
  }

  @override
  void dispose() {
    addressController.dispose();
    phoneController.dispose();
    emailController.dispose();
    schoolController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var updatepatientinfoCubit =
        BlocProvider.of<UpdatePatientInfoCubit>(context);

    return BlocConsumer<UpdatePatientInfoCubit, UpdatePatientInfoState>(
      listener: (context, state) {
        if (state is UpdatePatientInfoSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Updated Successfully")));
          Navigator.of(context).pop();
        } else if (state is UpdatePatientInfoFailed) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.error)));
        }
      },
      builder: (context, state) {
        bool isLoading = state is UpdatingPatientInfo;
        return Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            title: const Text("Patient Information"),
            centerTitle: true,
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Static Info Card
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _infoRow(Icons.person, "Name",
                                  widget.patientInfo.name),
                              _infoRow(Icons.cake, "Birth Date",
                                  widget.patientInfo.birthDate),
                              _infoRow(Icons.person, "Mother's Name",
                                  widget.patientInfo.motherName),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Editable Fields
                      _editableField(
                        controller: nameController,
                        label: "Name",
                        icon: Icons.person,
                      ),
                      _editableField(
                        controller: firstNameController,
                        label: "First Name",
                        icon: Icons.person,
                      ),
                      _editableField(
                        controller: middleNameController,
                        label: "Middle Name",
                        icon: Icons.person,
                      ),
                      _editableField(
                        controller: lastNameController,
                        label: "Last Name",
                        icon: Icons.person,
                      ),
                      _editableField(
                        controller: addressController,
                        label: "Address",
                        icon: Icons.home,
                      ),
                      _editableField(
                        controller: phoneController,
                        label: "Phone",
                        icon: Icons.phone,
                      ),
                      _editableField(
                        controller: emailController,
                        label: "Email",
                        icon: Icons.email,
                      ),
                      _editableField(
                        controller: schoolController,
                        label: "School",
                        icon: Icons.school,
                      ),
                      const SizedBox(height: 16),
                      // Save/Cancel Buttons
                      if (isEditMode)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                await updatepatientinfoCubit
                                    .updateClientsWithSoapRequest(
                                        widget.patientInfo.patientId,
                                        addressController.text,
                                        emailController.text,
                                        phoneController.text,
                                        schoolController.text,
                                        nameController.text,
                                        firstNameController.text,
                                        middleNameController.text,
                                        lastNameController.text
                                        );
                                setState(() {
                                  isEditMode = false;
                                });
                              },
                              child: const Text("Save"),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              // Loading Indicator Overlay
              if (isLoading)
                Container(
                  color:
                      Colors.black.withOpacity(0.5), // Semi-transparent overlay
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              setState(() {
                isEditMode = !isEditMode;
              });
            },
            child: Icon(isEditMode ? Icons.check : Icons.edit),
          ),
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 8),
          Text(
            "$title:",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _editableField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: TextFormField(
          controller: controller,
          enabled: isEditMode,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon),
            border: const OutlineInputBorder(
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }
}
