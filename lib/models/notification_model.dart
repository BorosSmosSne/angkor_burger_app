class NotificationModel {
  final String id;
  final String title;
  final String description;
  final String date;
  final bool isRead;
  final String? promoCode;

  NotificationModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    this.isRead = false, // By default, new notifications are unread
    this.promoCode,
  });
}
