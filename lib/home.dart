import 'package:abcd/chat.dart';
import 'package:flutter/material.dart';


class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chatapp'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
        ],
        backgroundColor: Colors.blueAccent,
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const UserAccountsDrawerHeader(
              accountName: Text('shibin'),
              accountEmail: Text('shibin001@gmail.com'),
              currentAccountPicture: CircleAvatar(
                child: Icon(Icons.person),
                // backgroundImage: AssetImage('assets/images/2.jpg'),
              ),
            ),
            const SizedBox(height: 30),
            ListTile(
              title: const Text('Profile'),
              leading: const Icon(Icons.person),
              onTap: () {},
            ),
            ListTile(
              title: const Text('New group'),
              leading: const Icon(Icons.group),
              onTap: () {},
            ),
            ListTile(
              title: const Text('Contacts'),
              leading: const Icon(Icons.contacts_rounded),
              onTap: () {},
            ),
            ListTile(
              title: const Text('Settings'),
              leading: const Icon(Icons.settings),
              onTap: () {},
            ),
            ListTile(
              title: const Text('Logout'),
              leading: const Icon(Icons.logout),
              onTap: () {},
            ),
          ],
        ),
      ),
      body: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('Shibin$index'),
            trailing: Text('$index:00pm'),
            leading: const CircleAvatar(
              radius: 30,
              child: Icon(Icons.person),
            ),
            subtitle: const Text('hello world'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>  Chat(),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {},
      ),
    );
  }
}
