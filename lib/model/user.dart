class User {
  final name;
  final iconPath;

  User({
    this.name,
    this.iconPath
  });

  User.fromJson(Map<String, dynamic> json)
    : name = json['name'],
      iconPath = json['icon_path'];
}