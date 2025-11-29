part of 'authentication_bloc.dart';

sealed class AuthenticationEvent extends Equatable {
  const AuthenticationEvent();

  @override
  List<Object> get props => [];
}

class LoginButtonClickedEvent extends AuthenticationEvent{
  final String email;
  final String password;

  const LoginButtonClickedEvent({required this.email, required this.password});

}

class RegisterButtonClickedEvent extends AuthenticationEvent{
final String name;
final String email;
final String password;

  const RegisterButtonClickedEvent({required this.name, required this.email, required this.password});
}