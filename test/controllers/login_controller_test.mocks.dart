import 'dart:async' as _i3;

import 'package:mockito/mockito.dart' as _i1;
import 'package:pi_metro_2025_2/services/auth_service.dart' as _i2;

class MockAuthService extends _i1.Mock implements _i2.AuthService {
  MockAuthService() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i3.Future<String?> get token =>
      (super.noSuchMethod(
            Invocation.getter(#token),
            returnValue: _i3.Future<String?>.value(),
          )
          as _i3.Future<String?>);

  @override
  _i3.Future<bool> login({required String? email, required String? senha}) =>
      (super.noSuchMethod(
            Invocation.method(#login, [], {#email: email, #senha: senha}),
            returnValue: _i3.Future<bool>.value(false),
          )
          as _i3.Future<bool>);

  @override
  _i3.Future<void> logout() =>
      (super.noSuchMethod(
            Invocation.method(#logout, []),
            returnValue: _i3.Future<void>.value(),
            returnValueForMissingStub: _i3.Future<void>.value(),
          )
          as _i3.Future<void>);
}
