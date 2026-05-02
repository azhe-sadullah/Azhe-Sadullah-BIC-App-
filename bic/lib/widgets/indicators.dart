import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter/material.dart';

Center circularProgress(BuildContext context) {
  return Center(
    child: SpinKitFadingCircle(
      size: 40.0,
      color: Theme.of(context).colorScheme.secondary,
    ),
  );
}

LinearProgressIndicator linearProgress(BuildContext context) {
  return LinearProgressIndicator(
    valueColor:
        AlwaysStoppedAnimation(Theme.of(context).colorScheme.secondary),
  );
}