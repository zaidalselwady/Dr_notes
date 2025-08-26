import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hand_write_notes/update_patient_state_cubit/cubit/update_patient_state_cubit.dart';

import 'core/loading_overlay.dart';
import 'login_screen/data/user_model.dart';
import 'login_screen/presentation/manger/save_user_locally_cubit/cubit/save_user_locally_cubit.dart';
import 'dart:ui';

class ChangePasswordScreen extends StatefulWidget {
  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  Future<void> _changePassword() async {
    var updateCubit = BlocProvider.of<UpdatePatientStateCubit>(context);
    if (_formKey.currentState!.validate()) {
      await updateCubit.updatePatient(
          "UPDATE Patients_Users SET Password = '${_newPasswordController.text}' WHERE User_Id=${user!.userId}",true);
    }
  }

  @override
  void initState() {
    fetchUser();
    super.initState();
  }

  User? user;
  void fetchUser() async {
    var saveCubit = BlocProvider.of<SaveUserLocallyCubit>(context);
    user = await saveCubit.getUser();
  }

  @override
  Widget build(BuildContext context) {
    var saveCubit = BlocProvider.of<SaveUserLocallyCubit>(context);
    return BlocConsumer<UpdatePatientStateCubit, UpdatePatientStateState>(
      listener: (context, state) {
        if (state is UpdatePatientStateSuccess) {
          saveCubit.updatePassword(_newPasswordController.text);
          Navigator.of(context).pop();
        } else if (state is UpdatePatientStateFaild) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.error)));
        }
      },
      builder: (context, state) {
        bool isLoading = state is UpdatingPatientState;
        return Scaffold(
            appBar: AppBar(title: const Text("Change Password")),
            body: LoadingOverlay(
              isLoading: isLoading,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Current Password"),
                        TextFormField(
                          controller: _currentPasswordController,
                          obscureText: !_isCurrentPasswordVisible,
                          decoration: InputDecoration(
                            hintText: "Enter current password",
                            suffixIcon: IconButton(
                              icon: Icon(_isCurrentPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off),
                              onPressed: () {
                                setState(() {
                                  _isCurrentPasswordVisible =
                                      !_isCurrentPasswordVisible;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Please enter your current password";
                            }
                            if (value != user!.password) {
                              return "Incorrect current password";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        const Text("New Password"),
                        TextFormField(
                          controller: _newPasswordController,
                          obscureText: !_isNewPasswordVisible,
                          decoration: InputDecoration(
                            hintText: "Enter new password",
                            suffixIcon: IconButton(
                              icon: Icon(_isNewPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off),
                              onPressed: () {
                                setState(() {
                                  _isNewPasswordVisible =
                                      !_isNewPasswordVisible;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Please enter a new password";
                            }
                            if (value.length < 4) {
                              return "Password must be at least 4 characters";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        const Text("Confirm Password"),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: !_isConfirmPasswordVisible,
                          decoration: InputDecoration(
                            hintText: "Confirm new password",
                            suffixIcon: IconButton(
                              icon: Icon(_isConfirmPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off),
                              onPressed: () {
                                setState(() {
                                  _isConfirmPasswordVisible =
                                      !_isConfirmPasswordVisible;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Please confirm your new password";
                            }
                            if (value != _newPasswordController.text) {
                              return "Passwords do not match";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 30),
                        // Check loading state

                        ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : _changePassword, // Disable when loading
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: const Text("Change Password"),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ));
      },
    );
  }
}
