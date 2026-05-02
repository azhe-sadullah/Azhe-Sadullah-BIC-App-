library;
import 'package:flutter/material.dart';
import 'package:bic/components/text_form_builder.dart';
import 'package:bic/utils/constants.dart';
import 'package:ionicons/ionicons.dart';

class EditProfileCustomer extends StatefulWidget {
  const EditProfileCustomer({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _EditProfileCustomerState createState() => _EditProfileCustomerState();
}

class _EditProfileCustomerState extends State<EditProfileCustomer> {
  final _formKey = GlobalKey<FormState>();
  // Controllers
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _billingController = TextEditingController();
  final TextEditingController _paymentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Edit Profile",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage("https://i.pravatar.cc/300?img=5"),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Constants.customerPrimary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.edit, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),
              
              _buildSectionTitle("Company Info"),
              SizedBox(height: 10),
              TextFormBuilder(
                controller: _companyController,
                hintText: "Company Name",
                prefix: Ionicons.business_outline,
                validateFunction: (val) => val!.isEmpty ? "Required" : null,
              ),
              SizedBox(height: 16),
              
              _buildSectionTitle("Contact Details"),
              SizedBox(height: 10),
              TextFormBuilder(
                controller: _emailController,
                hintText: "Email Address",
                prefix: Ionicons.mail_outline,
                textInputType: TextInputType.emailAddress,
                validateFunction: (val) => !val!.contains('@') ? "Invalid Email" : null,
              ),
              SizedBox(height: 10),
              TextFormBuilder(
                controller: _phoneController,
                hintText: "Phone Number",
                prefix: Ionicons.call_outline,
                textInputType: TextInputType.phone,
              ),
              SizedBox(height: 16),

              _buildSectionTitle("Billing & Payment"),
              SizedBox(height: 10),
               TextFormBuilder(
                controller: _billingController,
                hintText: "Billing Address",
                prefix: Ionicons.location_outline,
              ),
              SizedBox(height: 10),
              TextFormBuilder(
                controller: _paymentController,
                hintText: "Payment Method",
                prefix: Ionicons.card_outline,
              ),

              SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Save Logic
                       ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Profile Updated Successfully!"), backgroundColor: Constants.customerPrimary),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Constants.customerPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  child: Text("Save Changes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Constants.customerAccent,
      ),
    );
  }
}
