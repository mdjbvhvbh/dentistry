class SubjectModel {
  final String id;
  final int level;
  final int semester;
  final String name;
  final String nameAr;
  final String icon;
  final String colorKey;
  final String category;

  SubjectModel({
    required this.id,
    required this.level,
    required this.semester,
    required this.name,
    required this.nameAr,
    required this.icon,
    required this.colorKey,
    required this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'level': level,
      'semester': semester,
      'name': name,
      'nameAr': nameAr,
      'icon': icon,
      'colorKey': colorKey,
      'category': category,
    };
  }

  factory SubjectModel.fromMap(Map<String, dynamic> map) {
    return SubjectModel(
      id: map['id'] as String,
      level: map['level'] as int,
      semester: map['semester'] as int,
      name: map['name'] as String,
      nameAr: map['nameAr'] as String? ?? '',
      icon: map['icon'] as String? ?? 'menu_book',
      colorKey: map['colorKey'] as String? ?? 'blue',
      category: map['category'] as String? ?? '',
    );
  }
}
