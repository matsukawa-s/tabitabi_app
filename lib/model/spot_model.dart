class Spot {
  final spotName;
  final imageUrl;
  final int prefectureId;

  Spot({
    this.spotName,
    this.imageUrl,
    this.prefectureId
  });

  Spot.fromJson(Map<String,dynamic> json)
    : spotName = json["spot_name"],
      imageUrl = json["image_url"],
      prefectureId = json["prefecture_id"];
}