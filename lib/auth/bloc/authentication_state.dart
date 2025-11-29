part of 'authentication_bloc.dart';

sealed class AuthenticationState extends Equatable {
  const AuthenticationState();
  
  @override
  List<Object> get props => [];
}

final class AuthenticationInitial extends AuthenticationState {}

class LoginLoadingState extends AuthenticationState{

}

class LoginLoadedState extends AuthenticationState{
  final String successMessage;

  const LoginLoadedState({required this.successMessage});

}

class LoginFailedState extends AuthenticationState{
  final String errorMessage;

  const LoginFailedState({required this.errorMessage});
}

class RegisterLoadingState extends AuthenticationState{

}

class RegisterLoadedState extends AuthenticationState{
final String successMessage;

  const RegisterLoadedState({required this.successMessage});
}

class RegisterFailedState extends AuthenticationState{
final String failedMessage;

 const RegisterFailedState({required this.failedMessage});
}