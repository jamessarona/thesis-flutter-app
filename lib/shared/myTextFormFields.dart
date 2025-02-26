import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tanood/shared/constants.dart';

class MyTextFormField extends StatelessWidget {
  final TextInputType? inputType;
  final bool isObscureText;
  final FormFieldValidator<String>? validation;
  final FormFieldValidator<String>? onChanged;
  final Icon prefixIcon;
  final String? labelText;
  final String? hintText;
  final GestureDetector? suffixIcon;
  final FocusNode focusNode;
  MyTextFormField(
      {this.inputType,
      required this.isObscureText,
      this.validation,
      this.onChanged,
      required this.prefixIcon,
      this.labelText,
      this.hintText,
      this.suffixIcon,
      required this.focusNode});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      focusNode: focusNode,
      keyboardType: inputType,
      obscureText: isObscureText,
      validator: validation,
      onChanged: onChanged,
      decoration: InputDecoration(
        prefixIcon: prefixIcon,
        labelText: labelText,
        hintText: hintText,
        isDense: true,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white70,
        labelStyle: TextStyle(
            color: focusNode.hasFocus == true
                ? customColor[130]
                : Colors.grey[700]),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xff1c52dd)),
        ),
      ),
    );
  }
}

class MyDocumentationTextFormField extends StatelessWidget {
  final TextInputType inputType;
  final bool isObscureText;
  final TextInputAction textAction;
  final FormFieldValidator<String> validation;
  final FormFieldValidator<String> onChanged;
  final VoidCallback onTap;
  final GestureDetector? prefixIcon;
  final String labelText;
  final String hintText;
  final bool isReadOnly;
  final TextEditingController controller;
  MyDocumentationTextFormField({
    required this.inputType,
    required this.isObscureText,
    required this.textAction,
    required this.validation,
    required this.onChanged,
    required this.onTap,
    required this.prefixIcon,
    required this.labelText,
    required this.hintText,
    required this.isReadOnly,
    required this.controller,
  });
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      obscureText: isObscureText,
      validator: validation,
      onChanged: onChanged,
      readOnly: isReadOnly,
      textInputAction: textAction,
      onTap: onTap,
      decoration: InputDecoration(
        isDense: true,
        prefixIcon: prefixIcon,
        labelText: labelText,
        prefix: Text(labelText == 'Fine' ? '₱' : ''),
        hintText: hintText,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: Color(0xff1c52dd),
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        filled: true,
        fillColor: Colors.white70,
      ),
    );
  }
}

class MyPasswordTextFormField extends StatelessWidget {
  final TextInputType inputType;
  final bool isObscureText;
  final TextInputAction textAction;
  final FormFieldValidator<String> validation;
  final FormFieldValidator<String> onChanged;
  final VoidCallback onTap;
  final GestureDetector? prefixIcon;
  final String labelText;
  final String hintText;
  final bool isReadOnly;
  final TextEditingController controller;
  final VoidCallback? onTapSuffixIcon;
  MyPasswordTextFormField({
    required this.inputType,
    required this.isObscureText,
    required this.textAction,
    required this.validation,
    required this.onChanged,
    required this.onTap,
    required this.prefixIcon,
    required this.labelText,
    required this.hintText,
    required this.isReadOnly,
    required this.controller,
    this.onTapSuffixIcon,
  });
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      obscureText: isObscureText,
      validator: validation,
      onChanged: onChanged,
      readOnly: isReadOnly,
      textInputAction: textAction,
      onTap: onTap,
      decoration: InputDecoration(
        isDense: true,
        prefixIcon: prefixIcon,
        labelText: labelText,
        prefix: Text(labelText == 'Fine' ? '₱' : ''),
        suffixIcon: GestureDetector(
          onTap: onTapSuffixIcon,
          child: Icon(
              isObscureText ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye),
        ),
        hintText: hintText,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: Color(0xff1c52dd),
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        filled: true,
        fillColor: Colors.white70,
      ),
    );
  }
}
