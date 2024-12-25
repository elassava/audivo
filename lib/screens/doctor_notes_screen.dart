import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotesScreen extends StatefulWidget {
  @override
  _NotesScreenState createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final TextEditingController _noteController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notlarım'),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddNoteDialog(context),
        child: Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('doctor_notes')
            .where('doctorId', isEqualTo: user?.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Bir hata oluştu'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.data?.docs.isEmpty ?? true) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.note_alt_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Henüz not eklenmemiş'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(8),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final note = snapshot.data!.docs[index];
              return Card(
                elevation: 2,
                margin: EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text(note['content']),
                  subtitle: Text(
                    _formatDate(note['timestamp'].toDate()),
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showEditNoteDialog(context, note),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _showDeleteConfirmation(context, note.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }

  Future<void> _showAddNoteDialog(BuildContext context) async {
    _noteController.clear();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Yeni Not'),
        content: TextField(
          controller: _noteController,
          decoration: InputDecoration(hintText: 'Notunuzu yazın...'),
          maxLines: 5,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_noteController.text.isNotEmpty) {
                _addNote();
                Navigator.pop(context);
              }
            },
            child: Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditNoteDialog(
      BuildContext context, DocumentSnapshot note) async {
    _noteController.text = note['content'];
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Notu Düzenle'),
        content: TextField(
          controller: _noteController,
          decoration: InputDecoration(hintText: 'Notunuzu yazın...'),
          maxLines: 5,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_noteController.text.isNotEmpty) {
                _updateNote(note.id);
                Navigator.pop(context);
              }
            },
            child: Text('Güncelle'),
          ),
        ],
      ),
    );
  }

  Future<void> _addNote() async {
    try {
      await _firestore.collection('doctor_notes').add({
        'content': _noteController.text,
        'doctorId': user?.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Not eklenirken hata oluştu: $e');
    }
  }

  Future<void> _updateNote(String noteId) async {
    try {
      await _firestore.collection('doctor_notes').doc(noteId).update({
        'content': _noteController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Not güncellenirken hata oluştu: $e');
    }
  }

  Future<void> _deleteNote(String noteId) async {
    try {
      await _firestore.collection('doctor_notes').doc(noteId).delete();
    } catch (e) {
      print('Not silinirken hata oluştu: $e');
    }
  }

  Future<void> _showDeleteConfirmation(BuildContext context, String noteId) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Notu Sil'),
        content: Text('Bu notu silmek istediğinizden emin misiniz?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'İptal',
              style: TextStyle(
                color: Theme.of(context).primaryColor.withOpacity(0.7),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _deleteNote(noteId);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Sil'),
          ),
        ],
      ),
    );
  }
}
