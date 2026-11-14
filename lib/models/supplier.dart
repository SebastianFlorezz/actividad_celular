class Supplier {
  const Supplier({
    this.id,
    required this.name,
    this.phone,
    this.email,
  });

  final int? id;
  final String name;
  final String? phone;
  final String? email;

  Map<String, Object?> toMap() => {
    'id': id,
    'nombre': name.trim(),
    'telefono': _emptyToNull(phone),
    'correo': _emptyToNull(email),
  };

  factory Supplier.fromMap(Map<String, Object?> map) => Supplier(
    id: map['id'] as int,
    name: map['nombre'] as String,
    phone: map['telefono'] as String?,
    email: map['correo'] as String?,
  );

  static String? _emptyToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
