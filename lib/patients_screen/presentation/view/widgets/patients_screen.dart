import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';

import 'package:android_intent_plus/android_intent.dart';
import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hand_write_notes/change_password_screen.dart';
import 'package:hand_write_notes/login_screen/presentation/manger/save_user_locally_cubit/cubit/save_user_locally_cubit.dart';
import 'package:hand_write_notes/patients_screen/presentation/view/widgets/all_patients_icon.dart';

import 'package:hand_write_notes/update_patient_state_cubit/cubit/update_patient_state_cubit.dart';
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:restart_app/restart_app.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/failed_msg_screen_widget.dart';
import '../../../../core/repos/data_repo_impl.dart';
import '../../../../core/utils/api_service.dart';
import '../../../../settings.dart';
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        actions: [
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
          child: BlocListener<UpdatePatientStateCubit, UpdatePatientStateState>(
            listener: (context, state) {
              if (state is UpdatePatientStateSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Patient updated successfully ',
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
      ),
    );
  }
}

// drawer_widget.dart
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

  Future<bool> isInstallPermissionGranted() async {
    try {
      final bool result = await CustomDrawer._channel
          .invokeMethod('isInstallPermissionGranted');
      debugPrint('Install permission granted: $result');
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

      // Wait until the user returns from settings
      await Future.delayed(const Duration(seconds: 5));

      // Re-check again
      granted = await isInstallPermissionGranted();
    }

    return granted;
  }

  Future<void> checkForUpdate(BuildContext context) async {
    await checkInstallPermission(context);

    try {
      final dio = Dio();
      final response = await dio.get(
        'https://optimaljo.com/drapp/apk/version.json',
        options: Options(responseType: ResponseType.plain),
      );

      final Map<String, dynamic> data = jsonDecode(response.data);
      final latestVersion = data['latest_version'];
      final zipUrl = data['apk_url'];
      final changeLog = data['change_log'];

      final info = await PackageInfo.fromPlatform();
      final currentVersion = info.version;

      if (latestVersion != currentVersion) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("تحديث متوفر 🚀"),
            content: Text(" New Version $latestVersion available"),
            actions: [
              TextButton(
                child: const Text("تحميل"),
                onPressed: () async {
                  Navigator.pop(context);

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

                  try {
                    final dir = await getTemporaryDirectory();
                    final zipPath = '${dir.path}/update.zip';
                    final apkPath = '${dir.path}/update.apk';

                    // تحميل ملف ZIP
                    await dio.download(zipUrl, zipPath);

                    // فك ضغط ZIP
                    final bytes = File(zipPath).readAsBytesSync();
                    final archive = ZipDecoder().decodeBytes(bytes);

                    for (final file in archive) {
                      if (file.name.endsWith('.apk')) {
                        final outFile = File(apkPath);
                        await outFile.writeAsBytes(file.content as List<int>);
                        break;
                      }
                    }

                    Navigator.pop(context); // إغلاق دايلوج التحميل

                    // فتح ملف APK للتثبيت (بدون مشاكل صلاحيات URI)
                    final result = await OpenFile.open(apkPath);
                    debugPrint('فتح ملف التثبيت: ${result.message}');
                  } catch (e) {
                    Navigator.pop(context);
                    debugPrint("خطأ أثناء التثبيت: $e");
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("فشل في تحميل أو تثبيت التحديث 😥")),
                    );
                  }
                },
              ),
              TextButton(
                child: const Text("لاحقاً"),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🎉 أنت على آخر إصدار")),
        );
      }
    } catch (e) {
      debugPrint("خطأ أثناء التحقق من التحديث: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("حدث خطأ أثناء التحقق من التحديث 😅")),
      );
    }
  }

  String version = '';
  Future<void> loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      version = 'v${info.version}';
    });
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
                      ListTile(
                        leading: const Icon(Icons.system_update),
                        title: const Text('Check for updates'),
                        onTap: () => checkForUpdate(context),
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

//   Future<void> checkForUpdate(BuildContext context) async {
//   try {
//     final dio = Dio();
//     final response = await dio.get(
//       'https://optimaljo.com/drapp/apk/version.json',
//       options: Options(responseType: ResponseType.plain),
//     );
//     final Map<String, dynamic> data = jsonDecode(response.data);
//     final latestVersion = data['latest_version'];
//     final zipUrl = data['apk_url'];
//     final changeLog = data['change_log'];
//     final info = await PackageInfo.fromPlatform();
//     final currentVersion = info.version;
//     if (latestVersion != currentVersion) {
//       showDialog(
//         context: context,
//         builder: (_) => AlertDialog(
//           title: const Text("تحديث متوفر 🚀"),
//           content: Text("نسخة جديدة $latestVersion متوفرة:\n\n$changeLog"),
//           actions: [
//             TextButton(
//               child: const Text("تحميل"),
//               onPressed: () async {
//                 Navigator.pop(context);
//                 // أظهر دايلوج التحميل
//                 showDialog(
//                   context: context,
//                   barrierDismissible: false,
//                   builder: (_) => const AlertDialog(
//                     content: Row(
//                       children: [
//                         CircularProgressIndicator(),
//                         SizedBox(width: 20),
//                         Expanded(child: Text("جارٍ تحميل التحديث...")),
//                       ],
//                     ),
//                   ),
//                 );
//                 try {
//                   final dir = await getTemporaryDirectory();
//                   final zipPath = '${dir.path}/update.zip';
//                   final apkPath = '${dir.path}/update.apk';
//                   // نزّل ملف الـ ZIP
//                   await dio.download(zipUrl, zipPath);
//                   // فك الضغط
//                   final bytes = File(zipPath).readAsBytesSync();
//                   final archive = ZipDecoder().decodeBytes(bytes);
//                   for (final file in archive) {
//                     if (file.name.endsWith('.apk')) {
//                       final outFile = File(apkPath);
//                       await outFile.writeAsBytes(file.content as List<int>);
//                       break;
//                     }
//                   }
//                   // أغلق الدايلوج بعد ما يخلص
//                   Navigator.pop(context);
//                   // ثبّت الـ APK
//                   await InstallPlugin.installApk(apkPath, appId: 'com.example.hand_write_notes');
//                 } catch (e) {
//                   Navigator.pop(context);
//                   debugPrint("خطأ أثناء التثبيت: $e");
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text("فشل في تحميل أو تثبيت التحديث 😥")),
//                   );
//                 }
//               },
//             ),
//             TextButton(
//               child: const Text("لاحقاً"),
//               onPressed: () => Navigator.pop(context),
//             ),
//           ],
//         ),
//       );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("🎉 أنت على آخر إصدار")),
//       );
//     }
//   } catch (e) {
//     debugPrint("خطأ أثناء التحقق من التحديث: $e");
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("حدث خطأ أثناء التحقق من التحديث 😅")),
//     );
//   }
// }

//   Future<void> checkForUpdate(BuildContext context) async {
//   try {
//     final dio = Dio();
//     final response = await dio.get(
//       'https://optimaljo.com/drapp/apk/version.json',
//       options: Options(responseType: ResponseType.plain),
//     );
//     final Map<String, dynamic> data = jsonDecode(response.data);
//     final latestVersion = data['latest_version'];
//     final zipUrl = data['apk_url'];
//     final changeLog = data['change_log'];
//     final info = await PackageInfo.fromPlatform();
//     final currentVersion = info.version;
//     if (latestVersion != currentVersion) {
//       showDialog(
//         context: context,
//         builder: (_) => AlertDialog(
//           title: const Text("تحديث متوفر 🚀"),
//           content: Text("نسخة جديدة $latestVersion متوفرة:\n\n$changeLog"),
//           actions: [
//             TextButton(
//               child: const Text("تحميل"),
//               onPressed: () async {
//                 Navigator.pop(context);
//                 final dir = await getTemporaryDirectory();
//                 final zipPath = '${dir.path}/update.zip';
//                 final apkPath = '${dir.path}/update.apk';
//                 // نزّل ملف الـ ZIP
//                 await dio.download(zipUrl, zipPath);
//                 // فك الضغط
//                 final bytes = File(zipPath).readAsBytesSync();
//                 final archive = ZipDecoder().decodeBytes(bytes);
//                 for (final file in archive) {
//                   if (file.name.endsWith('.apk')) {
//                     final outFile = File(apkPath);
//                     await outFile.writeAsBytes(file.content as List<int>);
//                     break;
//                   }
//                 }
//                 // تثبيت الـ APK
//                 await InstallPlugin.installApk(apkPath, appId: 'com.example.hand_write_notes');
//               },
//             ),
//             TextButton(
//               child: const Text("لاحقاً"),
//               onPressed: () => Navigator.pop(context),
//             ),
//           ],
//         ),
//       );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("🎉 أنت على آخر إصدار")),
//       );
//     }
//   } catch (e) {
//     debugPrint("خطأ أثناء التحقق من التحديث: $e");
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("حدث خطأ أثناء التحقق من التحديث 😅")),
//     );
//   }
// }

//   Future<void> checkForUpdate(BuildContext context) async {
//     try {
//       final dio = Dio();
//       final response =
//           await dio.get('https://optimaljo.com/drapp/apk/version.json',
//               options: Options(
//                 responseType: ResponseType.plain,
//               ));
//       final Map<String, dynamic> data = jsonDecode(response.data);
//       final latestVersion = data['latest_version'];
//       final apkUrl = data['apk_url'];
//       final changeLog = data['change_log'];
//       final info = await PackageInfo.fromPlatform();
//       final currentVersion = info.version;
//       if (latestVersion != currentVersion) {
//         // في تحديث
//         showDialog(
//           context: context,
//           builder: (_) => AlertDialog(
//             title: const Text("تحديث متوفر 🚀"),
//             content: Text("نسخة جديدة $latestVersion متوفرة:\n\n$changeLog"),
//             actions: [
//               TextButton(
//                 child: const Text("تحميل"),
//                 onPressed: () async {
//                   Navigator.pop(context);
//                   final uri = Uri.parse(apkUrl);
//                   if (await canLaunchUrl(uri)) {
//                     await launchUrl(uri, mode: LaunchMode.externalApplication);
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
//         // لا يوجد تحديث
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

//   Future<void> downloadAndInstallApkFromZip(BuildContext context) async {
//   final url = 'https://optimaljo.com/DrApp/apk/app-v1.0.3.zip';
//   try {
//     final dir = await getTemporaryDirectory();
//     final zipPath = '${dir.path}/app.zip';
//     final apkPath = '${dir.path}/app-v1.0.3.apk';
//     // 1. تحميل ملف zi
//     final response = await Dio().download(url, zipPath);
//     if (response.statusCode != 200) throw 'فشل التحميل';
//     // 2. فك الضغط واستخراج ملف APK
//     final inputStream = InputFileStream(zipPath);
//     final archive = ZipDecoder().decodeBuffer(inputStream);
//     for (final file in archive) {
//       if (file.isFile && file.name.endsWith('.apk')) {
//         final output = File(apkPath);
//         await output.writeAsBytes(file.content as List<int>);
//         break;
//       }
//     }
//     // 3. فتح ملف APK للتنصي
//     final apkFile = File(apkPath);
//     if (await apkFile.exists()) {
//       final uri = Uri.file(apkFile.path);
//       await launchUrl(uri, mode: LaunchMode.externalApplication);
//     } else {
//       throw 'الملف غير موجود بعد فك الضغط';
//     }
//   } catch (e) {
//     debugPrint('⚠️ خطأ: $e');
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('فشل التحديث أو التنصيب')),
//     );
//   }
// }
