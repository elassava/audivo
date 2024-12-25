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
        .collection('doctors')
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Column(
              children: [
                Icon(
                  Icons.warning_rounded,
                  color: Colors.red[400],
                  size: 64,
                ),
                SizedBox(height: 16),
                Text(
                  'Delete Account',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[400],
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'You are about to delete your account',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'This action cannot be undone and all your data will be permanently deleted.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
              ],
            ),
            actionsPadding: EdgeInsets.all(16),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[400],
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Delete Account',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );

        if (isConfirmed == true) {
          // First try to delete the authentication account
          await user.delete();
          
          // Only if authentication deletion succeeds, delete from Firestore
          await FirebaseFirestore.instance
              .collection('doctors')
              .doc(userId)
              .delete();
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .delete();
          
          Navigator.popUntil(context, (route) => false);
          Navigator.pushNamed(context, '/');
        }
      } catch (error) {
        print("Account deletion failed: $error");
        // Show dialog for any deletion error
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Account Deletion Failed'),
            content: Text('For security reasons, you need to sign out and sign in again before deleting your account. Would you like to sign out now?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _signOut(context);
                },
                child: Text('Sign Out'),
              ),
            ],
          ),
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
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color.fromARGB(255, 60, 145, 230),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'), // Kendi image path'inizi kullanın
            fit: BoxFit.cover,
          ),
        ),
        child: FutureBuilder<DocumentSnapshot>(
          future: _getDoctorInfo(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(child: Text("No doctor data found."));
            }

            var doctorData = snapshot.data!.data() as Map<String, dynamic>;
            String doctorName = doctorData['name'] ?? 'N/A';
            String doctorSurname = doctorData['surname'] ?? 'N/A';

            return SafeArea(
              
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with profile photo and name
                    Container(
                      
                      padding: EdgeInsets.all(20),
                      margin: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        
                        color: Color.fromARGB(255, 60, 145, 230), // Orange color like in the image
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white,
                            backgroundImage: doctorData['profileImg'] != null
                                ? NetworkImage(doctorData['profileImg'])
                                : null,
                            child: doctorData['profileImg'] == null
                                ? Icon(Icons.person, size: 30, color: Colors.grey)
                                : null,
                          ),
                          SizedBox(width: 16),
                          Text(
                            '$doctorName $doctorSurname',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Personal Information Section
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoSection(
                            'Name',
                            doctorName,
                            Icons.person,
                            Colors.blue,
                          ),
                          _buildInfoSection(
                            'Surname',
                            doctorSurname,
                            Icons.person_outline,
                            Colors.green,
                          ),
                          _buildInfoSection(
                            'Email',
                            doctorData['email'] ?? 'N/A',
                            Icons.email,
                            Colors.orange,
                          ),
                          _buildInfoSection(
                            'Date of Birth',
                            doctorData['birthDate'] ?? 'N/A',
                            Icons.cake,
                            Colors.purple,
                          ),
                          SizedBox(height: 24),
                          
                          // Account Section
                          Text(
                            'Account',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 12),
                          
                          // Account Actions
                          if (!_isGoogleUser())
                            _buildActionButton(
                              'Change Password',
                              Icons.lock_outline,
                              Colors.blue,
                              () => _resetPassword(context),
                            ),
                          _buildActionButton(
                            'Delete Account',
                            Icons.delete_outline,
                            Colors.red,
                            () => _deleteAccount(context),
                          ),
                          _buildActionButton(
                            'Sign Out',
                            Icons.logout,
                            Colors.grey,
                            () => _showLogoutConfirmation(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoSection(String label, String value, IconData icon, Color color) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color),
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            SizedBox(width: 16),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Spacer(),
            Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
