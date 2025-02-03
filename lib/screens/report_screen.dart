import 'package:flutter/material.dart';
import 'package:who_location_app/api/report_api.dart';
import 'package:who_location_app/config/app_config.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class ReportScreen extends StatefulWidget {
  final bool isAdmin;
  final void Function() onUnauthorized;

  const ReportScreen({Key? key, required this.isAdmin, required this.onUnauthorized}) : super(key: key);

  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  late ReportApi _reportApi;
  List<dynamic> _reports = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _reportApi = ReportApi(widget.onUnauthorized);
    _fetchReports();
  }

  Future<void> _syncLocalReports(List<dynamic> serverReports) async {
    final directory = await getApplicationDocumentsDirectory();
    // List all local files in the application documents directory.
    final localFiles = Directory(directory.path)
        .listSync()
        .whereType<File>()
        .toList();
    final serverReportNames = serverReports.map((r) => r['name']).toSet();
    for (final file in localFiles) {
      final name = file.path.split('/').last;
      if (!serverReportNames.contains(name)) {
        try {
          await file.delete();
          debugPrint('Local report file $name deleted as it does not exist on server');
        } catch (e) {
          debugPrint('Failed to delete local file $name: $e');
        }
      }
    }
  }

  Future<void> _fetchReports() async {
    setState(() { _loading = true; });
    try {
      final reports = await _reportApi.listReports();
      setState(() { _reports = reports; });
      // Synchronize local report files with the server's report list.
      await _syncLocalReports(reports);
    } catch (e) {
      debugPrint('Error fetching reports: $e');
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _downloadReport(String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = "${directory.path}/$filename";
    final file = File(filePath);
    // Check if the file already exists locally.
    if (await file.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File already exists on device'))
      );
      return;
    }
    try {
      final reportText = await _reportApi.downloadReport(filename);
      await file.writeAsString(reportText);
      
      debugPrint('File saved at: $filePath');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File downloaded successfully'))
      );
    } catch (e) {
      debugPrint('Error downloading report: $e');
    }
  }

  Future<void> _deleteReport(String filename) async {
    try {
      await _reportApi.deleteReport(filename); // Send DELETE request to the server.
      
      // Update state by removing the report.
      setState(() {
        _reports.removeWhere((r) => r['name'] == filename);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reporte $filename eliminado'))
      );
      _fetchReports(); // Update the list to remove the deleted report.
    } catch (e) {
      debugPrint('Error deleting report: $e');
    }
  }

  Future<void> _generateReport() async {
    try {
      final newReport = await _reportApi.generateReport();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Nuevo reporte generado: ${newReport['filename']}')));
      _fetchReports();
    } catch (e) {
      debugPrint('Error generating report: $e');
    }
  }

  Future<void> _openReport(String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = "${directory.path}/$filename";
    final file = File(filePath);
    // Check if the file is already downloaded.
    if (!await file.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File is not downloaded'))
      );
      return;
    }
    try {
      debugPrint('Opening file: $filePath');
      await OpenFile.open(filePath);
    } catch (e) {
      debugPrint('Error opening report: $e');
    }
  }

  // Show a dialog to generate a new report with an optional date selection.
  Future<void> _showGenerateReportDialog() async {
    DateTime? selectedDate;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text("Generar Reporte"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Seleccione una fecha (opcional):"),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                  child: Text("Seleccionar Fecha"),
                ),
                if (selectedDate != null) ...[
                  SizedBox(height: 10),
                  Text("Fecha seleccionada: ${selectedDate!.toLocal().toString().split(' ')[0]}"),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text("Cancelar"),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text("Generar"),
              ),
            ],
          );
        });
      },
    );
    if (confirmed != true) {
      return;
    }
    try {
      final newReport = await _reportApi.generateReport(reportDate: selectedDate);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nuevo reporte generado: ${newReport['filename']}'))
      );
      _fetchReports();
    } catch (e) {
      debugPrint('Error generating report: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Reports", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        actions: [
          if(widget.isAdmin)
            IconButton(
              icon: Icon(Icons.add),
              onPressed: _showGenerateReportDialog,
              tooltip: "Generate new report",
            )
        ],
      ),
      body: Container(
        color: Colors.white,
        child: _loading 
          ? Center(child: CircularProgressIndicator())
          : _reports.isEmpty 
              ? Center(child: Text("No reports to show", style: TextStyle(fontSize: 18, color: Colors.grey)))
              : Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Available Reports", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      SizedBox(height: 12),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _reports.length,
                          itemBuilder: (context, index) {
                            final report = _reports[index];
                            final filename = report['name'];
                            return Card(
                              elevation: 2,
                              margin: EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              child: ListTile(
                                contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                title: Text(filename, style: TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text("Size: ${report['size']} bytes\nModified: ${report['modified_time']}"),
                                trailing: Wrap(
                                  spacing: 8,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.download),
                                      onPressed: () => _downloadReport(filename),
                                      tooltip: "Download report",
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.open_in_new),
                                      onPressed: () => _openReport(filename),
                                      tooltip: "Open report",
                                    ),
                                    if(widget.isAdmin)
                                      IconButton(
                                        icon: Icon(Icons.delete),
                                        onPressed: () => _deleteReport(filename),
                                        tooltip: "Delete report",
                                      )
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}