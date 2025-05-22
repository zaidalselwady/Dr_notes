import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hand_write_notes/patients_screen/presentation/view/all_patients_screen.dart';
import 'package:hand_write_notes/patients_screen/presentation/view/patients_in_clinic_screen.dart';
import '../../../core/repos/data_repo_impl.dart';
import '../../../core/utils/api_service.dart';
import '../../../generate_report_screen.dart';
import '../../../get_proc_cubit/cubit/get_proc_cubit.dart';
import '../../../information_screen/presentation/view/info.dart';
import '../../../login_screen/data/user_model.dart';
import '../../../login_screen/presentation/manger/save_user_locally_cubit/cubit/save_user_locally_cubit.dart';
import '../../../patients_screen/presentation/manger/get_patients_cubit/cubit/get_patients_cubit.dart';
import '../../../patients_screen/presentation/view/widgets/patients_screen.dart';
import '../../../reporting_screen_cubit/cubit/reporting_cubit.dart';
import 'widgets/dashboardCustomButtons.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  User? user;

  @override
  void initState() {
    super.initState();
    fetchUser();
  }

  void fetchUser() async {
    var saveCubit = BlocProvider.of<SaveUserLocallyCubit>(context);
    user = await saveCubit.getUser();
    setState(() {});
  }

  bool isSearchVisible = false;

  @override
  Widget build(BuildContext context) {
    var getPatientsCubit = BlocProvider.of<GetPatientsCubit>(context);
    var saveCubit = BlocProvider.of<SaveUserLocallyCubit>(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
      ),
      drawer: const CustomDrawer(),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE0F7FA), Color(0xFFB2EBF2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const WavingByeIcon(size: 28),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Welcome, ${user?.userName == "Dr" ? "Doctor" : "Secretary"}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF040A17),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: GridView(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 1.0,
                    ),
                    children: [
                      DashboardButton(
                        isDoctor: true,
                        imageName: "all-patients.png",
                        label: 'All Patients',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AllPatientsScreen(),
                            ),
                          );
                        },
                      ),
                      DashboardButton(
                          isDoctor: true,
                          imageName: "inClinic-patients.png",
                          label: 'In Clinic',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PatientsInClinic(),
                              ),
                            );
                          }),
                      DashboardButton(
                        isDoctor: true,
                        imageName: "add-patient.png",
                        label: 'Add Patient',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const ChildInformationScreen(),
                          ),
                        ),
                      ),
                      DashboardButton(
                          isDoctor: user?.userName == "Dr" ? true : false,
                          imageName: "report.png",
                          label: 'Reports',
                          onTap: () {
                            if (user?.userName == "Dr") {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      MultiBlocProvider(providers: [
                                    BlocProvider(
                                      create: (context) => GetProcCubit(
                                        DataRepoImpl(
                                          ApiService(
                                            Dio(),
                                          ),
                                        ),
                                      )..fetchPatientsWithSoapRequest(
                                          "SELECT pp.*,mp.Main_Procedure_Desc FROM Patients_Procedures pp INNER JOIN    Patients_Main_Procedures mp ON pp.Main_procedure_Id = mp.Main_procedure_Id"),
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
                          })
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class WavingByeIcon extends StatefulWidget {
  final double size;
  final Duration duration;

  const WavingByeIcon({
    Key? key,
    this.size = 48,
    this.duration = const Duration(milliseconds: 500),
  }) : super(key: key);

  @override
  State<WavingByeIcon> createState() => _WavingByeIconState();
}

class _WavingByeIconState extends State<WavingByeIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat(reverse: true);

    _rotation = Tween<double>(begin: -0.1, end: 0.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _rotation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotation.value,
          child: child,
        );
      },
      child: Text(
        '👋',
        style: TextStyle(fontSize: widget.size),
      ),
    );
  }
}
