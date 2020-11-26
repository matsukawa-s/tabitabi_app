//行程のデータ

class ItineraryData{
  int itineraryID;      //行程ID
  int itineraryOrder;   //順番
  int planId;           //プランID
  DateTime itineraryDateTime;   //日程
  bool accepting;

  ItineraryData(this.itineraryID, this.itineraryOrder, this.planId, this.itineraryDateTime, this.accepting);
}