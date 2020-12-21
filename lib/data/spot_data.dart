//spotのデータを入れるクラス

class SpotData{
  int spotId;
  String spotName;
  double latitude;
  double longitude;
  String spotImagePath;
  int priceId;
  int spotCategory;

  SpotData(this.spotId, this.spotName, this.latitude, this.longitude, this.spotImagePath, this.priceId, this.spotCategory);
}