import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/instance_manager.dart';
import 'package:get/route_manager.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:unicons/unicons.dart';
import '../../data/person.dart';
import '../../data/plant.dart';
import '../../utils/colors.dart';
import '../plant/input_field.dart';

class TimelineAddPage extends StatefulWidget{

  const TimelineAddPage({Key? key, required this.person}) : super(key: key);

  final Person person;

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _TimelineAddPage();
  }

}

class _TimelineAddPage extends State<TimelineAddPage>{

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  final TextEditingController dateController = TextEditingController();

  final ScrollController controller = ScrollController();

  late Plant plant;
  Uint8List? image;

  @override
  initState() {
    dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Add Timeline",style: TextStyle(color: primaryColor),),
        elevation: 0,
        backgroundColor: Colors.white,
        leading:  IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black54,),
          onPressed: () { Navigator.pop(context); },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12),
            child: IconButton(
                onPressed: () async{
                  final storageRef = FirebaseStorage.instance.ref();
                  int id = 0;
                  if(plant.timelines!.isNotEmpty){
                    id = plant.timelines!.indexOf(plant.timelines!.last) +1;
                  }
                  final imageRef = storageRef.child("users/${widget.person.uid}/timeLines/$id/image.text");

                  if(image != null){
                    await imageRef.putData(image!);
                  }

                  if(_formKey.currentState!.validate()){
                    plant.timelines!.add({
                      'id' : id,
                      'image': image != null ? await imageRef.getDownloadURL() : null,
                      'date': dateController.text,
                      'title' : titleController.text,
                      'content' : contentController.text
                    });

                    var usersCollection = firestore.collection('users');
                    await usersCollection.doc(widget.person.uid).update(
                        {
                          "plants": widget.person.plantsToJson(widget.person.plants!)
                        }).then((value) => Get.back());
                  }
                },
                icon: Icon(Icons.check, color: Colors.black54,)
            ),
          )
        ],
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child:  Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              image != null ? Scrollbar(
                  thickness: 5,
                  radius: Radius.circular(10),
                  thumbVisibility: true,
                  controller: controller,
                  child: SingleChildScrollView(
                      controller: controller,
                      child: Image.memory(image!, fit: BoxFit.cover)
                  )
              ) : Container(),
              const SizedBox(
                height: 20,
              ),
              Container(
                margin: EdgeInsets.only(left: 20, right: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      InputField(
                        isEditable: false,
                        label: "식물",
                        hint: "",
                        controller: nameController,
                        emptyText: false,
                        icon: Icon(UniconsLine.flower),
                        onTap: (){
                          showDialog(context: context, builder: (context) {
                            return AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("식물 선택"),
                                  IconButton(
                                      onPressed: (){
                                        Get.back();
                                      },
                                      icon: Icon(Icons.close,color: Colors.black54,)
                                  )
                                ],
                              ),
                              content: SizedBox(
                                height: MediaQuery.of(context).size.height * 0.4,
                                width: MediaQuery.of(context).size.width * 0.4,
                                child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: widget.person.plants!.length,
                                    itemBuilder: (BuildContext context, int index) =>
                                        Column(
                                          children: [
                                            Divider(thickness: 1,),
                                            GestureDetector(
                                              child: Row(
                                                children: [
                                                  Padding(
                                                    padding: const EdgeInsets.all(8.0),
                                                    child: Text(widget.person.plants![index]!.name!,style: TextStyle(fontWeight: FontWeight.bold),),
                                                  ),
                                                  Expanded(
                                                    child: Padding(
                                                      padding: const EdgeInsets.all(8.0),
                                                      child: Text(widget.person.plants![index]!.type!,overflow: TextOverflow.ellipsis),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              onTap: (){
                                                setState(() {
                                                  plant = widget.person.plants![index]!;
                                                  nameController.text = widget.person.plants![index]!.name!;
                                                });
                                                Navigator.of(context).pop();
                                              },

                                            ),
                                            index == widget.person.plants!.indexOf(widget.person.plants!.last) ? Divider(thickness: 1,) : Container(),
                                          ],
                                        )
                                ),
                              ),
                            );
                          });
                        },
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      InputField(
                        onTap: () async{
                          await showCupertinoModalPopup(
                              context: context,
                              builder: (BuildContext builder) {
                                return Container(
                                  height: MediaQuery.of(context).copyWith().size.height*0.25,
                                  color: Colors.white,
                                  child: CupertinoDatePicker(
                                    initialDateTime: DateFormat('yyyy-MM-dd').parse(dateController.text), //초기값
                                    maximumDate: DateTime(DateTime.now().year+1), //마지막일
                                    minimumDate: DateTime(DateTime.now().year-1),
                                    mode: CupertinoDatePickerMode.date,
                                    onDateTimeChanged: (value) {
                                      setState(() {
                                        dateController.text = DateFormat('yyyy-MM-dd').format(value);
                                      });
                                    },
                                  ),
                                );
                              }
                          );
                        },
                        controller: dateController,
                        isEditable: false,
                        label: '날짜',
                        emptyText: false,
                        icon: Icon(Icons.calendar_month_outlined),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      TextFormField(
                        controller: titleController,
                        maxLength: 20,
                        validator: (value){
                          if (value.toString().isEmpty) {
                            return '제목을 입력해주세요';
                          }
                        },
                        decoration: InputDecoration(
                          labelStyle: const TextStyle(height:0.1),
                          labelText: "제목",
                        ),
                      ),
                      TextFormField(
                        controller: contentController,
                        keyboardType: TextInputType.multiline,
                        maxLength: 50,
                        maxLines: null,
                        validator: (value){
                          if (value.toString().isEmpty) {
                            return '내용을 입력해주세요';
                          }
                        },
                        decoration: InputDecoration(
                          labelStyle: const TextStyle(height:0.1),
                          labelText: "내용",
                          hintText:  "식물에게 하고 싶은말, 변화 등을 적어보세요!",
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.08,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          )
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          var picker = ImagePicker();
          showCupertinoModalPopup(
            barrierColor: Colors.black54,
            context: context,
            builder: (BuildContext context) => Padding(
              padding: const EdgeInsets.only(left: 16,right: 16),
              child: CupertinoActionSheet(
                  actions: <Widget>[
                    CupertinoActionSheetAction(
                      child: const Text('갤러리에서 가져오기'),
                      onPressed: () async{
                        await picker.pickImage(source: ImageSource.gallery,maxWidth: 1024, maxHeight: 1024)
                            .then((value) async{
                          image = await value?.readAsBytes();
                          setState(() {});

                          Get.back();
                        });
                      },
                    ),
                    CupertinoActionSheetAction(
                      child: const Text('사진 찍기'),
                      onPressed: () async{
                        await picker.pickImage(source: ImageSource.camera,maxWidth: 1024, maxHeight: 1024)
                            .then((value) async{
                          image = await value?.readAsBytes();
                          setState(() {});
                          Get.back();
                        });
                      },
                    )
                  ],
                  cancelButton: CupertinoActionSheetAction(
                    child: const Text('Cancel'),
                    isDefaultAction: true,
                    onPressed: () {
                      Navigator.pop(context, 'Cancel');
                    },
                  )),
            ),
          );
        },
        heroTag: null,
        child: Icon(Icons.camera_alt_outlined,),backgroundColor: primaryColor,),
    );
  }

}
