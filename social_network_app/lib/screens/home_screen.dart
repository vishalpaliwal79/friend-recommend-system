import 'package:flutter/material.dart';
import 'package:social_network_app/models/user_model.dart';
import 'package:social_network_app/services/api_service.dart';
import 'package:social_network_app/widgets/recommendation_card.dart';
import 'package:social_network_app/widgets/network_graph.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  List<User> _users = [];
  User? _selectedUser;
  List<Recommendation> _recommendations = [];
  int _selectedDegree = 2;
  bool _isLoading = false;
  Map<String, dynamic>? _networkData;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadNetworkData();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final users = await _apiService.getUsers();
      setState(() {
        _users = users;
        if (users.isNotEmpty) {
          _selectedUser = users.first;
        }
      });
      if (_selectedUser != null) {
        await _loadRecommendations();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load users: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRecommendations() async {
    if (_selectedUser == null) return;

    setState(() {
      _isLoading = true;
    });
    try {
      final recommendations = await _apiService.getRecommendations(
        _selectedUser!.id,
        _selectedDegree,
      );
      setState(() {
        _recommendations = recommendations;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load recommendations: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadNetworkData() async {
    try {
      final data = await _apiService.getNetworkData();
      setState(() {
        _networkData = data;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load network data: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friend Recommendation System'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: _isLoading && _users.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Controls Section
                _buildControlsSection(),
                const SizedBox(height: 16),

                // Main Content
                Expanded(
                  child: DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        TabBar(
                          tabs: const [
                            Tab(text: 'Recommendations'),
                            Tab(text: 'Network Graph'),
                          ],
                          labelColor: Colors.blue[700],
                          indicatorColor: Colors.blue[700],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              // Recommendations Tab
                              _buildRecommendationsTab(),

                              // Network Graph Tab
                              _buildNetworkGraphTab(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildControlsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border.all(color: Colors.grey.shade700),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<User>(
                  initialValue: _selectedUser,
                  decoration: const InputDecoration(
                    labelText: 'Select User',
                    border: OutlineInputBorder(),
                  ),
                  items: _users.map((User user) {
                    return DropdownMenuItem<User>(
                      value: user,
                      child: Text(user.name),
                    );
                  }).toList(),
                  onChanged: (User? newValue) {
                    setState(() {
                      _selectedUser = newValue;
                    });
                    _loadRecommendations();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _selectedDegree,
                  decoration: const InputDecoration(
                    labelText: 'Degree of Separation',
                    border: OutlineInputBorder(),
                  ),
                  items: [1, 2, 3].map((int degree) {
                    return DropdownMenuItem<int>(
                      value: degree,
                      child: Text('$degree degree${degree > 1 ? 's' : ''}'),
                    );
                  }).toList(),
                  onChanged: (int? newValue) {
                    setState(() {
                      _selectedDegree = newValue!;
                    });
                    _loadRecommendations();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_selectedUser != null)
            Text(
              'Showing friends within $_selectedDegree degree(s) of ${_selectedUser!.name}',
              style: TextStyle(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_recommendations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No recommendations found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _recommendations.length,
      itemBuilder: (context, index) {
        final recommendation = _recommendations[index];
        return RecommendationCard(recommendation: recommendation);
      },
    );
  }

  Widget _buildNetworkGraphTab() {
    if (_networkData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return NetworkGraph(
      networkData: _networkData!,
      selectedUser: _selectedUser,
      recommendations: _recommendations,
    );
  }
}
