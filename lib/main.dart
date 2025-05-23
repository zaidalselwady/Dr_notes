import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hand_write_notes/dashboard_screen/presentation/view/dashboardScreen.dart';
import 'package:hand_write_notes/delete_patient_cubit/cubit/delete_patient_cubit.dart';
import 'package:hand_write_notes/login_screen/presentation/manger/cubit/login_cubit.dart';
import 'package:hand_write_notes/login_screen/presentation/manger/save_user_locally_cubit/cubit/save_user_locally_cubit.dart';
import 'package:hand_write_notes/login_screen/presentation/view/login.dart';
import 'package:hand_write_notes/patients_screen/presentation/view/patients_in_clinic_screen.dart';
import 'package:hand_write_notes/signature_screen/presentation/manger/convert_signature_to_img_cubit/convert_signature_to_img_cubit.dart';
import 'package:hand_write_notes/signature_screen/presentation/manger/upload_patient_info_cubit/upload_patient_info_cubit.dart';
import 'package:hand_write_notes/signature_screen/presentation/manger/upload_patient_questionnaire_cubit/upload_patient_questionnaire_cubit.dart';
import 'package:hand_write_notes/update_patient_state_cubit/cubit/update_patient_state_cubit.dart';
import 'package:hand_write_notes/upload_files_cubit/cubit/upload_files_cubit.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hand_write_notes/core/repos/data_repo_impl.dart';
import 'package:hand_write_notes/core/utils/api_service.dart';
import 'convert_canvas_B64_cubit/cubit/convert_canvas_b64_cubit.dart';
import 'create_folder_cubit/cubit/create_folder_cubit.dart';
import 'login_screen/data/user_model.dart';
import 'patients_screen/presentation/manger/get_patients_cubit/cubit/get_patients_cubit.dart';
import 'patients_screen/presentation/view/all_patients_screen.dart';

class SimpleBlocObserver extends BlocObserver {
  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    debugPrint('${bloc.runtimeType} $change');
  }
}

Future<void> main() async {
  await dotenv.load(fileName: "lib/.env");
  Bloc.observer = SimpleBlocObserver();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // Add observer to monitor app lifecycle
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // Clear cache when the app is disposed (fully closed or sent to background)
    _clearCache();
    // Remove the observer when the widget is disposed
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Function to clear cache
  Future<void> _clearCache() async {
    try {
      final cacheManager = DefaultCacheManager();
      await cacheManager.emptyCache(); // This clears all cached files
    } catch (e) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      // App is going to be closed or disposed, clear the cache
      _clearCache();
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => ConvertCanvasB64Cubit(),
        ),
        BlocProvider(
          create: (context) => UploadFilesCubit(
            DataRepoImpl(
              ApiService(
                Dio(),
              ),
            ),
          ),
        ),
        BlocProvider(
          create: (context) => ConvertSignatureToImgCubit(),
        ),
        BlocProvider(
          create: (context) => UploadPatientInfoCubit(
            DataRepoImpl(
              ApiService(
                Dio(),
              ),
            ),
          ),
        ),
        BlocProvider(
          create: (context) => UploadPatientInfoCubit(
            DataRepoImpl(
              ApiService(
                Dio(),
              ),
            ),
          ),
        ),
        BlocProvider(
          create: (context) => UploadPatientQuestionnaireCubit(
            DataRepoImpl(
              ApiService(
                Dio(),
              ),
            ),
          ),
        ),
        BlocProvider(
          create: (context) => CreateFolderCubit(
            DataRepoImpl(
              ApiService(
                Dio(),
              ),
            ),
          ),
        ),
        BlocProvider(
          create: (context) => DeletePatientCubit(
            DataRepoImpl(
              ApiService(
                Dio(),
              ),
            ),
          ),
        ),
        BlocProvider(
          create: (context) => UpdatePatientStateCubit(
            DataRepoImpl(
              ApiService(
                Dio(),
              ),
            ),
          ),
        ),
        BlocProvider(
          create: (context) => LoginCubit(
            DataRepoImpl(
              ApiService(
                Dio(),
              ),
            ),
          ),
        ),
        BlocProvider(
            create: (context) => GetPatientsCubit(
                  DataRepoImpl(
                    ApiService(
                      Dio(),
                    ),
                  ),
                )),
        BlocProvider(
          create: (context) => SaveUserLocallyCubit(),
        ),
      ],
      child: Builder(
        builder: (context) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Dr Notes',
          theme: ThemeData(
            
            appBarTheme: AppBarTheme(
              backgroundColor:  Colors.transparent,
              iconTheme: IconThemeData(
                color: Colors.teal[800], // Change color
                size: 28, // Change size
              ),
              
            ),
            textTheme: GoogleFonts.robotoTextTheme(),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(
                0xffdaedec,
              ),
            ),
            useMaterial3: true,
          ),
          home: FutureBuilder<User?>(
            future: BlocProvider.of<SaveUserLocallyCubit>(context).getUser(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              if (snapshot.data != null && snapshot.data?.rememberMe == true) {
                return SplashScreen(user: snapshot.data!.userName);
              }
              return const LoginScreen(); // User not logged in
            },
          ),
        ),
      ),
    );
  }
}


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.user});
  final String user;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _scaleAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);

    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _opacity = 1.0;
      });
      _controller.forward();
    });

    Future.delayed(const Duration(seconds: 4), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (context) => UpdatePatientStateCubit(
                  DataRepoImpl(ApiService(Dio())),
                ),
              ),
              BlocProvider(
                create: (context) => GetPatientsCubit(
                  DataRepoImpl(ApiService(Dio())),
                )..fetchPatientsWithSoapRequest(
                    "SELECT * FROM Patients_Info WHERE Status = 0"),
              ),
            ],
            child: const DashboardScreen(),
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background with wave or gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                 Color(0xFFE0F7FA), Color(0xFFB2EBF2)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Logo animation with scale and fade
          Center(
            child: AnimatedOpacity(
              opacity: _opacity,
              duration: const Duration(seconds: 2),
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/logo.png', height: 160),
                    const SizedBox(height: 20),
                    const Text(
                      'DrRecords',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF040A17),
                        fontFamily: 'HelveticaNeue',
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Smart Dental Record System',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF55575B),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}














// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key, required this.user});
//   final String user;

//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen> {
//   double _opacity = 0.0;

//   @override
//   void initState() {
//     super.initState();
//     // Trigger the animation
//     Future.delayed(const Duration(milliseconds: 500), () {
//       setState(() {
//         _opacity = 1.0;
//       });
//     });
//     Future.delayed(const Duration(seconds: 3), () {
//       Navigator.of(context).pushReplacement(
//         MaterialPageRoute(
//             builder: (context) => MultiBlocProvider(providers: [
//                   BlocProvider(
//                     create: (context) => UpdatePatientStateCubit(
//                       DataRepoImpl(
//                         ApiService(
//                           Dio(),
//                         ),
//                       ),
//                     ),
//                   ),
//                   BlocProvider(
//                     create: (context) => GetPatientsCubit(
//                       DataRepoImpl(
//                         ApiService(
//                           Dio(),
//                         ),
//                       ),
//                     )..fetchPatientsWithSoapRequest(
//                         "SELECT * FROM Patients_Info WHERE Status = 0"),
//                   )
//                 ], child: const DashboardScreen())),
//       );
//     });

//     // Navigate to Home Screen after 3 seconds
//     // if (widget.user == "Dr") {
//     //   Future.delayed(const Duration(seconds: 3), () {
//     //     Navigator.of(context).pushReplacement(
//     //       MaterialPageRoute(builder: (context) => const PatientsInClinic()),
//     //     );
//     //   });
//     // } else {
//     //   Future.delayed(const Duration(seconds: 3), () {
//     //     Navigator.of(context).pushReplacement(
//     //       MaterialPageRoute(builder: (context) => const AllPatientsScreen()),
//     //     );
//     //   });
//     // }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           // Background
//           AnimatedContainer(
//             duration: const Duration(seconds: 5),
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//                 colors: [
//                   Color(0xFF5985D8),
//                   Color(0xFFC7D7F5),
//                 ],
//               ),
//             ),
//           ),
//           // Logo Animation
//           Center(
//             child: AnimatedOpacity(
//               opacity: _opacity,
//               duration: const Duration(seconds: 2),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Image.asset('assets/logo.png', height: 200),
//                   // const Icon(Icons.local_hospital,
//                   //     size: 100, color: Colors.white), // Replace with your logo
//                   const SizedBox(height: 20),
//                   const Text(
//                     'Dental App',
//                     style: TextStyle(
//                       fontSize: 24,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
