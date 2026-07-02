import 'package:flutter/material.dart';

enum TaskType {
  birthday,
  nameDay,
  deathAnniversary,
  meeting,
  call,
  other;

  String get displayName {
    switch (this) {
      case TaskType.birthday:
        return 'Urodziny';
      case TaskType.nameDay:
        return 'Imieniny';
      case TaskType.deathAnniversary:
        return 'Rocznica śmierci';
      case TaskType.meeting:
        return 'Spotkanie';
      case TaskType.call:
        return 'Zadzwonić';
      case TaskType.other:
        return 'Inne';
    }
  }

  IconData get icon {
    switch (this) {
      case TaskType.birthday:
        return Icons.cake;
      case TaskType.nameDay:
        return Icons.card_giftcard;
      case TaskType.deathAnniversary:
        return Icons.remember_me;
      case TaskType.meeting:
        return Icons.people;
      case TaskType.call:
        return Icons.phone;
      case TaskType.other:
        return Icons.event_note;
    }
  }

  
}

enum Recurrence {
  none,
  weekly,
  monthly,
  yearly;

  String get displayName {
    switch (this) {
      case Recurrence.none:
        return 'Jednorazowe';
      case Recurrence.weekly:
        return 'Co tydzień';
      case Recurrence.monthly:
        return 'Co miesiąc';
      case Recurrence.yearly:
        return 'Co rok';
    }
  }
}