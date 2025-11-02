import 'package:flutter/material.dart';
import 'dart:math'; // ADD THIS IMPORT for cos/sin functions
import '../models/user_model.dart';

class NetworkGraph extends StatelessWidget {
  final Map<String, dynamic> networkData;
  final User? selectedUser;
  final List<Recommendation> recommendations;

  const NetworkGraph({
    super.key,
    required this.networkData,
    this.selectedUser,
    required this.recommendations,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'Network Visualization',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildLegend(),
          const SizedBox(height: 16),
          Container(
            height: 400,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: _buildSimpleGraph()),
          ),
          const SizedBox(height: 16),
          _buildNetworkStats(),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(Colors.red, 'You'),
        const SizedBox(width: 16),
        _buildLegendItem(Colors.orange, 'Recommended'),
        const SizedBox(width: 16),
        _buildLegendItem(Colors.blue, 'Other Users'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(text),
      ],
    );
  }

  Widget _buildSimpleGraph() {
    final nodes = networkData['nodes'] as List;
    final edges = networkData['edges'] as List;

    return CustomPaint(
      size: const Size(300, 300),
      painter: NetworkGraphPainter(
        nodes: nodes,
        edges: edges,
        selectedUserId: selectedUser?.id,
        recommendationIds: recommendations.map((r) => r.id).toList(),
      ),
    );
  }

  Widget _buildNetworkStats() {
    final nodes = networkData['nodes'] as List;
    final edges = networkData['edges'] as List;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Network Statistics',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total Users', nodes.length.toString()),
                _buildStatItem('Connections', edges.length.toString()),
                _buildStatItem(
                  'Recommendations',
                  recommendations.length.toString(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}

class NetworkGraphPainter extends CustomPainter {
  final List<dynamic> nodes;
  final List<dynamic> edges;
  final int? selectedUserId;
  final List<int> recommendationIds;

  NetworkGraphPainter({
    required this.nodes,
    required this.edges,
    this.selectedUserId,
    required this.recommendationIds,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 30;

    // Calculate node positions in a circle
    final nodePositions = <int, Offset>{};
    for (int i = 0; i < nodes.length; i++) {
      final angle = 2 * pi * i / nodes.length; // Use pi from dart:math
      final x = center.dx + radius * cos(angle); // Now cos is available
      final y = center.dy + radius * sin(angle); // Now sin is available
      nodePositions[nodes[i]['id']] = Offset(x, y);
    }

    // Draw edges
    final edgePaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;

    for (final edge in edges) {
      final from = nodePositions[edge['from']];
      final to = nodePositions[edge['to']];
      if (from != null && to != null) {
        canvas.drawLine(from, to, edgePaint);
      }
    }

    // Draw nodes
    for (final node in nodes) {
      final position = nodePositions[node['id']];
      if (position != null) {
        final color = _getNodeColor(node['id']);
        final nodePaint = Paint()..color = color;

        canvas.drawCircle(position, 12, nodePaint);

        // Draw node label
        final textPainter = TextPainter(
          text: TextSpan(
            text: node['label'][0], // First letter of name
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          position - Offset(textPainter.width / 2, textPainter.height / 2),
        );
      }
    }
  }

  Color _getNodeColor(int nodeId) {
    if (nodeId == selectedUserId) {
      return Colors.red;
    } else if (recommendationIds.contains(nodeId)) {
      return Colors.orange;
    } else {
      return Colors.blue;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
