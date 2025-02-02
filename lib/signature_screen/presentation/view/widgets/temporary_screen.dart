import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hand_write_notes/patients_screen/presentation/view/all_patients_screen.dart';

import '../../../../login_screen/data/user_model.dart';
import '../../../../login_screen/presentation/manger/save_user_locally_cubit/cubit/save_user_locally_cubit.dart';

class PatientConfirmationScreen extends StatefulWidget {
  @override
  _PatientConfirmationScreenState createState() =>
      _PatientConfirmationScreenState();
}

class _PatientConfirmationScreenState extends State<PatientConfirmationScreen> {
  late User user;
  @override
  void initState() {
    super.initState();
    _loadUser();
    // Set a timer for 5 seconds
    // Future.delayed(const Duration(seconds: 8), () {
    //   // Navigate back to Patients List
    //   Navigator.pushAndRemoveUntil(
    //     context,
    //     MaterialPageRoute(
    //       builder: (context) => const AllPatientsScreen(),
    //     ),
    //     (route) => false, // Remove all previous routes from the stack
    //   );
    // });
  }

  Future<void> _loadUser() async {
    final userCubit = context.read<SaveUserLocallyCubit>();
    final loadedUser = await userCubit.getUser();
    setState(() {
      user = loadedUser!; // Update the state with the loaded user
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon or Illustration
                const InkWell(
                  // onDoubleTap: () {
                  //   Navigator.pushAndRemoveUntil(
                  //     context,
                  //     MaterialPageRoute(
                  //       builder: (context) => const AllPatientsScreen(),
                  //     ),
                  //     (route) => false,
                  //   );
                  // },
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 100,
                  ),
                ),
                const SizedBox(height: 20),
            
                // Success Message
                Text(
                  'Information Saved Successfully!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[900],
                  ),
                ),
                const SizedBox(height: 10),
            
                // Description
                Text(
                  'Thank you for providing your information.\nYou will be redirected shortly.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blueGrey[600],
                  ),
                ),
                const SizedBox(height: 30),
            
                // Progress Indicator
                const CircularProgressIndicator(
                  color: Colors.blueGrey,
                  strokeWidth: 3,
                ),
                const SizedBox(height: 20),
                TextFormField(),
                TextFormField(
                  cursorColor: const Color(0xFF00695C),
                  style: const TextStyle(color: Color(0xFF00695C)),
                  onChanged: (value) {
                    if (value == user.password) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AllPatientsScreen(),
                        ),
                        (route) =>
                            false, // Remove all previous routes from the stack
                      );
                    }
                    // getPatientsCubit.filtering(
                    //     value, getPatientsCubit.patientsCopy);
                  },
                  keyboardType: TextInputType.name,
                  decoration: const InputDecoration(
                    labelStyle: TextStyle(color: Color(0xFF00695C)),
                    labelText: "Password",
                    prefixIcon: Icon(
                      Icons.password,
                      color: Color(0xFF00695C),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0xFF00695C),
                        width: 1.0,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0xFF00695C),
                        width: 2.0,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0xFF00695C),
                        width: 1.0,
                      ),
                    ),
                    prefixIconColor: Color(0xFF00695C),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
