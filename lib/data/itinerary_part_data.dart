//行程の各パーツ
// - スポット
// - メモ
// - 交通手段

//行程のスポットデータを入れる
class SpotItineraryData{
  int id;
  int itineraryId;
  int spotId;
  String spotName;
  double latitude;
  double longitude;
  String spotImagePath;
  DateTime spotStartDateTime;
  DateTime spotEndDateTime;
  int parentFlag;

  SpotItineraryData(this.id, this.itineraryId, this.spotId, this.spotName, this.latitude, this.longitude, this.spotImagePath, this.spotStartDateTime, this.spotEndDateTime, this.parentFlag);
}

//行程のメモ
class MemoItineraryData{
  int id;
  int itineraryId;
  String memo;

  MemoItineraryData(this.id, this.itineraryId, this.memo);
}

//行程の交通手段
class TrafficItineraryData{
  int id;
  int itineraryId;
  int trafficClass;
  String travelTime;
  int cost;

  TrafficItineraryData(this.id, this.itineraryId, this.trafficClass, this.travelTime, this.cost);
}