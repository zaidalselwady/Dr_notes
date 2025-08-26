import 'dart:convert';
import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:hand_write_notes/patients_screen/presentation/view/all_patients_screen.dart';
import 'package:hand_write_notes/patients_screen/presentation/view/patients_in_clinic_screen.dart';
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:restart_app/restart_app.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../change_password_screen.dart';
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
import '../../../settings.dart';
import '../../../update_patient_state_cubit/cubit/update_patient_state_cubit.dart';
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
    checkForUpdates();
  }

  void fetchUser() async {
    var saveCubit = BlocProvider.of<SaveUserLocallyCubit>(context);
    user = await saveCubit.getUser();
    setState(() {});
  }

  void checkForUpdates() async {
    var updateCubit = BlocProvider.of<UpdateCubit>(context);
    await updateCubit.checkForUpdate(context);
  }

  bool isSearchVisible = false;

  @override
  Widget build(BuildContext context) {
    var getPatientsCubit = BlocProvider.of<GetPatientsCubit>(context);
    var saveCubit = BlocProvider.of<SaveUserLocallyCubit>(context);
    return BlocConsumer<UpdateCubit, UpdateState>(
      listener: (context, state) {
        if (state is UpdateError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }

        if (state is UpdateAvailable) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("تحديث متوفر 🚀"),
              content: Text("New Version ${state.latestVersion} available"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // يغلق الديالوج
                    context
                        .read<UpdateCubit>()
                        .downloadAndInstall(state.apkUrl);
                  },
                  child: const Text("تحميل"),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context), // يغلق الديالوج بس
                  child: const Text("لاحقاً"),
                ),
              ],
            ),
          );
        }
        if (state is UpdateDownloading) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Expanded(child: Text("جارٍ تحميل التحديث...")),
                ],
              ),
            ),
          );
        }
        if (state is UpdateDownloaded) {
          Navigator.pop(context); // يغلق Dialog التحميل
        }
      },
      builder: (context, state) {
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
                                  builder: (context) =>
                                      const AllPatientsScreen(),
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
                                    builder: (context) =>
                                        const PatientsInClinic(),
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
      },
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

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({super.key});
  static const MethodChannel _channel =
      MethodChannel('install_permission_checker');

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  Future<void> _deleteUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Remove specific key
  }

  String version = '';
  Future<void> loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      version = 'v${info.version}';
    });
  }

  Future<void> _clearCache() async {
    try {
      final cacheManager = DefaultCacheManager();
      await cacheManager.emptyCache(); // يحذف كل الملفات المخزنة مؤقتًا
    } catch (e) {}
  }

  @override
  void initState() {
    super.initState();
    loadVersion();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SaveUserLocallyCubit, SaveUserLocallyState>(
      bloc: SaveUserLocallyCubit()..getUser(),
      builder: (context, state) {
        if (state is GetUserLocally) {
          return Drawer(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: <Widget>[
                      UserAccountsDrawerHeader(
                        accountName: Text(state.user.userName),
                        accountEmail: const Text(""),
                        currentAccountPicture: CircleAvatar(
                          backgroundColor: const Color(0xFFDDA853),
                          child: Text(
                            state.user.userName,
                            style: const TextStyle(fontSize: 40),
                          ),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.password),
                        title: const Text('Change password'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BlocProvider(
                                create: (context) => UpdatePatientStateCubit(
                                    DataRepoImpl(ApiService(Dio()))),
                                child: ChangePasswordScreen(),
                              ),
                            ),
                          );
                        },
                      ),
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
                                content: const Text(
                                    'Are you sure you want to logout?'),
                                actions: <Widget>[
                                  TextButton(
                                    child: const Text("Logout"),
                                    onPressed: () async {
                                      await _deleteUserData();
                                      Restart.restartApp();
                                    },
                                  ),
                                  TextButton(
                                    child: const Text("Cancel"),
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                      const Divider(),
                      BlocListener<UpdateCubit, UpdateState>(
                        listener: (context, state) {
                          if (state is UpdateError) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(state.message)),
                            );
                          }
                          if (state is UpdateNotAvailable) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("🎉 أنت على آخر إصدار")),
                            );
                          }
                          if (state is UpdateAvailable) {
                            Navigator.pop(context);
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text("تحديث متوفر 🚀"),
                                content: Text(
                                    "New Version ${state.latestVersion} available"),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context); // يغلق الديالوج
                                      context
                                          .read<UpdateCubit>()
                                          .downloadAndInstall(state.apkUrl);
                                    },
                                    child: const Text("تحميل"),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(
                                        context), // يغلق الديالوج بس
                                    child: const Text("لاحقاً"),
                                  ),
                                ],
                              ),
                            );
                          }
                          if (state is UpdateDownloading) {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => const AlertDialog(
                                content: Row(
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(width: 20),
                                    Expanded(
                                        child: Text("جارٍ تحميل التحديث...")),
                                  ],
                                ),
                              ),
                            );
                          }
                          if (state is UpdateDownloaded) {
                            Navigator.pop(context); // يغلق Dialog التحميل
                          }
                        },
                        child: ListTile(
                          leading: const Icon(Icons.system_update),
                          title: const Text('Check for updates'),
                          onTap: () => context
                              .read<UpdateCubit>()
                              .checkForUpdate(context),
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        enabled: state.user.userName == "Dr",
                        leading: const Icon(Icons.settings),
                        title: const Text('Settings'),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.delete_forever),
                        title: const Text('Clear Cache & Restart App'),
                        onTap: () => _clearCache().then((_) {
                          Restart.restartApp();
                        }),
                      ),
                      // const Divider(),
                      // ListTile(
                      //   leading: const Icon(Icons.info),
                      //   title: const Text('About'),
                      //   onTap: () => showAboutDialog(
                      //     context: context,
                      //     applicationIcon: Image.asset(
                      //       'assets/logo.png',
                      //       width: 50,
                      //       height: 50,
                      //     ),
                      //     applicationName: 'HandWrite Notes',
                      //     applicationVersion: version,
                      //     applicationLegalese:
                      //         '© 2024 HandWrite Notes. All rights reserved.',
                      //     children: [
                      //       const SizedBox(height: 10),
                      //       const Text(
                      //           'This app is designed to help doctors and secretaries manage patient information and visits efficiently.'),
                      //       const SizedBox(height: 10),
                      //       const Text(
                      //           'Developed by Optimal Software Solutions.'),
                      //     ],
                      //   ),
                      // ),
                    ],
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    version.isEmpty ? "Loading version..." : "Version $version",
                    style: const TextStyle(color: Colors.grey),
                  ),
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

class UpdateService {
  final Dio _dio = Dio();

  Future<bool> isInstallPermissionGranted() async {
    try {
      final bool result = await CustomDrawer._channel
          .invokeMethod('isInstallPermissionGranted');
      return result;
    } catch (e) {
      debugPrint("Error checking install permission: $e");
      return false;
    }
  }

  Future<bool> checkInstallPermission(BuildContext context) async {
    bool granted = await isInstallPermissionGranted();

    if (!granted) {
      final pkgName = (await PackageInfo.fromPlatform()).packageName;
      final intent = AndroidIntent(
        action: 'android.settings.MANAGE_UNKNOWN_APP_SOURCES',
        data: 'package:$pkgName',
      );
      await intent.launch();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text("رجاءً فعّل السماح بتثبيت التطبيقات من مصادر غير معروفة."),
        ),
      );

      // انتظر شوي بعد الرجوع من الإعدادات
      await Future.delayed(const Duration(seconds: 5));
      granted = await isInstallPermissionGranted();
    }

    return granted;
  }

  Future<Map<String, dynamic>> fetchLatestVersion() async {
    final response = await _dio.get(
      'https://optimaljo.com/drapp/apk/version.json',
      options: Options(responseType: ResponseType.plain),
    );
    return jsonDecode(response.data);
  }

  Future<String?> downloadAndExtractApk(String zipUrl) async {
    final dir = await getTemporaryDirectory();
    final zipPath = '${dir.path}/update.zip';
    final apkPath = '${dir.path}/update.apk';

    // تحميل ملف ZIP
    await _dio.download(zipUrl, zipPath);

    // فك ضغط ZIP
    final bytes = File(zipPath).readAsBytesSync();
    final archive = ZipDecoder().decodeBytes(bytes);

    for (final file in archive) {
      if (file.name.endsWith('.apk')) {
        final outFile = File(apkPath);
        await outFile.writeAsBytes(file.content as List<int>);
        return apkPath;
      }
    }
    return null;
  }

  Future<void> openApk(String apkPath) async {
    await OpenFile.open(apkPath);
  }

  bool isNewerVersion(String current, String latest) {
    List<int> currentParts = current.split('.').map(int.parse).toList();
    List<int> latestParts = latest.split('.').map(int.parse).toList();

    for (int i = 0; i < currentParts.length; i++) {
      if (latestParts[i] > currentParts[i]) {
        return true; // latest أكبر
      } else if (latestParts[i] < currentParts[i]) {
        return false; // current أكبر
      }
    }
    return false; // متساويين
  }
}

abstract class UpdateState {}

class UpdateInitial extends UpdateState {}

class UpdateChecking extends UpdateState {}

class UpdateAvailable extends UpdateState {
  final String latestVersion;
  final String changeLog;
  final String apkUrl;

  UpdateAvailable({
    required this.latestVersion,
    required this.changeLog,
    required this.apkUrl,
  });
}

class UpdateNotAvailable extends UpdateState {}

class UpdateDownloading extends UpdateState {}

class UpdateDownloaded extends UpdateState {
  final String apkPath;

  UpdateDownloaded(this.apkPath);
}

class UpdateError extends UpdateState {
  final String message;

  UpdateError(this.message);
}

class UpdateCubit extends Cubit<UpdateState> {
  final UpdateService updateService;

  UpdateCubit(this.updateService) : super(UpdateInitial());

  Future<void> checkForUpdate(BuildContext context) async {
    emit(UpdateChecking());

    try {
      final granted = await updateService.checkInstallPermission(context);
      if (!granted) {
        emit(UpdateError("Permission not granted"));
        return;
      }

      final data = await updateService.fetchLatestVersion();
      final latestVersion = data['latest_version'];
      final apkUrl = data['apk_url'];
      final changeLog = data['change_log'];

      final info = await PackageInfo.fromPlatform();
      final currentVersion = info.version;

      if (updateService.isNewerVersion(currentVersion, latestVersion)) {
        emit(UpdateAvailable(
          latestVersion: latestVersion,
          changeLog: changeLog,
          apkUrl: apkUrl,
        ));
      } else {
        emit(UpdateNotAvailable());
      }
    } catch (e) {
      emit(UpdateError("خطأ أثناء التحقق من التحديث: $e"));
    }
  }

  Future<void> downloadAndInstall(String apkUrl) async {
    emit(UpdateDownloading());
    try {
      final apkPath = await updateService.downloadAndExtractApk(apkUrl);
      if (apkPath != null) {
        emit(UpdateDownloaded(apkPath));
        await updateService.openApk(apkPath);
      } else {
        emit(UpdateError("لم يتم العثور على ملف APK في الأرشيف"));
      }
    } catch (e) {
      emit(UpdateError("خطأ أثناء تحميل أو تثبيت التحديث: $e"));
    }
  }
}

// Future<bool> isInstallPermissionGranted() async {
//     try {
//       final bool result = await CustomDrawer._channel
//           .invokeMethod('isInstallPermissionGranted');
//       debugPrint('Install permission granted: $result');
//       return result;
//     } catch (e) {
//       debugPrint("Error checking install permission: $e");
//       return false;
//     }
//   }

//   Future<bool> checkInstallPermission(BuildContext context) async {
//     bool granted = await isInstallPermissionGranted();

//     if (!granted) {
//       final pkgName = (await PackageInfo.fromPlatform()).packageName;
//       final intent = AndroidIntent(
//         action: 'android.settings.MANAGE_UNKNOWN_APP_SOURCES',
//         data: 'package:$pkgName',
//       );
//       await intent.launch();

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content:
//               Text("رجاءً فعّل السماح بتثبيت التطبيقات من مصادر غير معروفة."),
//         ),
//       );

//       // Wait until the user returns from settings
//       await Future.delayed(const Duration(seconds: 5));

//       // Re-check again
//       granted = await isInstallPermissionGranted();
//     }

//     return granted;
//   }

//   Future<void> checkForUpdate(BuildContext context) async {
//     await checkInstallPermission(context);

//     try {
//       final dio = Dio();
//       final response = await dio.get(
//         'https://optimaljo.com/drapp/apk/version.json',
//         options: Options(responseType: ResponseType.plain),
//       );

//       final Map<String, dynamic> data = jsonDecode(response.data);
//       final latestVersion = data['latest_version'];
//       final zipUrl = data['apk_url'];
//       final changeLog = data['change_log'];

//       final info = await PackageInfo.fromPlatform();
//       final currentVersion = info.version;

//       if (latestVersion != currentVersion) {
//         showDialog(
//           context: context,
//           builder: (_) => AlertDialog(
//             title: const Text("تحديث متوفر 🚀"),
//             content: Text(" New Version $latestVersion available"),
//             actions: [
//               TextButton(
//                 child: const Text("تحميل"),
//                 onPressed: () async {
//                   Navigator.pop(context);

//                   showDialog(
//                     context: context,
//                     barrierDismissible: false,
//                     builder: (_) => const AlertDialog(
//                       content: Row(
//                         children: [
//                           CircularProgressIndicator(),
//                           SizedBox(width: 20),
//                           Expanded(child: Text("جارٍ تحميل التحديث...")),
//                         ],
//                       ),
//                     ),
//                   );

//                   try {
//                     final dir = await getTemporaryDirectory();
//                     final zipPath = '${dir.path}/update.zip';
//                     final apkPath = '${dir.path}/update.apk';

//                     // تحميل ملف ZIP
//                     await dio.download(zipUrl, zipPath);

//                     // فك ضغط ZIP
//                     final bytes = File(zipPath).readAsBytesSync();
//                     final archive = ZipDecoder().decodeBytes(bytes);

//                     for (final file in archive) {
//                       if (file.name.endsWith('.apk')) {
//                         final outFile = File(apkPath);
//                         await outFile.writeAsBytes(file.content as List<int>);
//                         break;
//                       }
//                     }

//                     Navigator.pop(context); // إغلاق دايلوج التحميل

//                     // فتح ملف APK للتثبيت (بدون مشاكل صلاحيات URI)
//                     final result = await OpenFile.open(apkPath);
//                     debugPrint('فتح ملف التثبيت: ${result.message}');
//                   } catch (e) {
//                     Navigator.pop(context);
//                     debugPrint("خطأ أثناء التثبيت: $e");
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(
//                           content: Text("فشل في تحميل أو تثبيت التحديث 😥")),
//                     );
//                   }
//                 },
//               ),
//               TextButton(
//                 child: const Text("لاحقاً"),
//                 onPressed: () => Navigator.pop(context),
//               ),
//             ],
//           ),
//         );
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("🎉 أنت على آخر إصدار")),
//         );
//       }
//     } catch (e) {
//       debugPrint("خطأ أثناء التحقق من التحديث: $e");
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("حدث خطأ أثناء التحقق من التحديث 😅")),
//       );
//     }
//   }
