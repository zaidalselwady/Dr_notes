import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/repos/data_repo_impl.dart';
import '../../../core/utils/api_service.dart';
import '../../../update_patient_state_cubit/cubit/update_patient_state_cubit.dart';
import '../manger/get_patients_cubit/cubit/get_patients_cubit.dart';
import 'patients_in_clinic_screen.dart';
import 'widgets/clinic_patients_icon.dart';
import 'widgets/patients_screen.dart';

class AllPatientsScreen extends StatelessWidget {
  const AllPatientsScreen({super.key});

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
              "SELECT * FROM Patients_Info WHERE Status = 0"),
        )
      ],
      child: const Patients(
        icon: OnlineIcon(

        ),
      ),
    );
  }
}
