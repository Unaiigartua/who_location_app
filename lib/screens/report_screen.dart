import 'package:flutter/material.dart';
import 'package:who_location_app/api/report_api.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class ReportScreen extends StatefulWidget {
  final bool isAdmin;
  final void Function() onUnauthorized;

  const ReportScreen(
      {Key? key, required this.isAdmin, required this.onUnauthorized})
      : super(key: key);

  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  late ReportApi _reportApi;
  List<dynamic> _reports = [];
  bool _loading = false;
  String _searchQuery = '';
  bool _sortAscending = false; // false means newest first

  @override
  void initState() {
    super.initState();
    _reportApi = ReportApi(widget.onUnauthorized);
    _fetchReports();
  }

  Future<void> _syncLocalReports(List<dynamic> serverReports) async {
    final directory = await getApplicationDocumentsDirectory();
    // List all local files in the application documents directory.
    final localFiles =
        Directory(directory.path).listSync().whereType<File>().toList();
    final serverReportNames = serverReports.map((r) => r['name']).toSet();
    for (final file in localFiles) {
      final name = file.path.split('/').last;
      if (!serverReportNames.contains(name)) {
        try {
          await file.delete();
          debugPrint(
              'Local report file $name deleted as it does not exist on server');
        } catch (e) {
          debugPrint('Failed to delete local file $name: $e');
        }
      }
    }
  }

  Future<void> _fetchReports() async {
    setState(() {
      _loading = true;
    });
    try {
      final reports = await _reportApi.listReports();
      setState(() {
        _reports = reports;
        _sortReports(); // Sort reports after fetching
      });
      await _syncLocalReports(reports);
    } catch (e) {
      debugPrint('Error fetching reports: $e');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _downloadReport(String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = "${directory.path}/$filename";
    final file = File(filePath);
    // Check if the file already exists locally.
    if (await file.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File already exists on device')));
      return;
    }
    try {
      final reportText = await _reportApi.downloadReport(filename);
      await file.writeAsString(reportText);

      debugPrint('File saved at: $filePath');
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File downloaded successfully')));
    } catch (e) {
      debugPrint('Error downloading report: $e');
    }
  }

  Future<void> _deleteReport(String filename) async {
    try {
      await _reportApi
          .deleteReport(filename); // Send DELETE request to the server.

      // Update state by removing the report.
      setState(() {
        _reports.removeWhere((r) => r['name'] == filename);
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Reporte $filename eliminado')));
      _fetchReports(); // Update the list to remove the deleted report.
    } catch (e) {
      debugPrint('Error deleting report: $e');
    }
  }

  Future<void> _openReport(String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = "${directory.path}/$filename";
    final file = File(filePath);
    // Check if the file is already downloaded.
    if (!await file.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File is not downloaded')));
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
            title: const Text("Generate Report"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Select a date (optional):"),
                const SizedBox(height: 10),
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
                  child: const Text("Select Date"),
                ),
                if (selectedDate != null) ...[
                  const SizedBox(height: 10),
                  Text(
                      "Selected date: ${selectedDate!.toLocal().toString().split(' ')[0]}"),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text("Generate"),
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
      final newReport =
          await _reportApi.generateReport(reportDate: selectedDate);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('New report generated: ${newReport['filename']}')));
      _fetchReports();
    } catch (e) {
      debugPrint('Error generating report: $e');
    }
  }

  // Add sort function
  void _sortReports() {
    _reports.sort((a, b) {
      final DateTime dateA = DateTime.parse(a['modified_time']);
      final DateTime dateB = DateTime.parse(b['modified_time']);
      return _sortAscending ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
    });
  }

  // Add filter function
  List<dynamic> _getFilteredReports() {
    if (_searchQuery.isEmpty) {
      return _reports;
    }
    return _reports
        .where((report) => report['name']
            .toString()
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()))
        .toList();
  }

  Future<bool> _isReportDownloaded(String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = "${directory.path}/$filename";
    return File(filePath).exists();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Reports",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchReports,
            tooltip: "Refresh reports",
          ),
          if (widget.isAdmin)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showGenerateReportDialog,
              tooltip: "Generate new report",
            )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchReports,
        child: Container(
          color: Colors.white,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                hintText: 'Search reports...',
                                prefixIcon: Icon(Icons.search),
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(context).colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    _sortAscending
                                        ? Icons.arrow_upward
                                        : Icons.arrow_downward,
                                    size: 20,
                                  ),
                                  tooltip: _sortAscending
                                      ? 'Oldest first'
                                      : 'Newest first',
                                  onPressed: () {
                                    setState(() {
                                      _sortAscending = !_sortAscending;
                                      _sortReports();
                                    });
                                  },
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: Text(
                                    _sortAscending ? 'Oldest' : 'Newest',
                                    style:
                                        Theme.of(context).textTheme.labelMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _reports.isEmpty
                          ? const Center(
                              child: Text("No reports to show",
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.grey)))
                          : Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: ListView.builder(
                                itemCount: _getFilteredReports().length,
                                itemBuilder: (context, index) {
                                  final report = _getFilteredReports()[index];
                                  final filename = report['name'];
                                  return Card(
                                    elevation: 2,
                                    margin: const EdgeInsets.only(bottom: 12),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 8, horizontal: 16),
                                      title: Text(filename,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600)),
                                      subtitle: Text(
                                          "Size: ${report['size']} bytes\nModified: ${report['modified_time']}"),
                                      trailing: FutureBuilder<bool>(
                                        future: _isReportDownloaded(filename),
                                        builder: (context, snapshot) {
                                          final isDownloaded =
                                              snapshot.data ?? false;
                                          return Wrap(
                                            spacing: 8,
                                            children: [
                                              if (!isDownloaded)
                                                IconButton(
                                                  icon: const Icon(
                                                      Icons.download),
                                                  onPressed: () async {
                                                    await _downloadReport(
                                                        filename);
                                                    setState(
                                                        () {}); // Refresh UI after download
                                                  },
                                                  tooltip: "Download report",
                                                )
                                              else
                                                IconButton(
                                                  icon: const Icon(Icons
                                                      .description_outlined),
                                                  onPressed: () =>
                                                      _openReport(filename),
                                                  tooltip: "Open report",
                                                ),
                                              if (widget.isAdmin)
                                                IconButton(
                                                  icon:
                                                      const Icon(Icons.delete),
                                                  onPressed: () => showDialog(
                                                    context: context,
                                                    builder: (context) =>
                                                        AlertDialog(
                                                      title: const Text(
                                                          'Delete Report'),
                                                      content: Text(
                                                          'Are you sure you want to delete "$filename"?'),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                  context),
                                                          child: const Text(
                                                              'Cancel'),
                                                        ),
                                                        TextButton(
                                                          onPressed: () {
                                                            Navigator.pop(
                                                                context);
                                                            _deleteReport(
                                                                filename);
                                                          },
                                                          child: const Text(
                                                              'Delete'),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  tooltip: "Delete report",
                                                ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
