class Tool {
  final String name;
  final String description;
  final String? category;
  final String? risk;

  Tool({
    required this.name,
    required this.description,
    this.category,
    this.risk,
  });

  factory Tool.fromJson(Map<String, dynamic> json) {
    return Tool(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'],
      risk: json['risk'],
    );
  }
}
