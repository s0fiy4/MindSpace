import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'myprofile.dart';

class EditProfilePage extends StatefulWidget {
  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final supabase = Supabase.instance.client; // Supabase client
  File? _image;
  String? _imageUrl;
  TextEditingController _firstNameController = TextEditingController();
  TextEditingController _lastNameController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();
  String email = ""; // Email (read-only)
  bool isLoading = true; // Loading indicator

  @override
  void initState() {
    super.initState();
    _fetchDataFromSupabase();
  }

  Future<void> _fetchDataFromSupabase() async {
    try {
      final user = supabase.auth.currentUser; // Get authenticated user
      if (user != null) {
        final response = await supabase
            .from('profiles')
            .select('first_name, last_name, phone, profile_image')
            .eq('id', user.id)
            .maybeSingle(); // Fetch user profile

        if (response != null) {
          setState(() {
            _firstNameController.text = response['first_name'] ?? "";
            _lastNameController.text = response['last_name'] ?? "";
            _phoneController.text = response['phone']?.replaceFirst("+60", "") ?? ""; // Remove +60 for editing
            email = user.email ?? ""; // Fetch email from auth
            _imageUrl = response['profile_image']; // Fetch profile image URL
          });
        }
      }
    } catch (error) {
      print("Error fetching profile: $error");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _updateProfile() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final phone = "+60${_phoneController.text.trim()}";

    if (firstName.isEmpty || lastName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("First Name and Last Name are required."),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      final user = supabase.auth.currentUser; // Get authenticated user
      if (user != null) {
        await supabase
            .from('profiles')
            .update({
              'first_name': firstName,
              'last_name': lastName,
              'phone': phone,
            })
            .eq('id', user.id); // Update profile

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile Updated Successfully'),
            duration: Duration(seconds: 2),
          ),
        );

        Future.delayed(Duration(seconds: 2), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MyProfilePage()),
          );
        });
      }
    } catch (error) {
      print("Error updating profile: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile. Please try again.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _uploadImage(File file) async {
    try {
      final user = supabase.auth.currentUser; // Get the current user
      if (user != null) {
        final fileName = 'profile_picture/${DateTime.now().millisecondsSinceEpoch}.png';
        final response = await supabase.storage.from('profile-images').upload(fileName, file);

        if (response.error == null) {
          final publicUrl = supabase.storage.from('profile-images').getPublicUrl(fileName);
          await _updateProfileImageUrl(publicUrl); // Update URL in the database
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Image uploaded successfully!')),
          );
        } else {
          throw Exception(response.error?.message ?? 'Unknown error during upload');
        }
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $error')),
      );
    }
  }

  Future<void> _updateProfileImageUrl(String url) async {
    try {
      final user = supabase.auth.currentUser; // Get the current user
      if (user != null) {
        final response = await supabase
            .from('profiles')
            .update({'profile_image': url})
            .eq('id', user.id);

        if (response.error != null) {
          throw Exception(response.error?.message ?? 'Unknown error updating profile image');
        }
      }
    } catch (error) {
      //ScaffoldMessenger.of(context).showSnackBar(
        //SnackBar(content: Text('Error updating profile image: $error')),
      //);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final status = await _checkPermission(source);
    if (status) {
      final pickedFile = await ImagePicker().pickImage(source: source);
      if (pickedFile != null) {
        final file = File(pickedFile.path);
        setState(() {
          _image = file;
        });
        _uploadImage(file); // Upload the image to Supabase
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Permission denied. Please allow access to continue.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<bool> _checkPermission(ImageSource source) async {
    if (source == ImageSource.camera) {
      var cameraPermission = await Permission.camera.request();
      return cameraPermission.isGranted;
    } else if (source == ImageSource.gallery) {
      if (Platform.isAndroid) {
        var mediaPermission = await Permission.photos.request();
        if (mediaPermission.isGranted) {
          return true;
        }
        var storagePermission = await Permission.storage.request();
        return storagePermission.isGranted;
      } else if (Platform.isIOS) {
        var photosPermission = await Permission.photos.request();
        return photosPermission.isGranted;
      }
    }
    return false;
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose Source',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String placeholder, {bool enabled = true}) {
    return TextField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        hintText: controller.text.isEmpty ? placeholder : null,
        labelText: label,
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade200,
        hintStyle: TextStyle(
          color: enabled ? Colors.black : Colors.grey,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: () {
                            _showImageSourceActionSheet(context);
                          },
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage: _image != null
                                ? FileImage(_image!)
                                : (_imageUrl != null
                                    ? NetworkImage(_imageUrl!)
                                    : const AssetImage('assets/profile.png'))
                                        as ImageProvider,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () {
                              _showImageSourceActionSheet(context);
                            },
                            child: CircleAvatar(
                              radius: 15,
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.camera_alt,
                                size: 16,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 45),
                    _buildTextField("First Name", _firstNameController, "First Name"),
                    const SizedBox(height: 25),
                    _buildTextField("Last Name", _lastNameController, "Last Name"),
                    const SizedBox(height: 25),
                    _buildTextField("Email", TextEditingController(text: email), "", enabled: false),
                    const SizedBox(height: 25),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey),
                          ),
                          child: const Text(
                            "+60",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildTextField("Phone Number", _phoneController, "Phone Number"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 50),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
      backgroundColor: Colors.white,
    );
  }
}

extension on String {
  get error => null;
}
