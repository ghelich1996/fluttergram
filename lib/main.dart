import 'package:flutter/material.dart';
import 'feed.dart';
import 'upload_page.dart';
import 'dart:async';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_page.dart';
import 'search_page.dart';
import 'activity_feed.dart';
import 'create_account.dart';

final auth = FirebaseAuth.instance;
final googleSignIn = new GoogleSignIn();
final ref = Firestore.instance.collection('insta_users');

User currentUserModel;

Future<Null> _ensureLoggedIn(BuildContext context) async {
  GoogleSignInAccount user = googleSignIn.currentUser;
  if (user == null) {
    user = await googleSignIn.signInSilently();
  }
  if (user == null) {
    await googleSignIn.signIn().then((_) {
      tryCreateUserRecord(context);
    });
  }

  if (await auth.currentUser() == null) {
    GoogleSignInAuthentication credentials =
        await googleSignIn.currentUser.authentication;
    await auth.signInWithGoogle(
        idToken: credentials.idToken, accessToken: credentials.accessToken);
  }
}

Future<Null> _silentLogin(BuildContext context) async {
  GoogleSignInAccount user = googleSignIn.currentUser;

  if (user == null) {
    user = await googleSignIn.signInSilently().then((_) {
      tryCreateUserRecord(context);
    });
  }

  if (await auth.currentUser() == null && user != null) {
    GoogleSignInAuthentication credentials =
        await googleSignIn.currentUser.authentication;
    await auth.signInWithGoogle(
        idToken: credentials.idToken, accessToken: credentials.accessToken);
  }
}

tryCreateUserRecord(BuildContext context) async {
  GoogleSignInAccount user = googleSignIn.currentUser;
  if (user == null) {
    return null;
  }
  DocumentSnapshot userRecord = await ref.document(user.id).get();
  if (userRecord.data == null) {
    // no user record exists, time to create

    String userName = await Navigator.push(
      context,
      // We'll create the SelectionScreen in the next step!
      new MaterialPageRoute(
          builder: (context) => new Center(
                child: new Scaffold(
                    appBar: new AppBar(
                      leading: new Container(),
                      title: new Text('Fill out missing data',
                          style: new TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold)),
                      backgroundColor: Colors.white,
                    ),
                    body: new ListView(
                      children: <Widget>[
                        new Container(
                          child: new CreateAccount(),
                        ),
                      ],
                    )),
              )),
    );

    if (userName != null || userName.length != 0){
      ref.document(user.id).setData({
        "id": user.id,
        "username": userName,
        "photoUrl": user.photoUrl,
        "email": user.email,
        "displayName": user.displayName,
        "bio": "",
        "followers": {},
        "following": {},
      });
    }
  }

  currentUserModel = new User.fromDocument(userRecord);
}

class Fluttergram extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Fluttergram',
      theme: new ThemeData(
          // This is the theme of your application.
          //
          // Try running your application with "flutter run". You'll see the
          // application has a blue toolbar. Then, without quitting the app, try
          // changing the primarySwatch below to Colors.green and then invoke
          // "hot reload" (press "r" in the console where you ran "flutter run",
          // or press Run > Flutter Hot Reload in IntelliJ). Notice that the
          // counter didn't reset back to zero; the application is not restarted.
          primarySwatch: Colors.blue,
          buttonColor: Colors.pink,
          primaryIconTheme: new IconThemeData(color: Colors.black)),
      home: new HomePage(title: 'Fluttergram'),
    );
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _HomePageState createState() => new _HomePageState();
}

PageController pageController;

class _HomePageState extends State<HomePage> {
  int _page = 0;
  bool triedSilentLogin = false;

  Scaffold buildLoginPage() {
    return new Scaffold(
      body: new Center(
        child: new Padding(
          padding: const EdgeInsets.only(top: 240.0),
          child: new Column(
            children: <Widget>[
              new Text(
                'Fluttergram',
                style: new TextStyle(
                    fontSize: 60.0,
                    fontFamily: "Billabong",
                    color: Colors.black),
              ),
              new Padding(padding: const EdgeInsets.only(bottom: 100.0)),
              new GestureDetector(
                onTap: login,
                child: new Image.asset(
                  "assets/images/google_signin_button.png",
                  width: 225.0,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (triedSilentLogin == false) {
      silentLogin(context);
    }
    return googleSignIn.currentUser == null
        ? buildLoginPage()
        : new Scaffold(
            body: new PageView(
              children: [
                new Container(
                  color: Colors.white,
                  child: new Feed(),
                ),
                new Container(color: Colors.white, child: new SearchPage()),
                new Container(
                  color: Colors.white,
                  child: new Uploader(),
                ),
                new Container(
                    color: Colors.white, child: new ActivityFeedPage()),
                new Container(
                    color: Colors.white,
                    child: new ProfilePage(
                      userId: googleSignIn.currentUser.id,
                    )),
              ],
              controller: pageController,
              physics: new NeverScrollableScrollPhysics(),
              onPageChanged: onPageChanged,
            ),
            bottomNavigationBar: new BottomNavigationBar(
              items: <BottomNavigationBarItem>[
                new BottomNavigationBarItem(
                    icon: new Icon(Icons.home, color: Colors.grey),
                    title: new Container(),
                    backgroundColor: Colors.white),
                new BottomNavigationBarItem(
                    icon: new Icon(Icons.search, color: Colors.grey),
                    title: new Container(),
                    backgroundColor: Colors.white),
                new BottomNavigationBarItem(
                    icon: new Icon(Icons.add_circle, color: Colors.grey),
                    title: new Container(),
                    backgroundColor: Colors.white),
                new BottomNavigationBarItem(
                    icon: new Icon(Icons.star, color: Colors.grey),
                    title: new Container(),
                    backgroundColor: Colors.white),
                new BottomNavigationBarItem(
                    icon: new Icon(Icons.person_outline, color: Colors.grey),
                    title: new Container(),
                    backgroundColor: Colors.white),
              ],
              onTap: navigationTapped,
              currentIndex: _page,
              type: BottomNavigationBarType.fixed,
            ),
          );
  }

  void login() async {
    await _ensureLoggedIn(context);
    setState(() {
      triedSilentLogin = true;
    });
  }

  void silentLogin(BuildContext context) async {
    await _silentLogin(context);
    setState(() {});
  }

  void navigationTapped(int page) {
    //Animating Page
    pageController.jumpToPage(page);
  }

  void onPageChanged(int page) {
    setState(() {
      this._page = page;
    });
  }

  @override
  void initState() {
    super.initState();
    pageController = new PageController();
  }

  @override
  void dispose() {
    super.dispose();
    pageController.dispose();
  }
}

void main() => runApp(new Fluttergram());
