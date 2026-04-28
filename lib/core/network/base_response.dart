class BaseResponse<T> {
  final T? data;
  final String? message;
  final int? code;

  BaseResponse({this.data, this.message, this.code});

  factory BaseResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json)? fromJsonT,
  ) {
    return BaseResponse(
      data: fromJsonT?.call(json['data']),
      message: json['message'] as String?,
      code: json['code'] as int?,
    );
  }
}
