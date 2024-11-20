import 'package:flutter/material.dart';

import 'login_page.dart';
import 'register_page.dart';

class LoginOrRegisterPage extends StatefulWidget{
  const LoginOrRegisterPage({super.key});

  @override
  State<LoginOrRegisterPage> createState() => _LoginOrRegisterPageState();
}

class _LoginOrRegisterPageState extends State<LoginOrRegisterPage>{

  //initially show login page
  bool showLoginPge = true;

  //toggle between the login and register page
  void togglePages(){
    setState(() {
      showLoginPge = !showLoginPge;
    });

  }
    
  @override
  Widget build(BuildContext context) {
    if(showLoginPge){
      return LoginPage(
        onTap: togglePages,
      );
    }
    else{
      return RegisterPage(
        onTap: togglePages,);

    }
    
  }


}