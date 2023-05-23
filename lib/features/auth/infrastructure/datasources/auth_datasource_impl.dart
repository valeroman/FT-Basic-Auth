
import 'package:basic_auth/config/config.dart';
import 'package:basic_auth/features/auth/infrastructure/infrastructure.dart';
import 'package:dio/dio.dart';
import 'package:basic_auth/features/auth/domain/domain.dart';

class AuthDatasourceImpl extends AuthDatasource {

  final dio = Dio(
    BaseOptions(
      baseUrl: Environment.apiUrl,
    )
  );


  @override
  Future<User> checkAuthStatus(String token) {
    // TODO: implement checkAuthStatus
    throw UnimplementedError();
  }

  @override
  Future<User> login(String email, String password) async {

    try {
      final response = await dio.post('/auth/login', data: {
        'email': email,
        'password': password
      });

      final user = UserMapper.userJsonToEntity(response.data);

      return user;

    } on DioError catch (e) {
      if ( e.response?.statusCode == 401 ) {
        throw CustomError(e.response?.data['message'] ?? 'Credenciales incorrectas' );
      }
      if ( e.type == DioErrorType.connectionTimeout ) {
        throw CustomError( 'Revisar conexión a internet' );
      }
      throw Exception();
    
    } catch (e) {
      throw Exception();
    }
  }

  @override
  Future<User> register(String email, String password, String fullName) async {
    try {
      final response = await dio.post('/auth/register', data: {
        'email': email,
        'password': password,
        'fullName': fullName,
      });

      final user = UserMapper.userJsonToEntity(response.data);

      return user;

    } on DioError catch (e) {
      if ( e.response?.statusCode == 400 ) {
        throw CustomError(e.response?.data['message'] ?? 'Bad request');
      }
      if ( e.type == DioErrorType.connectionTimeout ) {
        throw CustomError( 'Revisar conexión a internet' );
      }
      throw Exception();
    } catch (e) {
      throw Exception();
    }
  }

}