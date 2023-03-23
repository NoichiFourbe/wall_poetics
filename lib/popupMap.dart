import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_storage/firebase_storage.dart';

class popupMap extends StatefulWidget {
  const popupMap({Key? key}) : super(key: key);
  @override
  State<popupMap> createState() => _popupMapState();
}

class _popupMapState extends State<popupMap> {
  late Position _currentPosition = Position(latitude: 48.858370, longitude: 2.294481, timestamp: null, accuracy: 0.0, altitude: 0.0, heading: 0.0, speed: 0.0, speedAccuracy: 0.0);

  List<DocumentSnapshot> documents = [];
  List<LatLng> coordinates = [];
  List<bool> me = [];
  List<Marker> markers = [];
  final List<String> _keywords = [
    'Artiste Indépendant',
    'Space Invader',
    'Graffiti',
    'Pastel',
    'Pochoir',
    'Fresque'
  ];
  List<String> _selectedKeywords = [];

  @override
  void initState() {
    super.initState();
    loadDocuments();
  }

  void loadDocuments() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('spot').get();
    setState(() {
      documents = snapshot.docs;
      for(var document in documents){
        LatLng l = LatLng(document['latitude'], document['longitude']);
        if(FirebaseAuth.instance.currentUser?.uid==document['userid'])
        {
          me.add(true);
        }
        else
        {
          me.add(false);
        }
        coordinates.add(l);
      }

      markers=coordinates
          .asMap()
          .map((index, point) => MapEntry(index, Marker(
        point: point,
        width: 60,
        height: 60,
        builder: (context) => GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              builder: (context) => Popup(
                document: documents[index],
              ),
            );
          },
          child: Icon(
            Icons.location_pin,
            size: 60,
            color: me[index]==true?const Color(0xFF885F06):const Color(0xFFE19F0C),
          ),
        ),
      )))
          .values
          .toList();
    });
  }
  void _filterMarkers() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('spot').get();

    setState(()  {
      // Filter documents based on keyword search
      documents = snapshot.docs.where((doc) => (doc['mot-cles'] as List<dynamic>).any((keyword) => _selectedKeywords.contains(keyword))).toList();
      coordinates = documents.map((doc) => LatLng(doc['latitude'], doc['longitude'])).toList();
      me = documents.map((doc) => FirebaseAuth.instance.currentUser?.uid == doc['userid']).toList();

      // Update markers based on filtered documents
      markers = coordinates
          .asMap()
          .map((index, point) => MapEntry(index, Marker(
        point: point,
        width: 60,
        height: 60,
        builder: (context) => GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              builder: (context) => Popup(
                document: documents[index],
              ),
            );
          },
          child: Icon(
            Icons.location_pin,
            size: 60,
            color: me[index] == true ? const Color(0xFF885F06) : const Color(0xFFE19F0C),
          ),
        ),
      )))
          .values
          .toList();
    });
  }
  MapController mapController = MapController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:Column(
          children: [
      Padding(
      padding: const EdgeInsets.all(8.0),
      child: InputDecorator(
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Mots-clés',
        ),
        child: Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: _keywords.map((String keyword) {
            return ChoiceChip(
              label: Text(keyword),
              selected: _selectedKeywords.contains(keyword),
              onSelected: (bool selected) {
                setState(() {
                  if (selected) {
                    _selectedKeywords.add(keyword);
                  } else {
                    _selectedKeywords.remove(keyword);
                  }
                });
              },
            );
          }).toList(),
        ),
      ),
    ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedKeywords=[];
                      loadDocuments();
                    });
                  },
                  child: Text('Annuler la recherche'),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Color(0xFFB71118)),
                  ),
                ),
                SizedBox(width: 10.0),
                ElevatedButton(
                  onPressed: () {
                    if(_selectedKeywords.isNotEmpty) {
                      _filterMarkers();
                    }
                  },
                  child: Text('Rechercher'),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Color(0xFFE19F0C)),
                  ),
                ),
              ],

            ),

      Expanded(
        child: FlutterMap(
          options: MapOptions(
            center: LatLng(_currentPosition.latitude, _currentPosition.longitude),
            zoom:17,

          ),
          mapController: mapController,
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.app',
            ),
            MarkerLayer(markers: markers),
          ],


        ),
      ),
    ],
      ),
    );
  }
}

class Popup extends StatefulWidget {
  final DocumentSnapshot document;

  Popup({Key? key, required this.document});

  @override
  State<Popup> createState() => _PopupState();
}

class _PopupState extends State<Popup> {
  List<String> _pictures = [];
  String imageUrl="";
  FirebaseStorage storage = FirebaseStorage.instance;

  List<File> _images = [];

  Future uploadPic(BuildContext context) async{
    for(File _image in _images) {
      String fileName = basename(_image.path);

      String res = FirebaseAuth.instance.currentUser!.uid.toString() + "/" + fileName;
      _pictures.add(res);
      Reference reference = storage.ref().child(res);
      UploadTask uploadTask = reference.putFile(_image);
      TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);
      imageUrl = await reference.getDownloadURL();

      setState(() {
         print("picture uploaded");
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedImages = await ImagePicker().pickMultiImage();
    if (pickedImages != null) {
      setState(() {
        _images.addAll(pickedImages.map((pickedImage) => File(pickedImage.path)).toList());
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  void _onReportPressed(BuildContext context) {
    _showReportDialog(context);
  }

  void _showReportDialog(BuildContext context) async {
    String? subject;
    String? description;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Report'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Sujet',
                ),
                onChanged: (String? value) {
                  subject = value;
                },
                items: const [
                  DropdownMenuItem<String>(
                    value: 'spam',
                    child: Text('Ce spot n\'existe pas/plus'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'inappropriate',
                    child: Text('Photo inappropriée'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'other',
                    child: Text('Autre'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Description',
                ),
                onChanged: (String value) {
                  description = value;
                },
                maxLines: 5,
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return 'Décrivez le problème rencontré avec le spot';
                  }
                  return null;
                },
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                FirebaseFirestore.instance
                    .collection('signalement')
                    .add({
                  "userid": FirebaseAuth.instance.currentUser?.uid.toString(),
                  "sujet" : subject,
                  "description" : description,
                  "standSignale" : widget.document.id
                });

                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Signalement envoyé')),
                );
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(const Color(
                    0xFFB71118)),
              ),
              child: const Text('Soumettre'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> pictures = widget.document["pictures"];
    bool _isLoggedIn=false;
    final User? user = FirebaseAuth.instance.currentUser;
    _isLoggedIn= user ==null ? false : true;
    return Container(
      height: 250,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(widget.document['description'].toString()),
          Text(widget.document['mot-cles'].toString()),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: pictures.length,
              itemBuilder: (BuildContext context, int index) {
                String doc = pictures[index];
                return FutureBuilder(
                  future: storage.ref().child(doc).getDownloadURL(),
                  builder: (context, AsyncSnapshot<dynamic> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    if (kDebugMode) {
                      print(snapshot.data.toString());
                    }
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.network(snapshot.data.toString(),
                          height: 100, width: 100),
                    );
                  },
                );
              },
            ),
          ),
          Visibility(
            visible: _isLoggedIn,
            child:  ElevatedButton(
              onPressed: () {
                showModalBottomSheet(
                context: context,
                builder: (BuildContext context) {
                  return SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        ListTile(
                          leading: const Icon(Icons.camera_alt),
                          title: const Text('Prendre une photo'),
                          onTap: () {
                            Navigator.pop(context);
                            _pickImage(ImageSource.camera);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.image),
                          title: const Text('Choisir une image depuis la galerie'),
                          onTap: () {
                            Navigator.pop(context);
                            _pickImage(ImageSource.gallery);
                          },
                        ),
                      ],
                    ),
                  );
                }
                 );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.add),
                  SizedBox(width: 8),
                  Text('Ajouter des photos au spot'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          ElevatedButton(
            onPressed: () => _onReportPressed(context),
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(const Color(0xFFE19F0C)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.flag_outlined),
                SizedBox(width: 8),
                Text('Signaler ce spot'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}




