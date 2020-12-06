//行程の各パーツ
// - スポット
// - メモ
// - 交通手段

//行程のスポットデータを入れる
class SpotItineraryData{
  int itineraryId;
  int spotId;
  String spotName;
  String spotImagePath;
  DateTime spotStartDateTime;
  DateTime spotEndDateTime;
  int parentFlag;

  SpotItineraryData(this.itineraryId, this.spotId, this.spotName, this.spotImagePath, this.spotStartDateTime, this.spotEndDateTime, this.parentFlag);
}

//行程のメモ
class MemoItineraryData{
  int itineraryId;
  String memo;

  MemoItineraryData(this.itineraryId, this.memo);
}

//行程の交通手段
class TrafficItineraryData{
  int itineraryId;
  int trafficClass;
  int travelTime;
  int cost;

  TrafficItineraryData(this.itineraryId, this.trafficClass, this.travelTime, this.cost);
}