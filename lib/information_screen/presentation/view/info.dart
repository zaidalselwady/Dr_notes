import 'package:flutter/material.dart';
import 'package:hand_write_notes/information_screen/data/child_info_model.dart';
import 'package:hand_write_notes/information_screen/presentation/view/widgets/colorful_background.dart';
import '../../../questionnaire_screen/presentation/view/questionnaire.dart';
import 'widgets/custom_image.dart';
import 'widgets/custom_text_field.dart';

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  Widget build(BuildContext context) {
    GlobalKey<FormState> formKey = GlobalKey<FormState>();

    //double height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const AnimatedImageWidget(),
                DecoratedTextField(
                  labelText: "Child name",
                  controller: nameCon,
                  keyboardType: TextInputType.name,
                  prefixIcon: const Icon(Icons.person_2),
                ),
                DecoratedTextField(
                  readOnly: true,
                  labelText: "Birth date",
                  controller: birthDateCon,
                  keyboardType: TextInputType.datetime,
                  prefixIcon: const Icon(Icons.date_range),
                  onTap: () {
                    showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    ).then((pickedDate) {
                      if (pickedDate != null) {
                        birthDateCon.text =
                            "${pickedDate.toLocal()}".split(' ')[0];
                      }
                    });
                  },
                ),
                DecoratedTextField(
                  labelText: "Address",
                  controller: addressCon,
                  keyboardType: TextInputType.streetAddress,
                  prefixIcon: const Icon(Icons.location_city),
                ),
                DecoratedTextField(
                  labelText: "Phone",
                  controller: phoneCon,
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.phone),
                ),
                DecoratedTextField(
                  labelText: "E-mail",
                  controller: emailCon,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email),
                ),
                DecoratedTextField(
                  labelText: "School",
                  controller: schoolCon,
                  keyboardType: TextInputType.name,
                  prefixIcon: const Icon(Icons.school),
                ),
                DecoratedTextField(
                  labelText: "Mother's name",
                  controller: motherNameCon,
                  keyboardType: TextInputType.name,
                  prefixIcon: const Icon(Icons.person_3_sharp),
                ),
              ]),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.navigate_next_outlined),
        onPressed: () {
          if (formKey.currentState!.validate()) {
            PatientInfo childInfo = PatientInfo(
              name: nameCon.text,
              birthDate: birthDateCon.text,
              address: addressCon.text,
              phone: phoneCon.text,
              email: emailCon.text,
              school: schoolCon.text,
              motherName: motherNameCon.text,
              isInClinic: true,
            );
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DecoratedQuestionnaireScreen(
                  childInfo: childInfo,
                  answers: const [],
                  isNavigateFromVisitScreen: false,
                ),
              ),
            );
          }
        },
      ),
    );
  }

  TextEditingController nameCon = TextEditingController();
  TextEditingController birthDateCon = TextEditingController();
  TextEditingController addressCon = TextEditingController();
  TextEditingController phoneCon = TextEditingController();
  TextEditingController emailCon = TextEditingController();
  TextEditingController schoolCon = TextEditingController();
  TextEditingController motherNameCon = TextEditingController();
}

class ChildInformationScreen extends StatelessWidget {
  const ChildInformationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColorfulBackground(child: MyWidget());
  }
}
