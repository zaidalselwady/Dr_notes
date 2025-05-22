import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hand_write_notes/dashboard_screen/presentation/view/dashboardScreen.dart';
import 'package:hand_write_notes/login_screen/presentation/manger/save_user_locally_cubit/cubit/save_user_locally_cubit.dart';

import '../manger/cubit/login_cubit.dart';
import 'widgets/text_field_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  var formkey = GlobalKey<FormState>();
  TextEditingController userNameCon = TextEditingController();
  TextEditingController passwordCon = TextEditingController();
  bool invisiblePassword = true;
  IconData icon = Icons.visibility_off_outlined;
  bool isChecked = false;
  @override
  void initState() {
    context.read<SaveUserLocallyCubit>().clearUserData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var loginCubit = BlocProvider.of<LoginCubit>(context);
    var saveCubit = BlocProvider.of<SaveUserLocallyCubit>(context);
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: ListView(
          children: [
            MultiBlocListener(
              listeners: [
                BlocListener<LoginCubit, LoginState>(
                  listener: (context, state) async {
                    if (state is GetUsersSuccess) {
                      await saveCubit.saveUser(state.user, isChecked);
                    } else if (state is GetUsersFailed) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.massege),
                        ),
                      );
                    }
                  },
                ),
                BlocListener<SaveUserLocallyCubit, SaveUserLocallyState>(
                  listener: (context, state) {
                    if (state is SaveUserLocallySuccess) {
                      
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const DashboardScreen()),
                        (route) => false, // Remove all routes
                      );
                      // if (state.user.userName == "Dr") {
                      //   Navigator.pushAndRemoveUntil(
                      //     context,
                      //     MaterialPageRoute(
                      //         builder: (context) => const PatientsInClinic()),
                      //     (route) => false, // Remove all routes
                      //   );
                      // } else {
                      //   Navigator.pushAndRemoveUntil(
                      //     context,
                      //     MaterialPageRoute(
                      //         builder: (context) => const AllPatientsScreen()),
                      //     (route) => false, // Remove all routes
                      //   );
                      // }
                    } else if (state is SaveUserLocallyFailed) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(state.error)));
                    }
                  },
                )
              ],
              child: BlocBuilder<LoginCubit, LoginState>(
                builder: (context, state) {
                  if (state is GettingUsers || state is SavingUserLocally) {
                    return Container(
                      color: Colors.black.withOpacity(0.5),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Form(
                      key: formkey,
                      child: Card(
                        child: Column(
                          children: [
                            Image.asset(
                              "assets/login1.png",
                              filterQuality: FilterQuality.high,
                              errorBuilder: (context, error, stackTrace) {
                                return const Text("Error");
                              },
                            ),
                            MyCustomTextField(
                              controller: userNameCon,
                              icon: Icons.email,
                              lableText: "User Name",
                              warning: "",
                              type: TextInputType.name,
                              invisible: false,
                              suffixIcon: const Icon(Icons.numbers),
                              onTapOnSuffexIcon: () {},
                            ),
                            MyCustomTextField(
                              controller: passwordCon,
                              icon: Icons.password,
                              lableText: "Password",
                              warning: "",
                              type: TextInputType.visiblePassword,
                              invisible: invisiblePassword,
                              suffixIcon: Icon(icon),
                              onTapOnSuffexIcon: () {
                                setState(() {
                                  if (invisiblePassword == true) {
                                    invisiblePassword = false;
                                    icon = Icons.remove_red_eye_outlined;
                                  } else {
                                    invisiblePassword = true;
                                    icon = Icons.visibility_off_outlined;
                                  }
                                });
                              },
                            ),
                            const SizedBox(
                              height: 30,
                            ),
                            LoginButton(
                              onPressed: () async {
                                if (formkey.currentState!.validate()) {
                                  loginCubit.fetchUsersWithSoapRequest(
                                      userNameCon.text, passwordCon.text);
                                }
                              },
                            ),
                            const SizedBox(
                              height: 20,
                            ),
                            Row(
                              children: [
                                Checkbox(
                                  value: isChecked,
                                  onChanged: (value) {
                                    setState(() {
                                      isChecked = value ?? false;
                                    });
                                  },
                                ),
                                const Flexible(
                                  child: Text('Remember me?'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}

class LoginButton extends StatelessWidget {
  const LoginButton({super.key, required this.onPressed});
  final Function onPressed;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ElevatedButton(
          onPressed: () {
            onPressed();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xff283796),
            elevation: 10,
          ),
          child: const Padding(
            padding: EdgeInsets.only(top: 10, bottom: 10, left: 40, right: 40),
            child: Text(
              "Login",
              style: TextStyle(color: Color(0xffFFFFFF)),
            ),
          )),
    );
  }
}
