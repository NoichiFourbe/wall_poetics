import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:open_street_map_search_and_pick/open_street_map_search_and_pick.dart';
import 'package:geolocator/geolocator.dart';



class Profil extends StatefulWidget {
  const Profil({Key? key}) : super(key: key);
  @override
  State<Profil> createState() => _ProfilState();
}

class _ProfilState extends State<Profil> {
  late Position _currentPosition = Position(latitude: 48.858370, longitude: 2.294481, timestamp: null, accuracy: 0.0, altitude: 0.0, heading: 0.0, speed: 0.0, speedAccuracy: 0.0);

  bool _isLoggedIn = false;
  double pickedLongitude=0.1;
  double pickedLatitude=0.1;
  late DocumentSnapshot document;
  FirebaseStorage storage = FirebaseStorage.instance;

  void _showEditForm(BuildContext context, String id) async {
    String? description;
    String locationaddress='Replacer le spot';
    final List<String> _keywords = [
      'Artiste Indépendant',
      'Space Invader',
      'Graffiti',
      'Pastel',
      'Pochoir',
      'Fresque'
    ];
    List<String> _selectedKeywords = [];

    // retrieve the document from Firebase
    DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('spot').doc(id).get();
    Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;
    String defaultDescription = data?['description'] ?? 'Default Description';
    _selectedKeywords=List<String>.from(data?['mot-cles']);

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Modifier un stand'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InputDecorator(
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
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Description',
                ),
                initialValue: defaultDescription,
                onChanged: (String value) {
                  description = value;
                },
                maxLines: 5,
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return 'Insérez une nouvelle description';
                  }
                  return null;
                },
              ),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SafeArea(
                      child: Container(
                        child: ElevatedButton(
                            child: Text(locationaddress),
                            onPressed: (){
                              _showModal(context);
                            }),
                      ),
                    ),
                  ],
                ),
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
                //edit the stand
                if (pickedLongitude==0.1) {
                  FirebaseFirestore.instance.collection('spot').doc(id).update(
                      {
                        'description': description,
                        'mot-cles': _selectedKeywords
                      });
                } else {
                  FirebaseFirestore.instance.collection('spot').doc(id).update(
                      {
                        'description': description,
                        'mot-cles': _selectedKeywords,
                        'longitude': pickedLongitude,
                        'latitude' : pickedLatitude
                      });
                }
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('spot modifié')),
                );
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(const Color(
                    0xFFB71118)),
              ),
              child: const Text('Sauvegarder les modifications'),
            ),
          ],
        );
      },
    );
  }
  void _showModal(BuildContext context){
    showModalBottomSheet(
        context: context,
        builder: (context){
          return Container(
            height: 600,
            //color: Colors.red,
            child: Center(
              child: OpenStreetMapSearchAndPick(
                //center: LatLong(50.6371, 3.0530),
                  center: LatLong(_currentPosition.latitude, _currentPosition.longitude),
                  buttonColor: Colors.blue,
                  buttonText: 'Set Current Location',
                  onPicked: (pickedData) {
                    ShowDialog(context,pickedData);
                  }),
            ),
          );
        });
  }
  void ShowDialog(BuildContext context,PickedData pickedData)
  {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirmation"),
          content: Text("Confimez-vous la position choisie ? (${pickedData.address})"),
          actions: [
            TextButton(
              child: const Text("Annuler"),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: const Text("Oui"),
              onPressed: () {
                pickedLatitude=pickedData.latLong.latitude;
                pickedLongitude=pickedData.latLong.longitude;
                Navigator.pop(context);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Votre spot est désormais placé à l'adresse: "+ pickedData.address)),
                );
              },
            ),
          ],
        );
      },
    );

  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted) {
        setState(() {
          _isLoggedIn = user != null;
        });
      }
    });
  }

  Future<void> _getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = position;
    });
  }

  @override
  Widget build(BuildContext context) {
    var currentUser = FirebaseAuth.instance.currentUser;
    String text = currentUser?.email ?? 'User is currently signed out!';

    return Scaffold(
        appBar: AppBar(
          title: const Text('Profil'),
          backgroundColor:  const Color(0xFF2487DC),
        ),
        body : Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: StreamBuilder(stream:FirebaseFirestore.instance
                      .collection('spot')
                      .where('userid', isEqualTo: currentUser?.uid)
                      .snapshots(),
                      builder: (BuildContext context,AsyncSnapshot<QuerySnapshot> snapshot){
                        if(!snapshot.hasData){
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        return Container(
                          height: MediaQuery.of(context).size.height/2,
                          width: MediaQuery.of(context).size.width*3/4,
                          child: ListView(
                            children: snapshot.data!.docs.map((snap){
                              String id = snap.id;
                              return Card(
                                child: ListTile(
                                  title: Text(snap['description'].toString()),
                                  subtitle: Text(snap['mot-cles'].toString()),
                                  trailing: SizedBox(
                                    width: 80,
                                    child: Row(
                                      children: <Widget>[
                                        Expanded(
                                          child: IconButton(
                                            icon: const Icon(Icons.edit_outlined),
                                            onPressed: () {
                                              // Define the edit function here
                                              _showEditForm(context,id);
                                              // find a way to pass id
                                            },
                                          ),
                                        ),
                                        Expanded(
                                          child: IconButton(
                                            icon: const Icon(Icons.delete_forever_outlined),
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (BuildContext context) {
                                                  return AlertDialog(
                                                    title: const Text("Confirmation"),
                                                    content: const Text("Are you sure you want to delete this item?"),
                                                    actions: <Widget>[
                                                      TextButton(
                                                        child: const Text("Cancel"),
                                                        onPressed: () {
                                                          Navigator.of(context).pop();
                                                        },
                                                      ),
                                                      TextButton(
                                                        child: const Text("Delete"),
                                                        onPressed: () {
                                                          FirebaseFirestore.instance.collection('spot').doc(snap.id).delete();
                                                          // Define the delete function here
                                                          // e.g. FirebaseFirestore.instance.collection('documents').doc(snap.id).delete();
                                                          Navigator.of(context).pop();
                                                        },
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );


                            }).toList(),
                          ),
                        );

                      }
                  ),
                ),

                Text(text),
                const SizedBox(height: 30),
                Visibility(
                  visible: _isLoggedIn,
                  child: ElevatedButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                    },
                    child: const Text("Signout"),
                  ),
                ),

              ],
            )
        )
    );
  }
}


