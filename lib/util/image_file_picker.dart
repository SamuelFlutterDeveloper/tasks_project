import 'dart:async';
import 'dart:io' show File;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class UniversalFilePicker extends StatefulWidget {
  final String title;
  final Function(List<File>)? onFilesSelected;
  final Function(List<Uint8List>, List<String>)? onFilesSelectedWeb;
  final String? propertyId;
  final bool enableUpload;
  final Color? iconColor;
  final Color? textColor;

  const UniversalFilePicker({
    super.key,
    this.title = "Upload Attachment",
    this.onFilesSelected,
    this.onFilesSelectedWeb,
    this.propertyId,
    this.enableUpload = true,
    this.iconColor,
    this.textColor,
  });

  @override
  State<UniversalFilePicker> createState() => _UniversalFilePickerState();
}

class _UniversalFilePickerState extends State<UniversalFilePicker> {
  // Mobile/Desktop
  final List<File> _selectedFiles = [];
  // Web
  final List<Uint8List> _selectedFilesWeb = [];
  final List<String> _selectedFileNames = [];

  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  Future<Uint8List?> _captureFromWebcam() async {
    if (kIsWeb) {
      try {
        // For web, use HTML5 webcam
        final bytes = await _webCaptureFromWebcam();
        return bytes;
      } catch (e) {
        print('Web webcam capture failed: $e');
        return null;
      }
    } else {
      // For mobile, use image_picker camera
      try {
        final picker = ImagePicker();
        final image = await picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
        );
        if (image != null) {
          final file = File(image.path);
          return await file.readAsBytes();
        }
      } catch (e) {
        print('Mobile camera capture failed: $e');
      }
      return null;
    }
  }

  // Web-specific webcam capture (only included in web builds)
  Future<Uint8List?> _webCaptureFromWebcam() async {
    // This function should be in a separate web-only file
    // For now, we'll implement a simplified version
    if (!kIsWeb) return null;

    try {
      // Create a file picker for web that simulates camera
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null &&
          result.files.isNotEmpty &&
          result.files.first.bytes != null) {
        return result.files.first.bytes!;
      }
    } catch (e) {
      print('Web camera simulation failed: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final hasFiles = kIsWeb
        ? _selectedFilesWeb.isNotEmpty
        : _selectedFiles.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: widget.textColor ?? Colors.blue[700],
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _showPickerOptions,
          child: Container(
            width: double.infinity,
            height: 140,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, width: 1.5),
            ),
            child: _isUploading
                ? _buildUploadProgress()
                : hasFiles
                ? _buildFileGrid()
                : _buildEmptyState(),
          ),
        ),
        if (hasFiles && widget.enableUpload && widget.propertyId != null)
          _buildUploadButton(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_upload_outlined,
            size: 48,
            color: widget.iconColor ?? Colors.blue[600],
          ),
          const SizedBox(height: 8),
          Text(
            "Tap to upload files",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            kIsWeb
                ? "Supports: Images, PDF, DOC, DOCX"
                : "Supports: Images, Documents",
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildFileGrid() {
    final fileCount = kIsWeb ? _selectedFilesWeb.length : _selectedFiles.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Selected Files ($fileCount)",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            TextButton.icon(
              onPressed: _showPickerOptions,
              icon: const Icon(Icons.add, size: 18),
              label: const Text("Add More"),
              style: TextButton.styleFrom(foregroundColor: Colors.blue[700]),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: fileCount,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) => _buildFileItem(index),
          ),
        ),
      ],
    );
  }

  Widget _buildFileItem(int index) {
    if (kIsWeb) {
      final fileBytes = _selectedFilesWeb[index];
      final fileName = _selectedFileNames[index];
      final isImage = _isImageFile(fileName);
      final fileSize = _formatFileSize(fileBytes.length);

      return _buildFileDisplay(
        index: index,
        fileName: fileName,
        fileSize: fileSize,
        child: isImage
            ? Image.memory(
                fileBytes,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildFileIcon(fileName),
              )
            : _buildFileIcon(fileName),
      );
    } else {
      final file = _selectedFiles[index];
      final fileName = file.path.split('/').last;
      final isImage = _isImageFile(fileName);
      final fileSize = _formatFileSize(file.lengthSync());

      return _buildFileDisplay(
        index: index,
        fileName: fileName,
        fileSize: fileSize,
        child: isImage
            ? Image.file(
                file,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildFileIcon(fileName),
              )
            : _buildFileIcon(fileName),
      );
    }
  }

  Widget _buildFileDisplay({
    required int index,
    required String fileName,
    required String fileSize,
    required Widget child,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: child,
          ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: GestureDetector(
            onTap: () => _removeFile(index),
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: const BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName.length > 12
                      ? '${fileName.substring(0, 10)}...'
                      : fileName,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  fileSize,
                  style: const TextStyle(fontSize: 9, color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFileIcon(String fileName) {
    final icon = _getFileIcon(fileName);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: Colors.blue[700]),
          const SizedBox(height: 4),
          Text(
            fileName.length > 10 ? '${fileName.substring(0, 8)}...' : fileName,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadProgress() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(
          value: _uploadProgress,
          strokeWidth: 3,
          color: Colors.blue[700],
        ),
        const SizedBox(height: 12),
        Text(
          _uploadProgress < 1.0 ? "Uploading..." : "Upload Complete!",
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "${(_uploadProgress * 100).toStringAsFixed(0)}%",
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildUploadButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isUploading ? null : _uploadFiles,
          icon: const Icon(Icons.cloud_upload, size: 20),
          label: const Text(
            "Upload to Server",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 2,
          ),
        ),
      ),
    );
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header (omitted)
                if (kIsWeb) ...[
                  _buildOptionTile(
                    icon: Icons.photo_library,
                    title: "Select Files",
                    subtitle: "Images, PDF, DOC, DOCX",
                    onTap: _pickGeneralFiles,
                  ),
                  // WEBCAM OPTION IS RESTORED, calling the wrapper method
                  _buildOptionTile(
                    icon: Icons.camera_alt,
                    title: "Use Webcam",
                    subtitle: "Capture new photo",
                    onTap: _captureFromWebcamHandler, // New Handler
                  ),
                ] else ...[
                  _buildOptionTile(
                    icon: Icons.photo_library,
                    title: "Gallery",
                    subtitle: "Pick multiple images",
                    onTap: _pickImagesFromGallery,
                  ),
                  _buildOptionTile(
                    icon: Icons.camera_alt,
                    title: "Camera",
                    subtitle: "Capture new photo",
                    onTap: _pickFromCamera,
                  ),
                  _buildOptionTile(
                    icon: Icons.picture_as_pdf,
                    title: "Documents",
                    subtitle: "PDF, DOC, DOCX files",
                    onTap: _pickGeneralFiles,
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _captureFromWebcamHandler() async {
    try {
      final bytes = await _captureFromWebcam();
      if (bytes != null && bytes.isNotEmpty) {
        setState(() {
          _selectedFilesWeb.add(bytes);
          // Give the webcam capture a unique file name
          _selectedFileNames.add(
            'webcam_${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
        });
        _notifyFilesSelectedWeb();
        Navigator.pop(context); // Close the modal if capture was successful
      }
    } catch (e) {
      _showError('Failed to capture from webcam: $e');
    }
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.blue[700]),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey[500],
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  // ==============================
  // MOBILE/WEB COMMON FILE PICKER
  // ==============================
  Future<void> _pickGeneralFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'jpeg', 'png'],
        withData: kIsWeb, // Get bytes for web
        withReadStream: !kIsWeb, // Get path for mobile/desktop
      );

      if (result != null && result.files.isNotEmpty) {
        if (kIsWeb) {
          setState(() {
            for (var file in result.files) {
              if (file.bytes != null) {
                _selectedFilesWeb.add(file.bytes!);
                _selectedFileNames.add(file.name);
              }
            }
          });
          _notifyFilesSelectedWeb();
        } else {
          setState(() {
            for (var file in result.files) {
              if (file.path != null) {
                _selectedFiles.add(File(file.path!));
              }
            }
          });
          _notifyFilesSelected();
        }
      }
    } catch (e) {
      _showError('Failed to pick files: $e');
    }
  }

  // ==============================
  // MOBILE ONLY METHODS (using image_picker)
  // ==============================
  Future<void> _pickImagesFromGallery() async {
    try {
      final List<XFile>? images = await _picker.pickMultiImage(
        imageQuality: 85,
      );
      if (images != null && images.isNotEmpty) {
        setState(() => _selectedFiles.addAll(images.map((x) => File(x.path))));
        _notifyFilesSelected();
      }
    } catch (e) {
      _showError('Failed to pick images: $e');
    }
  }

  Future<void> _pickFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() => _selectedFiles.add(File(image.path)));
        _notifyFilesSelected();
      }
    } catch (e) {
      _showError('Failed to capture image: $e');
    }
  }

  // ==============================
  // COMMON METHODS
  // ==============================
  void _removeFile(int index) {
    setState(() {
      if (kIsWeb) {
        _selectedFilesWeb.removeAt(index);
        _selectedFileNames.removeAt(index);
        _notifyFilesSelectedWeb();
      } else {
        _selectedFiles.removeAt(index);
        _notifyFilesSelected();
      }
    });
  }

  void _notifyFilesSelected() {
    if (widget.onFilesSelected != null) {
      widget.onFilesSelected!(_selectedFiles);
    }
  }

  void _notifyFilesSelectedWeb() {
    if (widget.onFilesSelectedWeb != null) {
      widget.onFilesSelectedWeb!(_selectedFilesWeb, _selectedFileNames);
    }
  }

  Future<void> _uploadFiles() async {
    // Placeholder for actual upload logic
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      // Simulate upload process
      await Future.delayed(const Duration(milliseconds: 500));
      for (int i = 1; i <= 10; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
        setState(() => _uploadProgress = i / 10);
      }

      _showSuccess('Files uploaded successfully!');
    } catch (e) {
      _showError('Upload failed: $e');
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
        // Optionally clear files after successful upload
        // _selectedFiles.clear();
        // _selectedFilesWeb.clear();
        // _selectedFileNames.clear();
      });
    }
  }

  // ==============================
  // UTILITY METHODS
  // ==============================
  bool _isImageFile(String fileName) {
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];
    final ext = fileName.toLowerCase();
    return imageExtensions.any(ext.endsWith);
  }

  IconData _getFileIcon(String fileName) {
    if (_isImageFile(fileName)) return Icons.image;
    if (fileName.endsWith('.pdf')) return Icons.picture_as_pdf;
    if (fileName.endsWith('.doc') || fileName.endsWith('.docx'))
      return Icons.description;
    if (fileName.endsWith('.txt')) return Icons.text_snippet;
    return Icons.insert_drive_file;
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
