class NotificationEntity {
  final String? id;
  final String? judul;
  final String? pesan;
  final bool isRead;
  final String? createdAt;

  const NotificationEntity({
    this.id,
    this.judul,
    this.pesan,
    this.isRead = false,
    this.createdAt,
  });

  NotificationEntity copyWith({
    String? id,
    String? judul,
    String? pesan,
    bool? isRead,
    String? createdAt,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      judul: judul ?? this.judul,
      pesan: pesan ?? this.pesan,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
