//import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scope_app/pages/orders.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
//import 'package:camera/camera.dart';
import 'package:scope_app/firestore/fire_order.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

enum status {
    STARTED,
    IN_PROGRESS,
    FINALIZED
}

class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({super.key, required this.id, required this.numero});
  final String id;
  final String numero;
  static const routeName = '/OrderDetailPage';
  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  
  var isLoaded = false;
  var textActionCard = 'Grabar';
  var colorActionCard = Colors.blue;
  var id = '';
  int _skuIndex = 0;
  int _skuLimit = 0;
  bool swLocked = false;
  bool swCenefaPromo = false;
  bool swExhibicion = false;  
  final ciInput = TextEditingController();
  final cfInput = TextEditingController();
  final ncInput = TextEditingController();
  final psInput = TextEditingController();
  final obInput = TextEditingController();
  final ppInput = TextEditingController();
  final ccInput = TextEditingController();
  final coInput = TextEditingController();
  final caducidadInput = TextEditingController(); 
  File? _image;
  final picker = ImagePicker();
  List<Map> _list_images = [];
  //late Future<void> _initializeControllerFuture;
  //late CameraController _controller;
  late Map order={
    "cadena": {
      "nombre":""
    },
    "local": {
      "nombre":""
    },
    "sku": [
      {
        "inicial": "0",
      }
    ]
  };

  @override
  void initState() {
    isLoaded = false;
    id = widget.id;
    getOrder();
    //getCameras();
    super.initState();
    setState(() {
      //getOrder();
      textActionCard = 'Grabar';
      colorActionCard = Colors.blue;
    });
  }

  @override
  void dispose() {
    isLoaded = false;
    super.dispose();
  }

  getOrder() async {
    order = await getOrderById(id) as Map;
    print(order.toString());
    // print(order as Map);
    setState(() {
        isLoaded = true;
        _skuLimit = order['sku'].length;
       rendering(true);
       if(order['estado']['id'] == 'eNyPUyFqo8SrwkKvDAgD') { //creada
        saveStatus(status.STARTED);
        savePosition(status.STARTED);
      }
    });    
  }

  rendering (bool initial_charge) {
    setState(() {
      textActionCard = 'Grabar';
      colorActionCard = Colors.blue;  
    });
    if(order['sku'][_skuIndex].containsKey('saved')) {
      final saved = order['sku'][_skuIndex]['saved'];
      if(saved) {
        setState(() {
          textActionCard = 'Actualizar';
          colorActionCard = Colors.green;
        });
      }
    }
    if(order['sku'][_skuIndex].containsKey('bloqueado')) {
        setState(() {
          swLocked = order['sku'][_skuIndex]['bloqueado'];
        });
    } else {
      setState(() {
          swLocked = false;
        });
    }
    if(initial_charge) {
      if(order.containsKey('fotos')) {
        for(Map item in order['fotos']) {
          if(item.containsKey('url')) {
            _list_images.add({
              'id': _list_images.length + 1,
              'nombre': item['nombre'],
              'url': item['url']
            });
          } 
        }
      } else {
        order['fotos'] = [];
      }
    }
    ciInput.text = (order['sku'][_skuIndex]['inicial'] == null) ? '': order['sku'][_skuIndex]['inicial'].toString();
    cfInput.text = (order['sku'][_skuIndex]['final'] == null) ? '': order['sku'][_skuIndex]['final'].toString();
    ncInput.text = (order['sku'][_skuIndex]['caras'] == null) ? '': order['sku'][_skuIndex]['caras'].toString();
    psInput.text = (order['sku'][_skuIndex]['sugerido'] == null) ? '': order['sku'][_skuIndex]['sugerido'].toString();
    obInput.text = (order['sku'][_skuIndex]['observacion'] == null) ? '': order['sku'][_skuIndex]['observacion'].toString();
    ppInput.text = (order['sku'][_skuIndex]['participacion'] == null) ? '': order['sku'][_skuIndex]['participacion'].toString();
    ccInput.text = (order['sku'][_skuIndex]['cantidad_caducar'] == null) ? '': order['sku'][_skuIndex]['cantidad_caducar'].toString();
    caducidadInput.text  = (order['sku'][_skuIndex]['proxima_caducidad'] == null) ? '': order['sku'][_skuIndex]['proxima_caducidad'].toString();
    setState(() {
      swCenefaPromo =  (order['sku'][_skuIndex]['cenefa_promo'] == null) ? false: order['sku'][_skuIndex]['cenefa_promo'];
      swExhibicion  =  (order['sku'][_skuIndex]['exhibicion'] == null) ? false: order['sku'][_skuIndex]['exhibicion'];
    });
  }

  saveDocument() async {
    if(ciInput.text.trim() == '') {
      showAlertDialog("Scope Alert!","Cantidad Inicial no puede ser vacío.");
      return false;
    }
    if(cfInput.text.trim() == '') {
      showAlertDialog("Scope Alert!","Cantidad Final no puede ser vacío.");
      return false;
    }
    if(ncInput.text.trim() == '') {
      showAlertDialog("Scope Alert!","# de caras no puede ser vacío.");
      return false;
    }
    order['sku'][_skuIndex]['bloqueado'] = swLocked;
    order['sku'][_skuIndex]['inicial'] = (ciInput.text.trim() == '') ? '0' : ciInput.text.trim();
    order['sku'][_skuIndex]['final'] = (cfInput.text.trim() == '') ? '0' : cfInput.text.trim();
    order['sku'][_skuIndex]['caras'] = (ncInput.text.trim() == '') ? '0' : ncInput.text.trim();
    order['sku'][_skuIndex]['sugerido'] = (psInput.text.trim() == '') ? '0' : psInput.text.trim();
    order['sku'][_skuIndex]['observacion'] = obInput.text.trim();
    order['sku'][_skuIndex]['participacion'] = (ppInput.text.trim() == '') ? '0' : ppInput.text.trim();
    order['sku'][_skuIndex]['cantidad_caducar'] = (ccInput.text.trim() == '') ? '0' : ccInput.text.trim();
    order['sku'][_skuIndex]['proxima_caducidad'] = (caducidadInput.text.trim() == '') ? '' : caducidadInput.text.trim();
    order['sku'][_skuIndex]['cenefa_promo'] = swCenefaPromo;
    order['sku'][_skuIndex]['exhibicion'] = swExhibicion;
    order['sku'][_skuIndex]['saved'] = true;
    bool updated = await updateSkuOrder(id, order);
    print (updated);
    if(updated) {
      Fluttertoast.showToast(
        msg: "Se grabó correctamente",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.black,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      if(order['estado']['id'] == 'LT4ytmo1DoCbXR3cj8k2') { //STARTED
        saveStatus(status.IN_PROGRESS);
      }
      setState(() {
        textActionCard = 'Actualizar';
        colorActionCard = Colors.green;
      });
    }
  }

  saveLocked() async {
    if(swLocked) {
      order['sku'][_skuIndex]['bloqueado'] = swLocked;
      order['sku'][_skuIndex]['inicial'] = ciInput.text = '';
      order['sku'][_skuIndex]['final'] = cfInput.text = '';
      order['sku'][_skuIndex]['caras'] = ncInput.text = '';
      order['sku'][_skuIndex]['sugerido'] = psInput.text = '';
      order['sku'][_skuIndex]['observacion'] = obInput.text = '';
      order['sku'][_skuIndex]['participacion'] = ppInput.text = '';
      order['sku'][_skuIndex]['cantidad_caducar'] = ccInput.text = '';
      order['sku'][_skuIndex]['proxima_caducidad'] = caducidadInput.text = '';
      order['sku'][_skuIndex]['cenefa_promo'] = swCenefaPromo = false;
      order['sku'][_skuIndex]['exhibicion'] = swExhibicion = false;
      order['sku'][_skuIndex]['saved'] = true;

      bool updated = await updateSkuOrder(id, order);
      if(updated) {
        Fluttertoast.showToast(
          msg: "Se grabó correctamente",
          toastLength: Toast.LENGTH_SHORT,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.black,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        if(order['estado']['id'] == 'LT4ytmo1DoCbXR3cj8k2') { //STARTED
          saveStatus(status.IN_PROGRESS);
        }
        setState(() {
          textActionCard = 'Actualizar';
          colorActionCard = Colors.green;
          swCenefaPromo = false;
          swExhibicion = false;
        });
      }
    }
  }

  saveStatus(status s) async {
    switch(s) {
      case status.STARTED:
        order['estado'] = {"id": "LT4ytmo1DoCbXR3cj8k2", "nombre": "INICIADA"};
        break;
      case status.IN_PROGRESS:
        order['estado'] = {"id": "rYPNu37CXYaD2EHDGS6u", "nombre": "EN PROGRESO"};
        order['inprogress'] = DateFormat('yyyy-MM-dd hh:mm').format(DateTime.now());
        break;
      case status.FINALIZED: 
        order['estado'] = {"id": "kq5JBF6UyK26E2S7fEz1", "nombre": "FINALIZADA"};
        order['finalizada'] = DateFormat('yyyy-MM-dd hh:mm').format(DateTime.now());
        break;
    }
    print("id ${id}");
    await updateStatusOrder(id, order);
  }

  savePosition(status s) async {
    Position position = await _determinePosition();
    print(position.latitude);
    print(position.longitude);
    switch(s) {
      case status.STARTED:
        order['geolocation_iniciada'] = {"latitude": position.latitude, "longitude": position.longitude};
        break;
      case status.IN_PROGRESS:
        break;
      case status.FINALIZED: 
        order['geolocation_finalizada'] = {"latitude": position.latitude, "longitude": position.longitude};
        break;
    }
    await updatePositionOrder(id, order);
  }

  finalizeOrder() async {
      order['estado'] = {"id": "kq5JBF6UyK26E2S7fEz1", "nombre": "FINALIZADA"};
      order['finalizada'] = DateFormat('yyyy-MM-dd hh:mm').format(DateTime.now());
      bool updated = await updateStatusOrder(id, order);
      print('FINALIZADA');
      print(updated);
      if(updated) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const OrderPage())
        );
      } else {
        showAlertDialog("Scope Alert", "No se pudo finalizar la orden");
      }
      return updated;
  }

  Future getImage() async {
    //final pickerImage = picker.pickImage(source: ImageSource.camera);
    var selectedFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxHeight: 637,
      maxWidth: 637,
      imageQuality: 95
    );

    setState(() {
      _image = File(selectedFile!.path);
      if(_image != null) {
        uploadFile();
      }
    });
  }

  Future uploadFile() async {
    if (_image == null) return;
    String url = '';
    String fecha = DateFormat('yyyy-MM-dd hh:mm:ss').format(DateTime.now());
    String fileName ='${order['numero']}_${DateFormat('yyyyMMdd_hhmmss').format(DateTime.now())}.jpg';
    try {
      /** Save to firebase storage */
      final ref = firebase_storage.FirebaseStorage.instance
          .ref('scope-app/fotos/')
          .child(fileName);
      await ref.putFile(_image!);
      url = (await ref.getDownloadURL()).toString();

      /** Object to firebase database*/
      order['fotos'].add({
        'fecha': fecha,
        'nombre': fileName,
        'url': url
      });
      await updatePhotoOrder(id, order);
      setState(() {
        _list_images.add({
          'id': _list_images.length + 1,
          'nombre': fileName,
          'url': url
        });
      });
    } catch (e) {
      print('error occured');
    }
  }

/*
  getCameras() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;
    print(firstCamera);
    CameraController controller = CameraController(
      firstCamera,
      ResolutionPreset.medium,
    );
    _initializeControllerFuture = controller.initialize();

  }
  */
  Future<void> showAlertDialog(String title, String message) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, 
      builder: (BuildContext context) {
        return AlertDialog( 
          title: Text(title),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(message),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    Future<void> showInputDialog(String title, String message) async {
      return showDialog<void>(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) {
          return AlertDialog( // <-- SEE HERE
            title: Text(title),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(message),
                  TextFormField(
                        controller: coInput,
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                          labelText: 'Ingrese el texto: ',
                        ),
                    )
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancelar'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('Finalizar'),
                onPressed: () {
                  savePosition(status.FINALIZED);
                  finalizeOrder();
                },
              ),
            ],
          );
        },
      );
    }

    List<Widget> widgetTabs = <Widget> [
      ListView(
        padding: const EdgeInsets.all(8),
        children: <Widget>[
          Row(
              //mainAxisAlignment: MainAxisAlignment.center,
              children:  <Widget>[
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        if(_skuIndex > 0) {
                          _skuIndex--;
                          rendering(false);
                        }
                      });
                    },
                    icon: const Icon(
                      Icons.arrow_back_outlined,
                      size: 30,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const Spacer(),
                Column(
                  children: [
                    Text(
                      (order['sku'][_skuIndex]['descripcion'].toString() + order['sku'][_skuIndex]['presentacion'].toString()).length > 33 ?
                        (order['sku'][_skuIndex]['descripcion'].toString() + order['sku'][_skuIndex]['presentacion'].toString()).substring(0,33) : 
                        (order['sku'][_skuIndex]['descripcion'].toString() + order['sku'][_skuIndex]['presentacion'].toString())
                       ,  
                      style: const TextStyle(
                        fontSize: 12, 
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 14, 77, 128)
                      ),
                    ),
                    Text(
                      order['sku'][_skuIndex]['sabor'].toString()
                      ,  
                      style: const TextStyle(
                        fontSize: 11, 
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 124, 124, 124)
                      ),
                    ),
                    Text(
                      "Sku ${_skuIndex+1} de ${order['sku'].length}",
                      style: const TextStyle(
                        fontSize: 10, 
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 14, 77, 128)
                      )
                    )
                  ],
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        if(_skuIndex + 1 < _skuLimit) {
                          _skuIndex++;
                          rendering(false);
                        }
                      });
                    },
                    icon: const Icon(
                      Icons.arrow_forward_outlined,
                      size: 30,
                      color: Colors.blue
                    ),
                  ),
                ),
            ],),
            Card(
              margin: const EdgeInsets.all(10),
              elevation: 10,
              //color: Colors.white,
              shadowColor: Colors.blueAccent,
              child: Column(children: [
                 ListTile(
                  tileColor: Colors.white,
                  leading: IconButton(
                    onPressed: () {
                     saveDocument();
                    },
                    icon: Icon(
                      Icons.save_outlined,
                      size: 30,
                      color: colorActionCard,
                    ),
                  ),
                  title:  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Bloqueado",
                        style: TextStyle(fontSize: 15),
                      ),
                      Switch(
                        value: swLocked,
                        activeColor: Colors.lightGreen.shade700,
                        onChanged: (bool value) {
                          setState(() {
                            swLocked = value;
                            if(value) {
                              swCenefaPromo = false;
                              swExhibicion = false;
                            }
                          });
                          saveLocked();
                        },
                      )
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(left: 30.0, right: 30.0, bottom: 15.0),
                  alignment: Alignment.center,
                  color: Colors.white,
                  child: Column(children: [
                    TextFormField(
                        controller: ciInput,
                        enabled: !swLocked,
                        keyboardType: TextInputType.number,
                        //initialValue: (order['sku'][_skuIndex]['inicial'] == null) ? '': order['sku'][_skuIndex]['inicial'].toString(),
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                          icon: Icon(Icons.grid_view_outlined),
                          labelText: 'Cantidad Inicial: ',
                        ),
                    ),
                    TextFormField(
                        controller: cfInput,
                        enabled: !swLocked,
                        keyboardType: TextInputType.number,
                        //initialValue: order['sku'][_skuIndex]['final'].toString(),
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                          icon: Icon(Icons.grid_view_outlined),
                          labelText: 'Cantidad Final: ',
                        ),
                    ),
                    TextFormField(
                        controller: ncInput,
                        enabled: !swLocked,
                        keyboardType: TextInputType.number,
                        //initialValue: order['sku'][_skuIndex]['caras'].toString(),
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                          icon: Icon(Icons.grid_view_outlined),
                          labelText: '# Caras: ',
                        ),
                    ),
                    TextFormField(
                        controller: psInput,
                        enabled: !swLocked,
                        keyboardType: TextInputType.number,
                        //initialValue: order['sku'][_skuIndex]['sugerido'].toString(),
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                          icon: Icon(Icons.grid_view_outlined),
                          labelText: 'Pedido Sugerido: ',
                        ),
                    ),
                    TextFormField(
                        controller: obInput,
                        enabled: !swLocked,
                        //initialValue: order['sku'][_skuIndex]['observacion'].toString(),
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                          icon: Icon(Icons.edit_note_outlined),
                          labelText: 'Obs: ',
                        ),
                    ),
                    TextFormField(
                        controller: ppInput,
                        enabled: !swLocked,
                        keyboardType: TextInputType.number,
                        //initialValue: order['sku'][_skuIndex]['participacion'].toString(),
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                          icon: Icon(Icons.grid_view_outlined),
                          labelText: 'Participacion Percha: ',
                        ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.check),
                            Text('    Cenefa Promo'),
                          ],
                        ),
                        Switch(
                        value: swCenefaPromo,
                        activeColor: Colors.lightBlue.shade700,
                        onChanged: (swLocked)? null: (bool value) {
                          setState(() {
                            swCenefaPromo = value;
                          });
                        },
                      )
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.check),
                            Text('    Exhibicion'),
                          ],
                        ),
                        Switch(
                        value: swExhibicion,
                        activeColor: Colors.lightBlue.shade700,
                        onChanged: (swLocked)? null: (bool value) {
                          setState(() {
                            swExhibicion = value;
                          });
                        },
                      )
                      ],
                    ),
                    TextFormField(
                        controller: ccInput,
                        enabled: !swLocked,
                        keyboardType: TextInputType.number,
                        //initialValue: order['sku'][_skuIndex]['cantidad_caducar'].toString(),
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                          icon: Icon(Icons.grid_view_outlined),
                          labelText: 'Cantidad a Caducar: ',
                        ),
                    ),
                    TextField(
                      controller: caducidadInput, 
                      enabled: !swLocked,
                      decoration: const InputDecoration( 
                        icon: Icon(Icons.calendar_month), 
                        labelText: "Proxima Caducidad" 
                      ),
                      readOnly: true,  
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                            context: context, initialDate: DateTime.now(),
                            firstDate: DateTime.now(), //DateTime(2000) / DateTime.now() - not to allow to choose before today.
                            lastDate: DateTime(2101)
                        );
                      
                        if(pickedDate != null ){
                            String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate); 
                            setState(() {
                              caducidadInput.text = formattedDate; 
                            });
                        }else{
                            // print("Date is not selected");
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: TextButton(
                        onPressed: saveDocument,
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(colorActionCard),
                        ),           
                        child:  Center(
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: Text(textActionCard,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              )
                            ),
                          ),
                        ),
                      ),
                    ),
                  ]),
                )
              ]),
            ),
        ],
      ),
      ListView.builder(
        itemCount: _list_images.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              elevation: 0,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListTile(
                  leading: Image.network(_list_images[index]['url']),
                  //leading: Image.network(order['fotos'][index].url),
                  title: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(child: Text("Foto #${index+1}",style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold,fontSize: 18))),
                  ),
                  subtitle: Center(child: Text("${_list_images[index]['nombre']}",style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold,fontSize: 15))),
                ),
              ),
            ),
          );
        }
      )
      // ListView(
      //   padding: const EdgeInsets.all(8),
      //   children: <Widget>[
      //     Container(
      //       alignment: Alignment.center, 
      //       child: (_image == null)? const Text('Imagenes'): Image.file(_image ?? File('/dev/null'))
      //     ),
      //   ]
      // )
    ];
    
    return MaterialApp(
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            leading: BackButton(
               onPressed: () => Navigator.of(context).pop(),
            ),
            bottom: TabBar(
              labelColor: Colors.lightBlue.shade800,
              unselectedLabelColor: Colors.white,
              indicator: const BoxDecoration(
                borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10)),
                color: Colors.white
              ),
              tabs: const [
                Tab(
                  child: Align(
                    alignment: Alignment.center,
                    child: Text("Productos",),
                  ),
                ),
                Tab(
                  child: Align(
                    alignment: Alignment.center,
                    child: Text("Imagenes",),
                  )
                ),
              ],
            ),
            title: Column(
              children: [
                  Center(
                    child: Text(
                      order['cadena']['nombre'].toString(),
                      style: const TextStyle(fontSize: 17),
                    ),
                  ),
                Center(
                  child:
                  Text(
                          order['local']['nombre'].toString(),
                          style: const TextStyle(fontSize: 12,color: Color.fromARGB(255, 172, 218, 255)),
                        )
                )
              ],
            ),
            backgroundColor: Colors.lightBlue.shade800,
            foregroundColor: Colors.white,
            //elevation: 15,
            //shadowColor: Colors.blueAccent,
            actions: <Widget>[
              Padding(
                padding: const EdgeInsets.only(right: 20.0),
                child: GestureDetector(
                  onTap: () {
                    // Fluttertoast.showToast(
                    //   msg: "Tap tap",
                    //   toastLength: Toast.LENGTH_SHORT,
                    //   timeInSecForIosWeb: 1,
                    //   backgroundColor: Colors.black,
                    //   textColor: Colors.white,
                    //   fontSize: 20.0,
                    // );
                  },
                  child: const Icon(
                      Icons.more_vert
                  ),
                )
              ),
            ],
          ),
          body: order['cadena']['nombre'] == null? const CircularProgressIndicator() : TabBarView(
            children: widgetTabs,
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          floatingActionButton: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                FloatingActionButton(
                  onPressed: () {
                    var hasUnsaved = false;
                    for(Map item in order['sku']) {
                      if(item.containsKey('saved')) {
                        if(!item['saved']) {
                          hasUnsaved = true;
                        }
                      } else {
                        hasUnsaved = true;
                      }
                    }
                    if(hasUnsaved) {
                      showAlertDialog("Scope Alert", "No se han guardado todos los skus");
                      return; 
                    }
                    showInputDialog("Scope Dialog!","Agregar Competencia");
                  },
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.lightBlue.shade800,
                  //shape: const CircleBorder(),
                  child: const Icon(Icons.check_outlined),
                ),
                FloatingActionButton(
                  onPressed: () {
                    //getCameras();
                    getImage();
                  },
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.lightBlue.shade800,
                  //shape: const CircleBorder(),
                  child: const Icon(Icons.camera_alt_outlined),
                )
              ],
            ),
          )
        ),
      ),
    );
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if(!serviceEnabled) {
      return Future.error('Location services are disabled. Please enable the services');

    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {   
        return Future.error('Location permission denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permission are permanently denied');
    }
    Position position = await Geolocator.getCurrentPosition();
    return position;
  }

}