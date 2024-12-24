import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Function to fetch doctor's info from Firebase
  Future<DocumentSnapshot> _getDoctorInfo() async {
    final userId = _auth.currentUser!.uid;
    return await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
  }

  // Function to sign out
  Future<void> _signOut(BuildContext context) async {
    try {
      await _auth.signOut();
      Navigator.popUntil(context, (route) => false);
      Navigator.pushNamed(context, '/'); // Navigate to the login screen
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  // Function to delete account
  Future<void> _deleteAccount(BuildContext context) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final userId = user.uid;

        // Show confirmation dialog
        bool? isConfirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Delete Account'),
            content: Text(
                'Are you sure you want to delete your account? This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Delete'),
              ),
            ],
          ),
        );

        if (isConfirmed == true) {
          try {
            await FirebaseFirestore.instance
                .collection('doctors')
                .doc(userId)
                .delete();
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .delete();
            await user.delete();
            Navigator.popUntil(context, (route) => false);
            Navigator.pushNamed(context, '/');
          } catch (error) {
            print("Account deletion failed: $error");
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to delete account')),
            );
          }
        }
      } catch (e) {
        print('Error deleting account: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete account: $e')),
        );
      }
    }
  }

  // Function to reset password
  Future<void> _resetPassword(BuildContext context) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _auth.sendPasswordResetEmail(email: user.email!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password reset email sent to ${user.email}')),
        );
      } catch (e) {
        print('Error sending password reset email: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send password reset email: $e')),
        );
      }
    }
  }

  // Function to show logout confirmation dialog
  Future<void> _showLogoutConfirmation(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Are you sure?',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 60, 145, 230),
          ),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: Colors.black,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'No',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _signOut(context);
            },
            child: Text(
              'Yes',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper function to check if user signed in with Google
  bool _isGoogleUser() {
    final user = _auth.currentUser;
    if (user != null) {
      // Check if the user's providers list contains Google
      return user.providerData
          .any((userInfo) => userInfo.providerId == 'google.com');
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50), // Reduce height of AppBar
        child: AppBar(
          iconTheme: IconThemeData(
            color: Colors.white,
          ),
          title: Text(
            'Settings',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Color.fromARGB(255, 60, 145, 230), // Blue color
        ),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height, // Full screen height
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          image: DecorationImage(
            image:
                AssetImage('assets/images/background.png'), // Background image
            fit: BoxFit.cover,
          ),
        ),
        padding: const EdgeInsets.all(20.0),
        child: FutureBuilder<DocumentSnapshot>(
          future: _getDoctorInfo(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(child: Text("No doctor data found."));
            }

            var doctorData = snapshot.data!.data() as Map<String, dynamic>;

            String doctorName = doctorData['name'] ?? 'N/A';
            String doctorSurname = doctorData['surname'] ?? 'N/A';
            String doctorEmail = doctorData['email'] ?? 'N/A';
            String doctorBirthDate = doctorData['birthDate'] ?? 'N/A';

            return SingleChildScrollView(
              child: Column(
                children: [
                  Card(
                    color: Colors.white.withOpacity(0.8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Information',
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 60, 145, 230),
                            ),
                          ),
                          Divider(
                            color: Colors.grey[400],
                            thickness: 1.0,
                            height: 20,
                          ),
                          SizedBox(height: 10),
                          _buildInfoRow('Name:', doctorName),
                          SizedBox(height: 10),
                          _buildInfoRow('Surname:', doctorSurname),
                          SizedBox(height: 10),
                          _buildInfoRow('Email:', doctorEmail),
                          SizedBox(height: 10),
                          _buildInfoRow('Birth Date:', doctorBirthDate),
                          SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _deleteAccount(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    ),
                    child: Text(
                      'Delete Account',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  // Only show reset password button for non-Google users
                  if (!_isGoogleUser())
                    ElevatedButton(
                      onPressed: () => _resetPassword(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      ),
                      child: Text(
                        'Reset Password',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: SizedBox(
        height: 80, // Increase button size
        width: 80, // Increase button size
        child: FloatingActionButton(
          onPressed: () => _showLogoutConfirmation(context),
          backgroundColor: Colors.red, // Change color to red
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40), // Make it circular
          ),
          child: Icon(Icons.exit_to_app, color: Colors.white, size: 30),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color:
            Color.fromARGB(255, 60, 145, 230), // Blue color for the bottom bar
        shape: CircularNotchedRectangle(),
        notchMargin: 8.0, // Notch margin for better visibility
        child: SizedBox(height: 10), // Adjust height to match button spacing
      ),
    );
  }

  // Helper widget to style each information row
  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style:
                GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w400),
          ),
        ),
      ],
    );
  }
}
