class User {
  final String? id;
  final String nome;
  final String email;
  final String? cpf;
  final String? telefone; 
  final String role;
  final bool ativo;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;

  User({
    this.id,
    required this.nome,
    required this.email,
    this.cpf,       
    this.telefone, 
    required this.role,
    this.ativo = true,
    this.criadoEm,
    this.atualizadoEm,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id']?.toString(),
      nome: json['nome'] ?? '',
      email: json['email'] ?? '',
      cpf: json['cpf'],     
      telefone: json['telefone'],  
      role: json['role'] ?? 'tecnico',
      ativo: json['ativo'] ?? true,
      criadoEm: json['criadoEm'] != null ? DateTime.parse(json['criadoEm']) : null,
      atualizadoEm: json['atualizadoEm'] != null ? DateTime.parse(json['atualizadoEm']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'nome': nome,
      'email': email,
      if (cpf != null) 'cpf': cpf,          
      if (telefone != null) 'telefone': telefone,  
      'role': role,
      'ativo': ativo,
      if (criadoEm != null) 'criadoEm': criadoEm!.toIso8601String(),
      if (atualizadoEm != null) 'atualizadoEm': atualizadoEm!.toIso8601String(),
    };
  }
}