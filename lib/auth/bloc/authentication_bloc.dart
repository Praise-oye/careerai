import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

part 'authentication_event.dart';
part 'authentication_state.dart';

class AuthenticationBloc extends Bloc<AuthenticationEvent, AuthenticationState> {
  AuthenticationBloc() : super(AuthenticationInitial()) {
    on<AuthenticationEvent>((event, emit) {
      // TODO: implement event handler
    });
    on<LoginButtonClickedEvent>(loginButtonClickedEvent);
    on<RegisterButtonClickedEvent>(registerButtonClickedEvent);
  }

  FutureOr<void> loginButtonClickedEvent(
    LoginButtonClickedEvent event,
    Emitter<AuthenticationState> emit,
  ) async {
    final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

    try {
      emit(LoginLoadingState());
      final querySnapshot = await FirebaseFirestore.instance
          .collection("users")
          .where("email", isEqualTo: event.email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        emit(LoginFailedState(errorMessage: 'Email does not exist in database'));
        return;
      }
      final user = await firebaseAuth.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );
      if (user.user != null) {
        emit(LoginLoadedState(successMessage: "Log in successful"));
      } else {
        emit(LoginFailedState(errorMessage: "Login failed"));
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == "wrong-password" || e.code == "user-not-found") {
        emit(LoginFailedState(errorMessage: "Email or password is wrong"));

      } else {
        emit(LoginFailedState(errorMessage: "Email or password is wrong"));
      }
    }
    
    catch (e) {
      emit(LoginFailedState(errorMessage: e.toString()));
    }
  }

  FutureOr<void> registerButtonClickedEvent(
    RegisterButtonClickedEvent event,
    Emitter<AuthenticationState> emit,
  ) async {
    final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
    try {
      emit(RegisterLoadingState());
      final querySnapshot = await FirebaseFirestore.instance
          .collection("users")
          .where("email", isEqualTo: event.email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        emit(RegisterFailedState(failedMessage: "email exists"));
      }
      final userCredential = await firebaseAuth.createUserWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );
      await FirebaseFirestore.instance
          .collection("users")
          .doc(userCredential.user!.uid)
          .set({"name": event.name, "email": event.email});
      emit(RegisterLoadedState(successMessage: 'Register Successful'));
    } catch (e) {
      emit(RegisterFailedState(failedMessage: e.toString()));
    }
  }
}
