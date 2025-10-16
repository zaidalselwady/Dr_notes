import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../patients_visits_insert_cubit/cubit/upload_patient_visits_cubit.dart';
import '../../../../update_patient_state_cubit/cubit/update_patient_state_cubit.dart';
import '../../../data/image_model.dart';

class FullscreenImageScreen extends StatefulWidget {
  final List<ImageModel> allImage;
  final int initialIndex;
  final int patientId;

  const FullscreenImageScreen({
    super.key,
    this.initialIndex = 0,
    required this.allImage,
    required this.patientId,
  });

  @override
  State<FullscreenImageScreen> createState() => _FullscreenImageScreenState();
}

class _FullscreenImageScreenState extends State<FullscreenImageScreen> {
  late PageController _pageController;
  late String _currentImageName;
  List<ImageModel> imagesOnly = [];
  @override
  void initState() {
    super.initState();

    // كل الصور فقط
    imagesOnly = widget.allImage.where((img) => img.isImage).toList();

    // نحسب الـ index الصحيح للعنصر الحالي داخل الصور فقط
    final clickedImage = widget.allImage[widget.initialIndex];
    final safeIndex =
        imagesOnly.indexWhere((img) => img.imgName == clickedImage.imgName);

    // لو ما كانت صورة (يعني رسم مثلاً)، نبدأ من أول صورة
    final startIndex = safeIndex != -1 ? safeIndex : 0;

    _pageController = PageController(initialPage: startIndex);
    _currentImageName = imagesOnly[startIndex].imgName;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(_currentImageName.split(" ").first),
        ),
        body: MultiBlocListener(
          listeners: [
            BlocListener<UploadPatientVisitsCubit, UploadPatientVisitsState>(
              listener: (context, state) {
                if (state is UploadPatientVisitsSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      duration: Duration(milliseconds: 500),
                      content: Text('Uploading Successful'),
                    ),
                  );
                } else if (state is UploadPatientVisitsFailed) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      duration: Duration(milliseconds: 500),
                      content: Text('uploading Failed'),
                    ),
                  );
                }
              },
            ),
            BlocListener<UpdatePatientStateCubit, UpdatePatientStateState>(
              listener: (context, state) {
                if (state is UpdatePatientStateSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      duration: Duration(milliseconds: 500),
                      content: Text('Updating Successful'),
                    ),
                  );
                } else if (state is UpdatePatientStateFaild) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      duration: Duration(milliseconds: 500),
                      content: Text('Updating Failed'),
                    ),
                  );
                }
              },
            ),
          ],
          child: PageView.builder(
            controller: _pageController,
            itemCount: imagesOnly.length,
            onPageChanged: (index) {
              setState(() {
                _currentImageName = imagesOnly[index].imgName;
              });
            },
            itemBuilder: (context, index) {
              return Center(
                child: Image.memory(imagesOnly[index].imgBase64!),
              );
            },
          ),
        ));
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
