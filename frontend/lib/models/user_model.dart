class UserModel {
  final String userId;
  final String username;
  final String email;
  final String nickname;

  UserModel({
    required this.userId,
    required this.username,
    required this.email,
    required this.nickname,
  });

  // 서버 응답 데이터를 사용해 유저 모델을 생성하는 팩토리 메서드
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'].toString(),
      username: json['username'],
      email: json['email'],
      nickname: json['nickname'],
    );
  }
}
