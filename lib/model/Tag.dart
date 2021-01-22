class Tag{
  var name;
  var count;

  Tag(this.name, this.count);
  Tag.fromJson(Map<String,dynamic> json)
    : name = json['tag']['tag_name'],
      count = json['count'];
}