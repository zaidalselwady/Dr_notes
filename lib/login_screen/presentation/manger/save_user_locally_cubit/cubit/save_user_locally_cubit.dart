import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../data/user_model.dart';
part 'save_user_locally_state.dart';

class SaveUserLocallyCubit extends Cubit<SaveUserLocallyState> {
  SaveUserLocallyCubit() : super(SaveUserLocallyInitial());

  Future<void> saveUser(User user, bool isChecked) async {
    emit(SavingUserLocally());
    final prefs = await SharedPreferences.getInstance();
    // Convert user to JSON and save it
    String userMap = jsonEncode(user.toMap()..['Remember_Me'] = isChecked);

    await prefs.setString('user', userMap).then(
      (value) {
        emit(SaveUserLocallySuccess(user: user));
      },
    ).catchError((error) {
      emit(SaveUserLocallyFailed(error: error.toString()));
    });
  }

  Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    if (userData == null) return null; // No user found
    emit(GetUserLocally(user: User.fromMap(jsonDecode(userData))));
    return User.fromMap(jsonDecode(userData));
  }

  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clears only user data
    //emit(GetUserLocally(user: null)); // Emit an empty user state
  }
}
