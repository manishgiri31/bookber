class Barber {
  Barber({
    required this.id,
    required this.name,
    required this.rating,
    required this.distanceKm,
    required this.bio,
    required this.isAvailable,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final double rating;
  final double distanceKm;
  final String bio;
  final bool isAvailable;
  final String? avatarUrl;
}

class ServiceItem {
  ServiceItem({
    required this.id,
    required this.name,
    required this.category,
    required this.durationMin,
    required this.price,
    this.isCombo = false,
  });

  final String id;
  final String name;
  final String category;
  final int durationMin;
  final double price;
  final bool isCombo;
}

class Booking {
  Booking({
    required this.id,
    required this.barberId,
    required this.barberName,
    required this.serviceNames,
    required this.status,
    required this.scheduledAt,
    required this.queuePosition,
    required this.estimatedWaitMinutes,
  });

  final String id;
  final String barberId;
  final String barberName;
  final List<String> serviceNames;
  final String status;
  final DateTime scheduledAt;
  final int queuePosition;
  final int estimatedWaitMinutes;
}

class QueueStateModel {
  QueueStateModel({
    required this.bookingId,
    required this.position,
    required this.etaMinutes,
    required this.status,
    required this.chairLabel,
  });

  final String bookingId;
  final int position;
  final int etaMinutes;
  final String status;
  final String chairLabel;
}
