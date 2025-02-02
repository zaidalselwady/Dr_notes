import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hand_write_notes/get_proc_cubit/cubit/get_proc_cubit.dart';
import 'package:hand_write_notes/information_screen/presentation/view/info.dart';
import 'package:hand_write_notes/login_screen/presentation/manger/save_user_locally_cubit/cubit/save_user_locally_cubit.dart';
import 'package:hand_write_notes/patients_screen/presentation/view/widgets/all_patients_icon.dart';
import 'package:hand_write_notes/generate_report_screen.dart';
import 'package:hand_write_notes/reporting_screen_cubit/cubit/reporting_cubit.dart';

import 'package:hand_write_notes/update_patient_state_cubit/cubit/update_patient_state_cubit.dart';
import 'package:restart_app/restart_app.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/failed_msg_screen_widget.dart';

import '../../../../core/repos/data_repo_impl.dart';
import '../../../../core/utils/api_service.dart';
import '../../../../login_screen/data/user_model.dart';
import '../../manger/get_patients_cubit/cubit/get_patients_cubit.dart';
import 'custom_patients_list.dart';

class Patients extends StatefulWidget {
  const Patients({super.key, required this.sqlStr, required this.icon});
  final String sqlStr;
  final Widget icon;

  @override
  State<Patients> createState() => _PatientsState();
}

class _PatientsState extends State<Patients> {
  @override
  void initState() {
    super.initState();
  }

  bool isSearchVisible = false;
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    var getPatientsCubit = BlocProvider.of<GetPatientsCubit>(context);
    var saveCubit = BlocProvider.of<SaveUserLocallyCubit>(context);
    return Scaffold(
      drawer: const CustomDrawer(),
      appBar: AppBar(
        actions: [
          widget.icon,
          IconButton(
            color: Colors.teal[800],
            onPressed: () async {
              User? user = await saveCubit.getUser();
              if (user?.userName == "Dr") {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MultiBlocProvider(providers: [
                      BlocProvider(
                        create: (context) => GetProcCubit(
                          DataRepoImpl(
                            ApiService(
                              Dio(),
                            ),
                          ),
                        )..fetchPatientsWithSoapRequest(
                            "SELECT * FROM Patients_Procedures"),
                      ),
                      BlocProvider(
                        create: (context) => GetSearchFields(
                          DataRepoImpl(
                            ApiService(
                              Dio(),
                            ),
                          ),
                        )..fetchPatientsWithSoapRequest(
                            "SELECT * FROM Patients_Search_Fields"),
                      )
                    ], child: const ReportingScreen()),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "No access to this feature",
                    ),
                  ),
                );
              }
            },
            icon: const Icon(
              Icons.query_stats,
              size: 40,
            ),
          ),
          IconButton(
            color: Colors.teal[800],
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChildInformationScreen(),
                ),
              );
            },
            icon: const Icon(
              Icons.add,
              size: 40,
            ),
          ),
          if (isSearchVisible == false)
            IconButton(
              color: Colors.teal[800],
              onPressed: () {
                setState(() {
                  isSearchVisible = !isSearchVisible;
                });
              },
              icon: const Icon(
                Icons.search,
                size: 40,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(5.0),
              child: SizedBox(
                  width: width * 0.50,
                  height: height * 0.09,
                  child: TextFormField(
                    cursorColor: const Color(0xFF00695C),
                    style: const TextStyle(color: Color(0xFF00695C)),
                    onFieldSubmitted: (value) {
                      setState(() {
                        isSearchVisible = !isSearchVisible;
                      });
                    },
                    onChanged: (value) {
                      getPatientsCubit.filtering(
                          value, getPatientsCubit.patientsCopy);
                    },
                    keyboardType: TextInputType.name,
                    decoration: const InputDecoration(
                      labelStyle: TextStyle(color: Color(0xFF00695C)),
                      labelText: "Search",
                      prefixIcon: Icon(
                        Icons.search,
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
                  )),
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              "assets/background.png",
            ),
          ),
        ),
        child: BlocListener<UpdatePatientStateCubit, UpdatePatientStateState>(
          listener: (context, state) {
            if (state is UpdatePatientStateSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Patient updated successfully',
                  ),
                ),
              );
              setState(() {});
              //   if (widget.icon is OnlineIcon) {
              //     context
              //         .read<GetPatientsCubit>()
              //         .fetchPatientsWithSoapRequest("SELECT * FROM Patients_Info");
              //   } else {
              //     context.read<GetPatientsCubit>().fetchPatientsWithSoapRequest(
              //         "SELECT * FROM Patients_Info Where isOnClinic = 1");
              //   }
            }
          },
          child: BlocBuilder<GetPatientsCubit, GetPatientsState>(
            builder: (context, state) {
              if (state is GetPatientsSuccess) {
                if (state.patients.isNotEmpty) {
                  return CustomPatientsList(
                    isAll: widget.icon is AllPatientsIcon ? false : true,
                    patients: getPatientsCubit.filteresdPatientsList,
                    onClosestClientCalculated: (index) {},
                    onLengthChanged: (length, visitedLength) {},
                  );
                } else {
                  return WarningMsgScreen(
                    onRefresh: () async {
                      context
                          .read<GetPatientsCubit>()
                          .fetchPatientsWithSoapRequest(widget.icon
                                  is AllPatientsIcon
                              ? "SELECT * FROM Patients_Info Where isOnClinic = 1 AND Status = 0"
                              : "SELECT * FROM Patients_Info WHERE Status = 0");
                    },
                    state: state,
                    msg: "No Patients",
                  );
                }
              } else if (state is GetPatientsFaild) {
                return WarningMsgScreen(
                  onRefresh: () async {
                    context
                        .read<GetPatientsCubit>()
                        .fetchPatientsWithSoapRequest(widget.icon
                                is AllPatientsIcon
                            ? "SELECT * FROM Patients_Info Where isOnClinic = 1"
                            : "SELECT * FROM Patients_Info");
                  },
                  state: state,
                  msg: state.error,
                );
              } else {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}

// drawer_widget.dart
class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});
  Future<void> _deleteUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Remove specific key
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SaveUserLocallyCubit, SaveUserLocallyState>(
      bloc: SaveUserLocallyCubit()..getUser(),
      builder: (context, state) {
        if (state is GetUserLocally) {
          return Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                UserAccountsDrawerHeader(
                  accountName: Text(state.user.userName),
                  accountEmail: const Text(""),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: const Color(0xFFDDA853),
                    child: Text(state.user.userName,
                        style: const TextStyle(fontSize: 40)),
                  ),
                ),
                // ListTile(
                //   enabled: false,
                //   leading: const Icon(Icons.home),
                //   title: const Text('Home'),
                //   onTap: () {
                //     // Add action for Home
                //     Navigator.pushReplacementNamed(context, '/');
                //   },
                // ),
                // ListTile(
                //   enabled: false,
                //   leading: const Icon(Icons.report),
                //   title: const Text('Reports'),
                //   onTap: () {
                //     // Navigate to Report Screen
                //     Navigator.pushReplacementNamed(context, '/report');
                //   },
                // ),
                // ListTile(
                //   enabled: false,
                //   leading: const Icon(Icons.settings),
                //   title: const Text('Settings'),
                //   onTap: () {
                //     // Add action for Settings
                //     Navigator.pushReplacementNamed(context, '/settings');
                //   },
                // ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.exit_to_app),
                  title: const Text('Logout'),
                  onTap: () {
                    Navigator.pop(context);
                    showAdaptiveDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                            title: const Text('Logout'),
                            content:
                                const Text('Are you sure you want to logout?'),
                            actions: <Widget>[
                              TextButton(
                                  child: const Text("Logout"),
                                  onPressed: () async {
                                    await _deleteUserData();
                                    //Restart.restartApp();
                                  }),
                              TextButton(
                                  child: const Text("Cancel"),
                                  onPressed: () {
                                    Navigator.pop(context);
                                  }),
                            ]);
                      },
                    );
                  },
                ),
              ],
            ),
          );
        } else {
          return const SizedBox();
        }
      },
    );
  }
}
