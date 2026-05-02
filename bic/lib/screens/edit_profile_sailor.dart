library;
import 'package:flutter/material.dart';
import 'package:bic/components/text_form_builder.dart';
import 'package:bic/utils/constants.dart';
import 'package:ionicons/ionicons.dart';

class EditProfileSailor extends StatefulWidget {
  const EditProfileSailor({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _EditProfileSailorState createState() => _EditProfileSailorState();
}

class _EditProfileSailorState extends State<EditProfileSailor> {
  final _formKey = GlobalKey<FormState>();
  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _certController = TextEditingController();
  bool _isAvailable = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.sailorBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Edit Sailor Profile",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Constants.sailorPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              SizedBox(height: 30),
              
              TextFormBuilder(
                controller: _nameController,
                hintText: "Full Name",
                prefix: Ionicons.person_outline,
                validateFunction: (val) => val!.isEmpty ? "Required" : null,
              ),
              SizedBox(height: 16),
              
              TextFormBuilder(
                controller: _phoneController,
                hintText: "Phone Number",
                prefix: Ionicons.call_outline,
                textInputType: TextInputType.phone,
              ),
              SizedBox(height: 16),

              TextFormBuilder(
                controller: _certController,
                hintText: "Certifications (comma separated)",
                prefix: Ionicons.ribbon_outline,
              ),
               SizedBox(height: 24),

               Container(
                 padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                 decoration: BoxDecoration(
                   color: Colors.white,
                   borderRadius: BorderRadius.circular(12),
                 ),
                 child: SwitchListTile(
                   title: Text("Availability Status", style: TextStyle(fontWeight: FontWeight.bold)),
                   subtitle: Text(_isAvailable ? "Available for tasks" : "Currently Unavailable"),
                   value: _isAvailable,
                   activeThumbColor: Constants.sailorPrimary,
                   onChanged: (val) {
                     setState(() {
                       _isAvailable = val;
                     });
                   },
                 ),
               ),

              SizedBox(height: 40),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text("Cancel", style: TextStyle(color: Colors.black)),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        // Save Logic
                         ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Profile Updated!"), backgroundColor: Constants.sailorPrimary),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Constants.sailorPrimary,
                      padding: EdgeInsets.symmetric(vertical: 16),
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text("Save Changes", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage("https://i.pravatar.cc/300?img=11"),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Constants.sailorPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            "Update your operational profile",
            style: TextStyle(color: Colors.grey[600]),
          )
        ],
      ),
    );
  }
}
