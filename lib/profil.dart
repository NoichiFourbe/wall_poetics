import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Profil extends StatefulWidget {
  const Profil({Key? key}) : super(key: key);
  @override
  State<Profil> createState() => _ProfilState();
}

class _ProfilState extends State<Profil> {
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted) {
        setState(() {
          _isLoggedIn = user != null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var currentUser = FirebaseAuth.instance.currentUser;
    print(currentUser?.uid);
    String text = currentUser?.email ?? 'User is currently signed out!';

    return Scaffold(
        appBar: AppBar(
          title: Text('Profil'),
          backgroundColor:  Color(0xFFE19F0C),
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
                              return Card(
                                child: ListTile(
                                  title: Text(snap['description'].toString()),
                                  subtitle: Text(snap['mot-cles'].toString()),
                                  trailing: SizedBox(
                                    width: 80,
                                    child: Row(
                                      children: <Widget>[
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined),
                                          onPressed: () {
                                            // Define the edit function here
                                            // e.g. Navigator.pushNamed(context, '/edit', arguments: snap.id);
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_forever_outlined),
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title: const Text("Confirmation"),
                                                  content: const Text("Souhaitez-vous vraiment supprimer ce stand? Il ne sera plus récupérable"),
                                                  actions: <Widget>[
                                                    TextButton(
                                                      child: const Text("Annuler"),
                                                      onPressed: () {
                                                        Navigator.of(context).pop();
                                                      },
                                                    ),
                                                    TextButton(
                                                      child: const Text("Supprimer le stand"),
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
