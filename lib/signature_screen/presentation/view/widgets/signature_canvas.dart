import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hand_write_notes/create_folder_cubit/cubit/create_folder_cubit.dart';
import 'package:hand_write_notes/information_screen/data/child_info_model.dart';
import 'package:hand_write_notes/questionnaire_screen/data/questionnaire_model.dart';
import 'package:hand_write_notes/signature_screen/presentation/manger/convert_signature_to_img_cubit/convert_signature_to_img_cubit.dart';
import 'package:hand_write_notes/signature_screen/presentation/manger/upload_patient_info_cubit/upload_patient_info_cubit.dart';
import 'package:hand_write_notes/signature_screen/presentation/manger/upload_patient_questionnaire_cubit/upload_patient_questionnaire_cubit.dart';
import 'package:hand_write_notes/upload_files_cubit/cubit/upload_files_cubit.dart';
import 'package:signature/signature.dart';

import '../../../../login_screen/data/user_model.dart';
import '../../../../login_screen/presentation/manger/save_user_locally_cubit/cubit/save_user_locally_cubit.dart';
import '../../../../patients_screen/presentation/view/all_patients_screen.dart';
import 'temporary_screen.dart';

class SignatureCanvas extends StatefulWidget {
  const SignatureCanvas(
      {super.key, required this.childInfo, required this.questionnaireModel});
  final PatientInfo childInfo;
  final List<QuestionnaireModel> questionnaireModel;

  @override
  _SignatureCanvasState createState() => _SignatureCanvasState();
}

class _SignatureCanvasState extends State<SignatureCanvas> {
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  bool isActive = true;

  @override
  Widget build(BuildContext context) {
    var saveCubit = BlocProvider.of<SaveUserLocallyCubit>(context);
    var convertCubit = BlocProvider.of<ConvertSignatureToImgCubit>(context);
    var uploadPatientInfoCubit =
        BlocProvider.of<UploadPatientInfoCubit>(context);
    var uploadPatientQuestionnaireCubit =
        BlocProvider.of<UploadPatientQuestionnaireCubit>(context);
    var uploadFilesCubit = BlocProvider.of<UploadFilesCubit>(context);
    var createFolderCubit = BlocProvider.of<CreateFolderCubit>(context);
    String? base64String = "";
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SignatureExplainationText(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            height: 150,
            child: Signature(
              controller: _controller,
              backgroundColor: Colors.white,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () {
                _controller.clear();
              },
              child: const Text("Clear"),
            ),
            MultiBlocListener(
              listeners: [
                BlocListener<ConvertSignatureToImgCubit,
                    ConvertSignatureToImgState>(
                  listener: (context, state) async {
                    if (state is ConvertSignatureSuccess) {
                      await uploadPatientInfoCubit
                          .uploadPatientInfo(widget.childInfo);
                    } else if (state is ConvertSignatureFaild) {
                      showSnack(context, state.error);
                    }
                  },
                ),
                BlocListener<UploadPatientInfoCubit, UploadPatientInfoState>(
                  listener: (context, state) async {
                    if (state is UploadPatientInfoSuccess) {
                      await uploadPatientQuestionnaireCubit
                          .uploadPatientQuestionnaire(
                              widget.questionnaireModel, state.patientId);
                      debugPrint("SUCCESSFUL");
                    } else if (state is UploadPatientInfoFaild) {
                      showSnack(context, state.error);
                    }
                  },
                ),
                BlocListener<UploadPatientQuestionnaireCubit,
                    UploadPatientQuestionnaireState>(
                  listener: (context, state) async {
                    if (state is UploadPatientQuestionnaireSuccess) {
                      await createFolderCubit
                          .createFolder("P${state.patientId}");
                      debugPrint("SUCCESSFUL");
                    } else if (state is UploadPatientQuestionnaireFaild) {
                      showSnack(context, state.error);
                    }
                  },
                ),
                BlocListener<CreateFolderCubit, CreateFolderState>(
                  listener: (context, state) async {
                    if (state is CreateFolderSuccess) {
                      await uploadFilesCubit.uploadPhoto(
                          "", base64String!, "Signature", state.folderName);
                      debugPrint("SUCCESSFUL");
                    } else if (state is CreateFolderFaild) {
                      showSnack(context, state.error);
                    }
                  },
                ),
              ],
              child: BlocConsumer<UploadFilesCubit, UploadFilesState>(
                listener: (context, state) async {
                  if (state is UploadFilesSuccess) {
                    User? user = await saveCubit.getUser();
                    if (user?.userName == "Dr") {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AllPatientsScreen()),
                        (route) => false, // This removes all routes.
                      );
                    } else {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => PatientConfirmationScreen()),
                        (route) => false, // This removes all routes.
                      );
                    }
                  } else if (state is UploadFilesError) {
                    showSnack(context, state.errorMessage);
                  }
                },
                builder: (context, state) {
                  
                  if (state is ConvertingSignature ||
                      state is UploadingPatientInfo ||
                      state is UploadingPatientQuestionnaire ||
                      state is UploadingFiles) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return ElevatedButton(
                    onPressed: (state is ConvertingSignature ||
                            state is UploadingPatientInfo ||
                            state is UploadingPatientQuestionnaire ||
                            state is UploadingFiles)
                        ? null // الزر معطل
                        : () async {
                            if (_controller.isNotEmpty && isActive) {
                              isActive = false;

                              base64String = await convertCubit
                                  .convertSignatureToBase64(_controller);
                            }
                          },
                    child: const Text("Save"),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  void showSnack(BuildContext context, String snackBarText) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(snackBarText),
      ),
    );
  }
}

class SignatureExplainationText extends StatelessWidget {
  const SignatureExplainationText({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Text(
        'Please provide your signature below to confirm that the information you have provided is accurate and complete to the best of your knowledge:',
        style: TextStyle(
          fontSize: 16,
        ),
      ),
    );
  }
}
