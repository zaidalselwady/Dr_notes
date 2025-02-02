import 'package:flutter/material.dart';

import '../../../information_screen/data/child_info_model.dart';
import '../../../questionnaire_screen/data/questionnaire_model.dart';
import 'widgets/signature_canvas.dart';

class SignatureScreen extends StatefulWidget {
  const SignatureScreen({super.key, required this.childInfo, required this.questionnaireModel});
  final PatientInfo childInfo;
  final List<QuestionnaireModel> questionnaireModel;

  @override
  State<SignatureScreen> createState() => _SignatureScreenState();
}

class _SignatureScreenState extends State<SignatureScreen> {
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      body: SignatureCanvas(childInfo:widget.childInfo ,questionnaireModel:widget.questionnaireModel ,),
    );
  }
}
