import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/votacion_viewmodel.dart';
import '../core/services/votacion_service.dart';
import '../data/models/candidato.dart';

class ResultadoView extends StatefulWidget {
  const ResultadoView({super.key});

  @override
  State<ResultadoView> createState() => _ResultadoViewState();
}

class _ResultadoViewState extends State<ResultadoView> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        context.read<VotacionViewModel>().cargar();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<VotacionViewModel>();

    int totalVotos = vm.conteoVotos.values.fold(0, (sum, v) => sum + v);

    var candidatosOrdenados = List.from(vm.candidatos);
    // Ordenar por número de candidato
    candidatosOrdenados.sort((a, b) => a.numero.compareTo(b.numero));
    // Luego ordenar por votos para el ranking
    candidatosOrdenados.sort((a, b) {
      final votosA = vm.conteoVotos[a.id] ?? 0;
      final votosB = vm.conteoVotos[b.id] ?? 0;
      return votosB.compareTo(votosA);
    });

    String? liderId = candidatosOrdenados.isNotEmpty ? candidatosOrdenados.first.id : null;

    // Verificar si hay un ganador oficial
    Candidato? candidatoGanador;
    for (var candidato in candidatosOrdenados) {
      final votos = vm.conteoVotos[candidato.id] ?? 0;
      if (votos >= VotacionService.VOTOS_PARA_GANAR) {
        candidatoGanador = candidato;
        break;
      }
    }

    final bool hayGanador = candidatoGanador != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text("📊 Resultados en Vivo"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF002855),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => vm.cargar(),
            icon: const Icon(Icons.refresh),
            tooltip: "Actualizar",
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF002855).withOpacity(0.05),
                Colors.transparent,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              // Header con indicador de elección culminada
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: hayGanador
                        ? [Colors.amber, Colors.orange]
                        : [const Color(0xFF002855), const Color(0xFF005BBB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hayGanador) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.emoji_events, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              "🎉 ELECCIÓN FINALIZADA",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ] else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.sync, color: Colors.white70, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            "Actualizando cada 5s",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        hayGanador ? Icons.emoji_events : Icons.how_to_vote,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      hayGanador ? "🏆 Nuevo Delegado UC" : "Elección de Delegado",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (hayGanador) ...[
                      const SizedBox(height: 8),
                      Flexible(
                        child: Text(
                          candidatoGanador!.nombre,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "#${candidatoGanador.numero} - ${vm.conteoVotos[candidatoGanador.id]} votos",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem(
                          value: "${vm.candidatos.length}",
                          label: "Candidatos",
                        ),
                        Container(height: 30, width: 1, color: Colors.white30),
                        _buildStatItem(
                          value: "$totalVotos",
                          label: "Votos",
                        ),
                        Container(height: 30, width: 1, color: Colors.white30),
                        _buildStatItem(
                          value: vm.yaVotoUsuario ? "✅" : "⏳",
                          label: vm.yaVotoUsuario ? "Votaste" : "Sin votar",
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Podio o Ganador
              if (hayGanador) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.amber, Colors.orange],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.emoji_events,
                          size: 48,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "🏆 GANADOR OFICIAL",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white,
                          backgroundImage: (candidatoGanador!.imagen?.isNotEmpty ?? false)
                              ? NetworkImage(candidatoGanador.imagen!)
                              : null,
                          child: (candidatoGanador.imagen?.isEmpty ?? true)
                              ? const Icon(Icons.person, size: 40, color: Color(0xFF002855))
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          candidatoGanador.nombre,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Flexible(
                          child: Text(
                            "#${candidatoGanador.numero} - ${candidatoGanador.semestre}",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.8),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "${vm.conteoVotos[candidatoGanador.id]} VOTOS",
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "¡Felicidades al nuevo Delegado UC!",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ] else if (candidatosOrdenados.isNotEmpty && totalVotos > 0) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.emoji_events, color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        "🏆 Líderes",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF002855),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 120,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (candidatosOrdenados.length > 1)
                        _buildPodioItem(
                          candidato: candidatosOrdenados[1],
                          votos: vm.conteoVotos[candidatosOrdenados[1].id] ?? 0,
                          totalVotos: totalVotos,
                          posicion: 2,
                        ),
                      if (candidatosOrdenados.length > 1) const SizedBox(width: 6),
                      _buildPodioItem(
                        candidato: candidatosOrdenados.first,
                        votos: vm.conteoVotos[candidatosOrdenados.first.id] ?? 0,
                        totalVotos: totalVotos,
                        posicion: 1,
                      ),
                      if (candidatosOrdenados.length > 2) const SizedBox(width: 6),
                      if (candidatosOrdenados.length > 2)
                        _buildPodioItem(
                          candidato: candidatosOrdenados[2],
                          votos: vm.conteoVotos[candidatosOrdenados[2].id] ?? 0,
                          totalVotos: totalVotos,
                          posicion: 3,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Mensaje de progreso hacia el ganador
              if (!hayGanador)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF002855).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.info_outline, color: Color(0xFF002855), size: 18),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            "El primer candidato en alcanzar ${VotacionService.VOTOS_PARA_GANAR} votos será el ganador",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF002855),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: candidatosOrdenados.length,
                  itemBuilder: (_, index) {
                    final candidato = candidatosOrdenados[index];
                    final votos = vm.conteoVotos[candidato.id] ?? 0;
                    final porcentaje = totalVotos > 0 ? (votos / totalVotos * 100) : 0.0;
                    final isLider = candidato.id == liderId && totalVotos > 0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: isLider
                            ? Border.all(color: Colors.amber, width: 2)
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: _getPosicionColor(index + 1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      "${index + 1}",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: const Color(0xFF002855).withOpacity(0.1),
                                  backgroundImage: (candidato.imagen?.isNotEmpty ?? false)
                                      ? NetworkImage(candidato.imagen!)
                                      : null,
                                  child: (candidato.imagen?.isEmpty ?? true)
                                      ? const Icon(Icons.person, size: 18, color: Color(0xFF002855))
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              candidato.nombre,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF002855),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (isLider) ...[
                                            const SizedBox(width: 6),
                                            const Icon(
                                              Icons.emoji_events,
                                              color: Colors.amber,
                                              size: 16,
                                            ),
                                          ],
                                        ],
                                      ),
                                      Text(
                                        "#${candidato.numero} - ${candidato.semestre}",
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "$votos",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: isLider
                                            ? Colors.amber[700]
                                            : const Color(0xFF002855),
                                      ),
                                    ),
                                    Text(
                                      "${porcentaje.toStringAsFixed(1)}%",
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: totalVotos > 0 ? votos / totalVotos : 0,
                                minHeight: 6,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _getPosicionColor(index + 1),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildPodioItem({
    required dynamic candidato,
    required int votos,
    required int totalVotos,
    required int posicion,
  }) {
    final porcentaje = totalVotos > 0 ? (votos / totalVotos * 100) : 0.0;
    
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getPosicionColor(posicion),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (posicion == 1)
              const Icon(Icons.emoji_events, color: Colors.amber, size: 20),
            if (posicion == 2)
              const Icon(Icons.workspace_premium, color: Colors.grey, size: 16),
            if (posicion == 3)
              const Icon(Icons.military_tech, color: Colors.brown, size: 16),
            const SizedBox(height: 4),
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF002855).withOpacity(0.1),
              backgroundImage: (candidato.imagen?.isNotEmpty ?? false)
                  ? NetworkImage(candidato.imagen!)
                  : null,
              child: (candidato.imagen?.isEmpty ?? true)
                  ? const Icon(Icons.person, size: 16, color: Color(0xFF002855))
                  : null,
            ),
            const SizedBox(height: 4),
            Text(
              candidato.nombre.split(' ').first,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF002855),
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              "$votos (${porcentaje.toStringAsFixed(0)}%)",
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPosicionColor(int posicion) {
    switch (posicion) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey;
      case 3:
        return Colors.brown;
      default:
        return const Color(0xFF002855);
    }
  }
}
