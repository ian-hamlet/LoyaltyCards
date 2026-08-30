package com.loyaltycards.supplier_app

import io.flutter.embedding.android.FlutterFragmentActivity

// local_auth's BiometricPrompt requires the host Activity to be a
// FragmentActivity - plain FlutterActivity throws
// "The current activity must be a FragmentActivity" on any authenticate()
// call. FlutterFragmentActivity is Flutter's own FragmentActivity subclass.
class MainActivity : FlutterFragmentActivity()
