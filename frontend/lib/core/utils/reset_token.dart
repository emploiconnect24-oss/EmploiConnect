import 'reset_token_stub.dart'
    if (dart.library.html) 'reset_token_web.dart' as rt_impl;

String? readResetPasswordTokenFromUrl() => rt_impl.readResetPasswordTokenFromUrl();
