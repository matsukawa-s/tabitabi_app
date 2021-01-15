import 'package:flutter/cupertino.dart';

class Plan{
  var id;
  var title;
  var description;
  var startDay;
  var endDay;
  var imageUrl;
  var cost;
  var isOpen;
  var favoriteCount;
  var numberOfViews;
  var referencedNumber;
  var userId;
  var createdAt;
  var updateAt;
  var isFavorite;
  var user;

  Plan(
      this.id,
      this.title,
      this.description,
      this.startDay,
      this.endDay,
      this.imageUrl,
      this.cost,
      this.isOpen,
      this.favoriteCount,
      this.numberOfViews,
      this.referencedNumber,
      this.userId,
      this.createdAt,
      this.updateAt,
      this.isFavorite,
      this.user
  );

  Plan.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        title = json['title'],
        description = json['description'],
        startDay = json['start_day'],
        endDay = json['end_day'],
        imageUrl = json['image_url'],
        cost = json['cost'],
        isOpen = json['is_open'],
        favoriteCount = json['favorite_count'],
        numberOfViews = json['number_of_views'],
        referencedNumber = json['referenced_number'],
        userId = json['user_id'],
        createdAt = json['created_at'],
        updateAt   = json['update_at'],
        isFavorite = json['islike'],
        user = json["user"];
}