import 'package:ebiseekleta_app/utils/user_preference.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SetttingScreen extends StatefulWidget {
  const SetttingScreen({super.key});

  @override
  State<SetttingScreen> createState() => _SetttingScreenState();
}

class _SetttingScreenState extends State<SetttingScreen> {
  final formKey = GlobalKey<FormState>();
  final phoneNum = TextEditingController();
  final cyclistName = TextEditingController();
  List<String> contactNums = [];
  var itemCount;

  String? sharedName;
  List<String>? sharedNums = [];

  @override
  void initState() {
    // TODO: implement initState

    getInformation();

    super.initState();
    itemCount = 0;
  }

  addPhoneNumber(String number) {
    contactNums.add(number);
    itemCount = contactNums.length;
  }

  removePhoneNumber(int index) {
    contactNums.removeAt(index);
    itemCount = contactNums.length;
    print(contactNums.toString());
  }

  // _getPermission() async => await [
  //       Permission.sms,
  //       Permission.location,
  //       Permission.camera,
  //     ].request();

  Future getInformation() async {
    final SharedPreferences sharedPreferences =
        await SharedPreferences.getInstance();
    var obtainedName = sharedPreferences.getString('username');
    var obtainedNumbers = sharedPreferences.getStringList('phonenumber');
    setState(() {
      cyclistName.text = obtainedName ?? '';
      obtainedNumbers?.forEach((item) {
        addPhoneNumber(item);
      });
    });
    print(cyclistName.text);
    print(obtainedNumbers);
  }

  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  _row(int index) {
    int contactListNo = index + 1;
    return Column(
      children: [
        Row(
          children: [
            Text('Contact #: $contactListNo'),
            const SizedBox(width: 30),
            Expanded(
              child: Text(contactNums[index]),
            ),
            IconButton(
                onPressed: () async {
                  await removePhoneNumber(index);
                  setState(() {
                    itemCount;
                  });
                },
                icon: Icon(Icons.delete)),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(40),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/logo.png',
                  scale: 1.5,
                ),
                const SizedBox(
                  height: 10,
                ),
                TextFormField(
                  controller: cyclistName,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: InputDecoration(labelText: "Enter your name."),
                  validator: (value) {
                    if (value!.isEmpty ||
                        RegExp(r'^[a-z A-Z]$').hasMatch(value)) {
                      return "Please enter correct value";
                    } else {
                      return null;
                    }
                  },
                ),
                const SizedBox(
                  height: 10,
                ),
                TextFormField(
                  controller: phoneNum,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: InputDecoration(
                      labelText: "Enter close contact number.",
                      suffixIcon: IconButton(
                          onPressed: () async {
                            if (phoneNum.text.isNotEmpty &&
                                RegExp(r'^(09|\+639)\d{9}$')
                                    .hasMatch(phoneNum.text)) {
                              await addPhoneNumber(phoneNum.text);
                              setState(() {
                                itemCount;
                              });
                              phoneNum.clear();
                            }
                          },
                          icon: Icon(Icons.add))),
                  validator: (value) {
                    if (value!.isEmpty ||
                        !RegExp(r'^(09|\+639)\d{9}$').hasMatch(value)) {
                      return "Please enter correct value";
                    } else {
                      return null;
                    }
                  },
                ),
                const SizedBox(
                  height: 10,
                ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: itemCount,
                    itemBuilder: (context, index) {
                      return _row(index);
                    },
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                ElevatedButton(
                    onPressed: () async {
                      if (cyclistName.text.isNotEmpty ||
                          RegExp(r'^[a-z A-Z]$').hasMatch(cyclistName.text)) {
                        final SharedPreferences sharedPreferences =
                            await SharedPreferences.getInstance();
                        sharedPreferences.setString(
                            'username', cyclistName.text);
                        sharedPreferences.setStringList(
                            'phonenumber', contactNums);
                        if (!mounted) return;
                        const snackBar =
                            SnackBar(content: Text('Information saved.'));
                        ScaffoldMessenger.of(context).showSnackBar(snackBar);
                        // Navigator.pushReplacement<void, void>(
                        //   context,
                        //   MaterialPageRoute<void>(
                        //     builder: (BuildContext context) => const MyApp(),
                        //   ),
                        // );
                      }
                    },
                    child: Text("Update")),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
