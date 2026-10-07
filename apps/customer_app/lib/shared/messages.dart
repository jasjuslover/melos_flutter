import 'package:api_client/api_client.dart';
import 'package:flutter/material.dart';

String messageOf(Object error) {
  if (error is ApiException) return error.message;
  return 'Something went wrong. Please try again';
}

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
