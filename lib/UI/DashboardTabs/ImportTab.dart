import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:solobytes/Providers/auth_provider.dart';
import 'package:solobytes/Providers/import_provider.dart';

class ImportTab extends ConsumerStatefulWidget {
  const ImportTab({Key? key}) : super(key: key);

  @override
  ConsumerState<ImportTab> createState() => _ImportTabState();
}

class _ImportTabState extends ConsumerState<ImportTab> {
  Uint8List? _fileBytes;
  String? _fileName;

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
  type: FileType.custom,
  allowedExtensions: ['xlsx', 'xls'],
  withData: true,
);

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _fileBytes = result.files.single.bytes;
        _fileName = result.files.single.name;
      });

      ref
          .read(importProvider.notifier)
          .parseFile(fileName: _fileName!, fileBytes: _fileBytes!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final importState = ref.watch(importProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Import from Excel',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: importState.isLoading ? null : _pickFile,
            icon: const Icon(Icons.upload_file),
            label: const Text('Select Excel File'),
          ),
          const SizedBox(height: 16),
          if (importState.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (importState.errorMessage != null)
            Card(
              color: Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        importState.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (importState.isImportCompleted)
            Card(
              color: Colors.green[50],
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Import completed successfully!',
                        style: TextStyle(color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (importState.previewResult != null) ...[
            Text('Preview: $_fileName'),
            const SizedBox(height: 8),
            Text('Valid Schema: ${importState.previewResult!.isSchemaValid}'),
            Text(
              'Transactions: ${importState.previewResult!.transactions.length}',
            ),
            Text(
              'Receivables: ${importState.previewResult!.receivables.length}',
            ),
            const SizedBox(height: 16),
            if (importState.previewResult!.isSchemaValid && _fileBytes != null)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final user = ref.read(authUserProvider);
                  if (user != null) {
                    await ref
                        .read(importProvider.notifier)
                        .confirmImport(
                          userId: user.uid,
                          originalFileBytes: _fileBytes!,
                        );
                  }
                },
                child: const Text('Confirm Import'),
              ),
          ] else
            const Text('Select an excel file to see preview.'),
        ],
      ),
    );
  }
}
