import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/auth_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';

class ContractScreen extends StatefulWidget {
  const ContractScreen({super.key});

  @override
  State<ContractScreen> createState() => _ContractScreenState();
}

class _ContractScreenState extends State<ContractScreen> {
  bool? _isSupplying;
  final _energyController = TextEditingController();
  final _priceController = TextEditingController();
  bool _isLoading = false;
  final _firestore = FirebaseFirestore.instance;

  final String _pinataJWT =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySW5mb3JtYXRpb24iOnsiaWQiOiI4ODNiZDEyZC02NTQ0LTQ1NWQtYTc1ZS0zNTg5YzAwNGI1MjkiLCJlbWFpbCI6InBlc3dhbmlzYWFjaGlAZ21haWwuY29tIiwiZW1haWxfdmVyaWZpZWQiOnRydWUsInBpbl9wb2xpY3kiOnsicmVnaW9ucyI6W3siZGVzaXJlZFJlcGxpY2F0aW9uQ291bnQiOjEsImlkIjoiRlJBMSJ9LHsiZGVzaXJlZFJlcGxpY2F0aW9uQ291bnQiOjEsImlkIjoiTllDMSJ9XSwidmVyc2lvbiI6MX0sIm1mYV9lbmFibGVkIjpmYWxzZSwic3RhdHVzIjoiQUNUSVZFIn0sImF1dGhlbnRpY2F0aW9uVHlwZSI6InNjb3BlZEtleSIsInNjb3BlZEtleUtleSI6Ijk2ZDgzODYyN2U5ZTA2MWFjMTFhIiwic2NvcGVkS2V5U2VjcmV0IjoiNzdlNGFhNGUxMDAxMTA1ZDJkNzNjM2M5YTAwZmIzZTg4MzY0ZDg5MTZlMGVjY2JhYWU5MTdjOGQzNmJiMjEzMSIsImV4cCI6MTc2NzI3NTg2Mn0.qhrhcmQLzq6zDD7wSuU5EcZ7lBRD1-maktkFB57f288';

  @override
  void dispose() {
    _energyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<String> _uploadToPinata(List<int> fileBytes) async {
    try {
      final uri = Uri.parse('https://api.pinata.cloud/pinning/pinFileToIPFS');
      final request = http.MultipartRequest('POST', uri)
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            fileBytes,
            filename: 'contract.pdf',
          ),
        )
        ..headers.addAll({
          'Authorization': 'Bearer $_pinataJWT',
        });

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final json = jsonDecode(response.body);

      return json['IpfsHash'] as String;
    } catch (e) {
      debugPrint('Error uploading to IPFS: $e');
      rethrow;
    }
  }

  Future<void> _handleEnergyTransaction() async {
    if (_energyController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter both energy amount and price')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final energy = double.parse(_energyController.text);
      final price = double.parse(_priceController.text);
      if (_isSupplying!) {
        await _handleEnergySupply(energy, price);
      } else {
        await _handleEnergyRequest(energy, price);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleEnergySupply(double energy, double price) async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    try {
      // Add to sellers collection with new name
      await _firestore.collection('UserSellers').add({
        'propertyId': user.propertyID,
        'energy': energy,
        'price': price,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Find matching buyers with similar requirements
      final buyers = await _firestore
          .collection('UserBuyers')
          .where('energy', isLessThanOrEqualTo: energy)
          .where('propertyId', isNotEqualTo: user.propertyID) // Add this line
          .orderBy('propertyId') // Add this line
          .orderBy('energy', descending: true)
          .orderBy('price', descending: true)
          .limit(5)
          .get();

      if (buyers.docs.isNotEmpty) {
        // Show list of potential buyers
        if (!mounted) return;
        final selectedBuyer = await _showPotentialMatchesDialog(
          buyers.docs,
          isSeller: true,
          requestedPrice: price,
        );

        if (selectedBuyer != null) {
          final contract = await _generateContract(
            energy,
            price,
            user.propertyID,
            selectedBuyer['propertyId'],
          );

          // Remove matched buyer and seller
          await _firestore
              .collection('UserBuyers')
              .doc(selectedBuyer['docId'])
              .delete();
          await _firestore
              .collection('UserSellers')
              .where('propertyId', isEqualTo: user.propertyID)
              .get()
              .then((sellers) {
            for (var doc in sellers.docs) {
              doc.reference.delete();
            }
          });

          // Update green points and contract history
          await context
              .read<UserProvider>()
              .updateGreenPoints((energy * 10).round());
          await context
              .read<UserProvider>()
              .addContractToHistory(contract['ipfsCid']);

          if (!mounted) return;
          await _showEnhancedContractDialog(contract);
        }
      } else {
        if (!mounted) return;
        await _showNoMatchDialog(true);
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error in handleEnergySupply: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }

  Future<void> _handleEnergyRequest(double energy, double price) async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    try {
      // Add to buyers collection with new name
      await _firestore.collection('UserBuyers').add({
        'propertyId': user.propertyID,
        'energy': energy,
        'price': price,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Find matching sellers with similar requirements
      final sellers = await _firestore
          .collection('UserSellers')
          .where('energy', isGreaterThanOrEqualTo: energy)
          .where('propertyId', isNotEqualTo: user.propertyID) // Add this line
          .orderBy('propertyId') // Add this line
          .orderBy('energy')
          .orderBy('price')
          .limit(5)
          .get();

      if (sellers.docs.isNotEmpty) {
        if (!mounted) return;
        final selectedSeller = await _showPotentialMatchesDialog(
          sellers.docs,
          isSeller: false,
          requestedPrice: price,
        );

        if (selectedSeller != null) {
          final contract = await _generateContract(
            energy,
            selectedSeller['price'],
            selectedSeller['propertyId'],
            user.propertyID,
          );

          // Remove matched buyer and seller
          await _firestore
              .collection('UserSellers')
              .doc(selectedSeller['docId'])
              .delete();
          await _firestore
              .collection('UserBuyers')
              .where('propertyId', isEqualTo: user.propertyID)
              .get()
              .then((buyers) {
            for (var doc in buyers.docs) {
              doc.reference.delete();
            }
          });

          if (!mounted) return;
          await _showEnhancedContractDialog(contract);
        }
      } else {
        if (!mounted) return;
        await _showNoMatchDialog(false);
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error in handleEnergyRequest: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }

  Future<Map<String, dynamic>?> _showPotentialMatchesDialog(
      List<QueryDocumentSnapshot> matches,
      {required bool isSeller,
      required double requestedPrice}) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isSeller ? 'Potential Buyers' : 'Potential Sellers',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index].data() as Map<String, dynamic>;
              final priceDiff =
                  ((match['price'] - requestedPrice) / requestedPrice * 100)
                      .abs();

              return Card(
                child: ListTile(
                  title: Text(
                    'Property ID: ${match['propertyId']}',
                    style: GoogleFonts.poppins(),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Energy: ${match['energy']} kW',
                        style: GoogleFonts.poppins(),
                      ),
                      Text(
                        'Price: ₹${match['price']}/kW (${priceDiff.toStringAsFixed(1)}% ${match['price'] > requestedPrice ? 'higher' : 'lower'})',
                        style: GoogleFonts.poppins(),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.of(context).pop({
                      ...match,
                      'docId': matches[index].id,
                    });
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showNoMatchDialog(bool isSeller) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'No Matches Found',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notification_important,
              size: 48,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(
              isSeller
                  ? 'No matching buyers found at the moment. We\'ll notify you when a suitable buyer is available.'
                  : 'No matching sellers found at the moment. We\'ll notify you when a suitable seller is available.',
              style: GoogleFonts.poppins(
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(),
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _generateContract(
    double energy,
    double price,
    String sellerPropertyId,
    String buyerPropertyId,
  ) async {
    final contract = {
      'sellerPropertyId': sellerPropertyId,
      'buyerPropertyId': buyerPropertyId,
      'energy': energy,
      'pricePerUnit': price,
      'totalPrice': energy * price,
      'date': DateTime.now().toIso8601String(),
    };

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Energy Trading Contract',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Contract Details:',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text('Seller Property ID: ${contract['sellerPropertyId']}'),
              pw.Text('Buyer Property ID: ${contract['buyerPropertyId']}'),
              pw.Text('Energy Amount: ${contract['energy']} kW'),
              pw.Text('Price per kW: ₹${contract['pricePerUnit']}'),
              pw.Text('Total Price: ₹${contract['totalPrice']}'),
              pw.Text('Date: ${contract['date']}'),
              pw.SizedBox(height: 40),
              pw.Text('Terms and Conditions:',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text(
                '1. Smart Meter Integration:\n'
                '   • This contract will automatically trigger the smart meters at both properties.\n'
                '   • Energy transfer will be initiated through the grid system upon contract activation.\n\n'
                '2. Transfer Schedule:\n'
                '   • Energy transfer will begin within 1 hour of contract confirmation.\n'
                '   • The specified amount will be transferred continuously until completion.\n\n'
                '3. Grid Operations:\n'
                '   • The energy will be routed through the existing power grid infrastructure.\n'
                '   • Both parties must maintain their grid connection during the transfer period.\n\n'
                '4. Quality Assurance:\n'
                '   • The smart meter system will ensure the agreed amount is accurately transferred.\n'
                '   • Real-time monitoring will be available through the platform dashboard.\n\n'
                '5. Payment Terms:\n'
                '   • Payment will be processed automatically through the platform\'s secure system.\n'
                '   • Transaction confirmation will be provided upon successful transfer.\n\n'
                '6. Technical Support:\n'
                '   • 24/7 support is available for any technical issues during the transfer.\n'
                '   • Emergency protocols are in place for any grid-related interruptions.',
              ),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/contract.pdf');
    final bytes = await pdf.save();
    await file.writeAsBytes(bytes);

    final ipfsCid = await _uploadToPinata(bytes);
    contract['ipfsCid'] = ipfsCid;

    return contract;
  }

  Future<void> _showEnhancedContractDialog(Map<String, dynamic> contract) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        'Contract Generated!',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildContractField(
                            'IPFS CID',
                            contract['ipfsCid'],
                            showCopy: true,
                          ),
                          _buildContractField(
                            'Contract Link',
                            'https://w3s.link/ipfs/${contract['ipfsCid']}',
                            showCopy: true,
                          ),
                          _buildContractField(
                            'Seller Property ID',
                            contract['sellerPropertyId'],
                          ),
                          _buildContractField(
                            'Buyer Property ID',
                            contract['buyerPropertyId'],
                          ),
                          _buildContractField(
                            'Energy Amount',
                            '${contract['energy']} kW',
                          ),
                          _buildContractField(
                            'Price per kW',
                            '₹${contract['pricePerUnit']}',
                          ),
                          _buildContractField(
                            'Total Price',
                            '₹${contract['totalPrice']}',
                          ),
                          _buildContractField(
                            'Date',
                            DateTime.parse(contract['date']).toString(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.download),
                        label: Text(
                          'Download Contract',
                          style: GoogleFonts.poppins(),
                        ),
                        onPressed: () async {
                          final tempDir = await getTemporaryDirectory();
                          final file = File('${tempDir.path}/contract.pdf');
                          if (await file.exists()) {
                            await OpenFile.open(file.path);
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          'Close',
                          style: GoogleFonts.poppins(),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContractField(String label, String value,
      {bool showCopy = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              if (showCopy) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: value)).then((_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Copied to clipboard',
                            style: GoogleFonts.poppins(),
                          ),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    });
                  },
                  tooltip: 'Copy to clipboard',
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Energy Contract'),
        backgroundColor: Colors.green.shade500,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green[50]!,
              Colors.blue[50]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isSupplying == null) ...[
                  _buildChoiceCard(
                    icon: Icons.upload,
                    title: 'Supply Energy',
                    description: 'I want to supply excess energy',
                    onTap: () => setState(() => _isSupplying = true),
                  ),
                  const SizedBox(height: 20),
                  _buildChoiceCard(
                    icon: Icons.download,
                    title: 'Need Energy',
                    description: 'I want to purchase energy',
                    onTap: () => setState(() => _isSupplying = false),
                  ),
                ] else ...[
                  Text(
                    _isSupplying! ? 'Supply Energy' : 'Request Energy',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isSupplying!
                        ? 'Share your excess energy and earn rewards'
                        : 'Request clean energy for your needs',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white,
                            Colors.green[50]!,
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          TextField(
                            controller: _energyController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Energy Amount (kW)',
                              labelStyle: GoogleFonts.poppins(),
                              prefixIcon:
                                  Icon(Icons.bolt, color: Colors.green[700]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.green.shade500),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Price per kW (INR)',
                              labelStyle: GoogleFonts.poppins(),
                              prefixIcon: Icon(Icons.currency_rupee,
                                  color: Colors.green[700]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.green.shade500),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed:
                                  _isLoading ? null : _handleEnergyTransaction,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade500,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : Text(
                                      'Continue',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () => setState(() => _isSupplying = null),
                    icon: const Icon(Icons.arrow_back),
                    label: Text(
                      'Go Back',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.green[50]!,
              ],
            ),
          ),
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 36,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}