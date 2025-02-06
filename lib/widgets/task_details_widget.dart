import 'package:flutter/material.dart';
import 'package:who_location_app/models/task.dart';
import 'package:intl/intl.dart';
import 'package:who_location_app/utils/helpers.dart';

// TaskInfoWidget class
class TaskInfoWidget extends StatelessWidget {
  final Task task;

  const TaskInfoWidget({Key? key, required this.task}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Divider(height: 24, thickness: 1.5),
            Text(
              task.description,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Chip(
                  label: Text(formatStatus(task.status)),
                  backgroundColor: getStatusColor(task.status),
                  labelStyle: const TextStyle(color: Colors.white),
                ),
                const SizedBox(width: 8),
                Text(
                  'Created: ${DateFormat.yMMMd().add_Hm().format(task.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.black54,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ExpansionTile(
              title: const Text('Details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              childrenPadding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Created by', task.createdByUsername),
                _buildDetailRow(
                    'Assigned to', task.assignedToUsername ?? 'Unassigned'),
                if (task.updatedAt != null)
                  _buildDetailRow('Updated',
                      DateFormat.yMMMd().add_Hm().format(task.updatedAt!)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Build detail row for task info (folding part)
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              )),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(value,
                  style: const TextStyle(
                    color: Colors.black54,
                  )),
            ),
          ),
        ],
      ),
    );
  }
}

// TaskLogsWidget class
class TaskLogsWidget extends StatelessWidget {
  final Task task;
  final Future<void> Function() onRefresh;

  const TaskLogsWidget({Key? key, required this.task, required this.onRefresh})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: task.logs?.length ?? 0,
        itemBuilder: (context, index) {
          final log = task.logs![index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: ExpansionTile(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Chip(
                        label: Text(formatStatus(log.status)),
                        backgroundColor: getStatusColor(log.status),
                        labelStyle: const TextStyle(color: Colors.white),
                      ),
                      const Spacer(),
                      Text(
                        DateFormat.yMMMd().add_Hm().format(log.timestamp),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  if (log.assignedToUsername != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: _buildDetailRow(
                          'Assigned to', log.assignedToUsername!),
                    ),
                ],
              ),
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: -2,
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  margin: const EdgeInsets.all(8.0),
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow(
                          'Modified by', log.modifiedByUsername ?? 'Unknown'),
                      if (log.note.isNotEmpty)
                        _buildDetailRow('Note', log.note),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text('$label: ',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              )),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(value,
                  style: const TextStyle(
                    color: Colors.black54,
                  )),
            ),
          ),
        ],
      ),
    );
  }
}
