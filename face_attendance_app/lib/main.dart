import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Face Attendance',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const AttendanceHomePage(),
    );
  }
}

class AttendanceHomePage extends StatefulWidget {
  const AttendanceHomePage({super.key});

  @override
  State<AttendanceHomePage> createState() => _AttendanceHomePageState();
}

class _AttendanceHomePageState extends State<AttendanceHomePage> {
  Map<String, String> attendance = {};
  String savedFile = "";
  bool isLoading = false;
  bool isCapturing = false;

  final String apiUrl = "http://172.26.16.1:9000";
  final TextEditingController nameController = TextEditingController();
  String selectedStatus = "P";

  // ------------------ START ATTENDANCE ------------------
  Future<void> startAttendance() async {
    setState(() {
      isLoading = true;
      isCapturing = true;
    });

    try {
      final url = Uri.parse("$apiUrl/start-attendance");
      final response = await http.get(url).timeout(const Duration(seconds: 30));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Safe null handling
        final rawAttendance = data['attendance'] as Map<String, dynamic>?;
        setState(() {
          attendance = rawAttendance != null
              ? rawAttendance.map(
                  (k, v) => MapEntry(k.toString(), v.toString()),
                )
              : {};
          savedFile = data['saved_file'] ?? "";
        });

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Attendance Completed"),
            content: Text("Saved in: $savedFile"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Server Error: ${response.statusCode}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
          isCapturing = false;
        });
      }
    }
  }

  Future<void> addFace(String name) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) return;

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.0.104:9000/add-face'),
      );
      request.fields['name'] = name;
      request.files.add(await http.MultipartFile.fromPath('file', image.path));

      var response = await request.send();
      final resBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        debugPrint("✅ Face added: $resBody");
        if (!mounted) return; // 👈 added line
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("$name added successfully!")));
      } else {
        debugPrint("❌ Failed to add face: ${response.statusCode}");
        if (!mounted) return; // 👈 added line
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to add $name")));
      }
    } catch (e) {
      debugPrint("⚠️ Error adding face: $e");
      if (!mounted) return; // 👈 added line
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // ------------------ STOP ATTENDANCE ------------------
  Future<void> stopAttendance() async {
    try {
      final url = Uri.parse("$apiUrl/stop-attendance");
      final response = await http.get(url);

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          isCapturing = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Attendance stopped")));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error stopping: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ------------------ MANUAL MARK ------------------
  Future<void> manualMark() async {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter a name")));
      return;
    }

    try {
      final url = Uri.parse("$apiUrl/manual-mark");
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'status': selectedStatus}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Safe null handling
        final rawAttendance = data['attendance'] as Map<String, dynamic>?;
        setState(() {
          attendance = rawAttendance != null
              ? rawAttendance.map(
                  (k, v) => MapEntry(k.toString(), v.toString()),
                )
              : {};
          nameController.clear();
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("$name marked $selectedStatus")));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error marking $name")));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Connection Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ------------------ RESET ATTENDANCE ------------------
  Future<void> resetAttendance() async {
    try {
      final url = Uri.parse("$apiUrl/reset-attendance");
      final response = await http.get(url);

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          attendance = {};
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Attendance reset")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error resetting attendance")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Connection Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ------------------ MANUAL MARK INDIVIDUAL ------------------
  Future<void> manualMarkIndividual(String name, String status) async {
    try {
      final url = Uri.parse("$apiUrl/manual-mark");
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'status': status}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Safe null handling
        final rawAttendance = data['attendance'] as Map<String, dynamic>?;
        setState(() {
          attendance = rawAttendance != null
              ? rawAttendance.map(
                  (k, v) => MapEntry(k.toString(), v.toString()),
                )
              : {};
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("$name marked $status")));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  // ------------------ BUILD ATTENDANCE LIST ------------------
  Widget buildAttendanceList() {
    if (attendance.isEmpty) {
      return const Center(
        child: Text(
          "No attendance data yet.\nClick 'Start Attendance' to begin.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: attendance.length,
      itemBuilder: (context, index) {
        final name = attendance.keys.elementAt(index);
        final status = attendance[name];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
          child: ListTile(
            title: Text(name),
            subtitle: Text("Status: $status"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () => manualMarkIndividual(name, "P"),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => manualMarkIndividual(name, "A"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ------------------ SHOW MANUAL MARK DIALOG ------------------
  void showManualMarkDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Manual Attendance"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: selectedStatus,
              items: const [
                DropdownMenuItem(value: "P", child: Text("Present (P)")),
                DropdownMenuItem(value: "A", child: Text("Absent (A)")),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedStatus = value;
                  });
                }
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Status',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              manualMark();
            },
            child: const Text("Mark"),
          ),
        ],
      ),
    );
  }

  // ------------------ BUILD ------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Face Attendance"),
        actions: [
          if (attendance.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: resetAttendance,
              tooltip: "Reset Attendance",
            ),
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: showManualMarkDialog,
            tooltip: "Manual Attendance",
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: isLoading ? null : startAttendance,
                    icon: isLoading && isCapturing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.camera_alt),
                    label: isLoading && isCapturing
                        ? const Text("Processing...")
                        : const Text("Start Attendance"),
                  ),
                ),
                if (isCapturing) ...[
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: stopAttendance,
                    icon: const Icon(Icons.stop),
                    label: const Text("Stop"),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // 👇 Add Face Buttons Section
            Text(
              "Add Predefined Faces:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => addFace("Alice"),
                  child: const Text("Add Alice"),
                ),
                ElevatedButton(
                  onPressed: () => addFace("Bob"),
                  child: const Text("Add Bob"),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Text(
              "Attendance Records:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(child: buildAttendanceList()),
            ),
          ],
        ),
      ),
    );
  }
}
