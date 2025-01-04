import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../services/points_service.dart';
import '../services/ocr_service.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';

class BillUploadScreen extends StatefulWidget {
  final bool isGridReturn;
  
  const BillUploadScreen({
    super.key,
    this.isGridReturn = false,
  });

  @override
  State<BillUploadScreen> createState() => _BillUploadScreenState();
}

class _BillUploadScreenState extends State<BillUploadScreen> {
  File? _image;
  String? _extractedText;
  Map<String, dynamic>? _analysis;
  bool _isProcessing = false;
  String? _errorMessage;
  final _imagePicker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _image = File(image.path);
          _extractedText = null;
          _analysis = null;
          _errorMessage = null;
          _isProcessing = true;
        });

        await _processBill(image.path);
      }
    } catch (e) {
      _handleError('Failed to pick image', e);
    }
  }

  Future<void> _processBill(String imagePath) async {
    try {
      // Step 1: Extract text using OCR
      final extractedText = await OcrService.processImage(imagePath);
      setState(() {
        _extractedText = extractedText;
      });

      // Step 2: Analyze text with Gemini
      final analysis = await OcrService.analyzeWithGemini(extractedText);
      setState(() {
        _analysis = analysis;
      });

      // Get user ID
      final userId = context.read<AuthProvider>().user?.email;
      if (userId == null) throw Exception('User not authenticated');

      // Ensure all values are properly parsed as numbers
      final double usage = _parseNumber(analysis['usage']);
      final double amount = _parseNumber(analysis['amount']);
      final double comparison = _parsePercentage(analysis['comparison']?.toString());
      final double renewable = _parsePercentage(analysis['renewable']?.toString());

      // Calculate points using the analysis data
      final pointsResult = await PointsService.calculatePointsFromBill(
        {
          'usage': usage,
          'amount': amount,
          'improvement': comparison,
          'renewable': renewable,
          'peakUsageReduction': analysis['peakUsageReduction'] ?? false,
          'returnedEnergy': widget.isGridReturn ? usage : 0.0,
          'billingPeriod': analysis['billingPeriod'] ?? 'Current Period',
          'meterNumber': analysis['meterNumber'] ?? 'N/A',
        },
        isGridReturn: widget.isGridReturn,
         // Make sure to pass the userId
      );

      // Ensure points are greater than 0
      if (pointsResult.points <= 0) {
        throw Exception('Invalid points calculation: ${pointsResult.points}');
      }

      // Update user points
      if (!mounted) return;
      await context.read<UserProvider>().updateGreenPoints(pointsResult.points);

      // Show success message
      if (!mounted) return;
      _showSuccessMessage(pointsResult);
    } catch (e) {
      print('Error in _processBill: $e'); // Detailed error logging
      _handleError('Error processing bill', e);
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  double _parseNumber(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    try {
      return double.parse(value.toString().replaceAll(RegExp(r'[^\d.-]'), ''));
    } catch (e) {
      print('Error parsing number: $value');
      return 0.0;
    }
  }

  double _parsePercentage(String? value) {
    if (value == null) return 0.0;
    try {
      // Remove % sign and any other non-numeric characters except decimal point and minus
      final cleanValue = value.replaceAll(RegExp(r'[^\d.-]'), '');
      return double.parse(cleanValue);
    } catch (e) {
      print('Error parsing percentage: $value');
      return 0.0;
    }
  }

  void _handleError(String message, dynamic error) {
    debugPrint('$message: $error');
    setState(() {
      _errorMessage = '$message: $error';
      _isProcessing = false;
    });
  }

  void _showSuccessMessage(PointsResult pointsResult) {
    if (pointsResult.points <= 0) return; // Don't show message for 0 points

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🎉 You earned ${pointsResult.points.toStringAsFixed(0)} green points!',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (pointsResult.breakdown.isNotEmpty)
              Text(
                pointsResult.breakdown,
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildAnalysisDisplay() {
    if (_analysis == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bill Analysis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            _buildAnalysisRow('Energy Usage', '${_analysis!['usage']} kWh'),
            _buildAnalysisRow('Bill Amount', '\$${_analysis!['amount']}'),
            _buildAnalysisRow(
              'vs Last Month',
              '${_analysis!['comparison']}',
              textColor: _analysis!['comparison'].toString().contains('-') 
                  ? Colors.green 
                  : Colors.red,
            ),
            if (_analysis!['renewable'] != null)
              _buildAnalysisRow(
                'Renewable Energy',
                '${_analysis!['renewable']}',
                textColor: Colors.green,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisRow(String label, String value, {Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontWeight: textColor != null ? FontWeight.bold : null,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isGridReturn ? 'Upload Grid Return Bill' : 'Upload Energy Bill'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelpDialog(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildUploadCard(),
            if (_errorMessage != null) _buildErrorCard(),
            if (_isProcessing) _buildLoadingIndicator(),
            if (_image != null) _buildImagePreview(),
            if (_analysis != null) _buildAnalysisDisplay(),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              widget.isGridReturn ? Icons.upload_file : Icons.receipt_long,
              size: 48,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              widget.isGridReturn
                  ? 'Upload your grid return bill to earn extra points!'
                  : 'Upload your energy bill to track usage and earn points!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Take Photo'),
                  onPressed: _isProcessing ? null : () => _pickImage(ImageSource.camera),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Choose File'),
                  onPressed: _isProcessing ? null : () => _pickImage(ImageSource.gallery),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      margin: const EdgeInsets.only(top: 16),
      color: Colors.red[100],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[900]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red[900]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: const Center(
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Processing your bill...'),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Bill Image',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            child: Image.file(_image!),
          ),
        ],
      ),
    );
  }

  Future<void> _showHelpDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to Upload'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('For best results:'),
              const SizedBox(height: 8),
              _buildHelpItem('Ensure good lighting'),
              _buildHelpItem('Keep the bill flat'),
              _buildHelpItem('Include the entire bill in the frame'),
              _buildHelpItem('Make sure text is clearly visible'),
              const SizedBox(height: 16),
              Text(
                'Note: Processing may take a few moments.',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}