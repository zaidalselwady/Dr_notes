import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hand_write_notes/patients_screen/presentation/manger/get_patients_cubit/cubit/get_patients_cubit.dart';

import 'package:hand_write_notes/patients_screen/presentation/view/widgets/patients_screen.dart';

import '../../../core/repos/data_repo_impl.dart';
import '../../../core/utils/api_service.dart';
import '../../../update_patient_state_cubit/cubit/update_patient_state_cubit.dart';
import 'all_patients_screen.dart';
import 'widgets/all_patients_icon.dart';

class PatientsInClinic extends StatelessWidget {
  const PatientsInClinic({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
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
          create: (context) => GetPatientsCubit(
            DataRepoImpl(
              ApiService(
                Dio(),
              ),
            ),
          )..fetchPatientsWithSoapRequest(
              "SELECT * FROM Patients_Info Where isOnClinic = 1 AND Status = 0"),
        )
      ],
      child: const Patients(
        icon: AllPatientsIcon(),
      ),
    );
  }
}
