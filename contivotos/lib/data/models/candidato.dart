class Candidato {
  final String id;
  final String nombre;
  final String propuesta;
  final String imagen;
  final String semestre;
  final String cargo;
  final int numero;
  final String experiencia;
  final String vision;

  Candidato({
    required this.id,
    required this.nombre,
    required this.propuesta,
    required this.imagen,
    required this.semestre,
    required this.cargo,
    required this.numero,
    required this.experiencia,
    required this.vision,
  });

  factory Candidato.fromFirestore(id, data) {
    return Candidato(
      id: id,
      nombre: data['nombre'] ?? '',
      propuesta: data['propuesta'] ?? '',
      imagen: data['imagen'] ?? '',
      semestre: data['semestre'] ?? '',
      cargo: data['cargo'] ?? '',
      numero: (data['numero'] ?? 0) as int,  // Asegurar que sea int
      experiencia: data['experiencia'] ?? '',
      vision: data['vision'] ?? '',
    );
  }
}
