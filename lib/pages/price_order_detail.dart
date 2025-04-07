// price_order_detail.dart

import 'package:scope_app/pages/price_orders.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'package:scope_app/firestore/fire_price_orders.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class PriceOrderDetailPage extends StatefulWidget {
  const PriceOrderDetailPage(
      {super.key, required this.id, required this.numero});
  final String id;
  final String numero;
  static const routeName = '/PriceOrderDetailPage';

  @override
  State<PriceOrderDetailPage> createState() => _PriceOrderDetailPageState();
}

class _PriceOrderDetailPageState extends State<PriceOrderDetailPage> {
  var isLoaded = false;
  var textActionCard = 'Grabar';
  var colorActionCard = Colors.blue;
  var id = '';
  int _skuIndex = 0;
  int _skuLimit = 0;
  bool swLocked = false;
  bool swPromocion = false;
  final precioInput = TextEditingController();
  final observacionInput = TextEditingController();
  final coInput = TextEditingController();
  File? _image;
  final picker = ImagePicker();
  List<Map> _list_images = [];
  late Map order = {
    "cadena": {"nombre": ""},
    "local": {"nombre": ""},
    "sku": []
  };

  @override
  void initState() {
    isLoaded = false;
    id = widget.id;
    getOrder();
    super.initState();
  }

  getOrder() async {
    order = await getPriceOrderById(id) as Map;

    // Guardar estado INICIADA y geolocalización inmediatamente
    if (order['estado']?['id'] == 'eNyPUyFqo8SrwkKvDAgD') {
      await saveStatus("INICIADA");
      await savePosition("INICIADA");
    }

    setState(() {
      isLoaded = true;
      _skuLimit = order['sku']?.length ?? 0;
      rendering(true);
    });
  }

  rendering(bool initial) {
    setState(() {
      textActionCard = 'Grabar';
      colorActionCard = Colors.blue;
      precioInput.text = order['sku'][_skuIndex]['precio']?.toString() ?? '';
      observacionInput.text = order['sku'][_skuIndex]['observacion'] ?? '';
      swPromocion = order['sku'][_skuIndex]['promocion'] ?? false;
      swLocked = order['sku'][_skuIndex]['bloqueado'] ?? false;
      if (initial && order['fotos'] != null) {
        for (Map item in order['fotos']) {
          if (item.containsKey('url')) {
            _list_images.add({
              'id': _list_images.length + 1,
              'nombre': item['nombre'],
              'url': item['url']
            });
          }
        }
      }
    });
  }

  saveDocument() async {
    if (precioInput.text.trim() == '') {
      showAlertDialog("Campo requerido", "Debes ingresar un precio.");
      return;
    }
    order['sku'][_skuIndex]['precio'] = precioInput.text.trim();
    order['sku'][_skuIndex]['promocion'] = swPromocion;
    order['sku'][_skuIndex]['observacion'] = observacionInput.text.trim();
    order['sku'][_skuIndex]['bloqueado'] = swLocked;
    order['sku'][_skuIndex]['saved'] = true;
    bool updated = await updatePriceOrderSku(id, order);
    if (updated) {
      Fluttertoast.showToast(
        msg: "SKU actualizado",
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: Colors.black,
        textColor: Colors.white,
      );
      saveStatus("EN PROGRESO");
      setState(() {
        textActionCard = 'Actualizar';
        colorActionCard = Colors.green;
      });
    }
  }

  saveStatus(String estado) async {
    switch (estado) {
      case "INICIADA":
        order['estado'] = {"id": "LT4ytmo1DoCbXR3cj8k2", "nombre": "INICIADA"};
        break;
      case "EN PROGRESO":
        order['estado'] = {
          "id": "rYPNu37CXYaD2EHDGS6u",
          "nombre": "EN PROGRESO"
        };
        order['inprogress'] =
            DateFormat('yyyy-MM-dd hh:mm').format(DateTime.now());
        break;
      case "FINALIZADA":
        order['estado'] = {
          "id": "kq5JBF6UyK26E2S7fEz1",
          "nombre": "FINALIZADA"
        };
        order['finalizada'] =
            DateFormat('yyyy-MM-dd hh:mm').format(DateTime.now());
        break;
    }
    await updatePriceOrderStatus(id, order);
  }

  savePosition(String etapa) async {
    Position position = await _determinePosition();
    switch (etapa) {
      case "INICIADA":
        order['geolocation_iniciada'] = {
          "latitude": position.latitude,
          "longitude": position.longitude
        };
        break;
      case "FINALIZADA":
        order['geolocation_finalizada'] = {
          "latitude": position.latitude,
          "longitude": position.longitude
        };
        break;
    }
    await updatePriceOrderPosition(id, order);
  }

  finalizeOrder() async {
    bool allSaved = order['sku'].every((sku) => sku['saved'] == true);
    if (!allSaved) {
      showAlertDialog("Error", "No todos los SKUs han sido guardados.");
      return;
    }
    saveStatus("FINALIZADA");
    savePosition("FINALIZADA");
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const PriceOrdersPage()));
  }

  Future<void> showAlertDialog(String title, String message) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Ubicación desactivada');
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Permiso de ubicación denegado');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Permiso de ubicación denegado permanentemente');
    }
    return await Geolocator.getCurrentPosition();
  }

  Future getImage() async {
    var selectedFile = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxHeight: 637,
        maxWidth: 637,
        imageQuality: 95);
    setState(() {
      _image = File(selectedFile!.path);
      if (_image != null) {
        uploadFile();
      }
    });
  }

  Future uploadFile() async {
    if (_image == null) return;
    String fileName =
        '${order['numero']}_${DateFormat('yyyyMMdd_hhmmss').format(DateTime.now())}.jpg';
    final ref = firebase_storage.FirebaseStorage.instance
        .ref('scope-app/fotos-PricesOrders/')
        .child(fileName);
    await ref.putFile(_image!);
    String url = await ref.getDownloadURL();
    String fecha = DateFormat('yyyy-MM-dd hh:mm:ss').format(DateTime.now());

    // ✅ Arreglo aquí
    if (order['fotos'] == null) {
      order['fotos'] = [];
    }

    order['fotos'].add({'fecha': fecha, 'nombre': fileName, 'url': url});
    await updatePriceOrderPhoto(id, order);

    setState(() {
      _list_images.add({
        'id': _list_images.length + 1,
        'nombre': fileName,
        'url': url,
      });
    });
  }

  void showAddSkuDialog(BuildContext context) {
    final skuInput = TextEditingController();
    final marcaInput = TextEditingController();
    final descripcionInput = TextEditingController();
    final presentacionInput = TextEditingController();
    final saborInput = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Agregar nuevo SKU"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                    controller: skuInput,
                    decoration: const InputDecoration(labelText: "Código SKU")),
                TextFormField(
                    controller: marcaInput,
                    decoration: const InputDecoration(labelText: "Marca")),
                TextFormField(
                    controller: descripcionInput,
                    decoration: const InputDecoration(labelText: "Producto")),
                TextFormField(
                    controller: presentacionInput,
                    decoration:
                        const InputDecoration(labelText: "Presentación")),
                TextFormField(
                    controller: saborInput,
                    decoration: const InputDecoration(labelText: "Sabor")),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () async {
                if (skuInput.text.isEmpty || descripcionInput.text.isEmpty) {
                  Fluttertoast.showToast(
                      msg: "SKU y producto son obligatorios");
                  return;
                }

                final nuevoSku = {
                  "sku": skuInput.text.trim(),
                  "ds_marca": marcaInput.text.trim(),
                  "descripcion": descripcionInput.text.trim(),
                  "presentacion": presentacionInput.text.trim(),
                  "sabor": saborInput.text.trim(),
                  "estado": "A",
                  "cliente": order['cliente']?['id'] ?? '',
                  "ds_cliente": order['cliente']?['razonsocial'] ?? ''
                };

                order['sku'].add(nuevoSku);
                bool updated = await updatePriceOrderSku(id, order);

                if (updated) {
                  Fluttertoast.showToast(msg: "SKU agregado exitosamente");
                  setState(() {
                    _skuLimit = order['sku'].length;
                    _skuIndex = _skuLimit - 1;
                  });
                  Navigator.of(context).pop();
                } else {
                  Fluttertoast.showToast(msg: "Error al guardar el SKU");
                }
              },
              child: const Text("Guardar"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            backgroundColor: Colors.lightBlue.shade800,
            leading: BackButton(
              color: Colors.white,
              onPressed: () => Navigator.of(context).pop(),
            ),
            centerTitle: true, // <- ¡Esto lo centra visualmente!
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.attach_money, color: Colors.white, size: 22),
                    SizedBox(width: 5),
                    Text(
                      'Órdenes de Precio',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (order['tipoPrecio'] == 'competencia')
                        ? Colors.redAccent
                        : Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order['tipoPrecio']?.toUpperCase() ?? 'TIPO DESCONOCIDO',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            bottom: const TabBar(
              tabs: [
                Tab(text: "Productos"),
                Tab(text: "Imágenes"),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              order['sku'] == null || order['sku'].isEmpty
                  ? const Center(
                      child: Text(
                        "No hay SKUs en esta orden.\nUsa el botón + para agregar uno.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: EdgeInsets.only(
                        left: 8,
                        right: 8,
                        bottom: MediaQuery.of(context).viewInsets.bottom + 80,
                        top: 10,
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back),
                                onPressed: () {
                                  if (_skuIndex > 0) {
                                    setState(() {
                                      _skuIndex--;
                                      rendering(false);
                                    });
                                  }
                                },
                              ),
                              const Spacer(),
                              Column(
                                children: [
                                  Text("SKU ${_skuIndex + 1} de $_skuLimit"),
                                  const SizedBox(height: 4),
                                  Text(
                                    "SKU: ${order['sku'][_skuIndex]['sku'] ?? '-'}",
                                    style: const TextStyle(
                                        fontSize: 14, color: Colors.black54),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.arrow_forward),
                                onPressed: () {
                                  if (_skuIndex + 1 < _skuLimit) {
                                    setState(() {
                                      _skuIndex++;
                                      rendering(false);
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                          Card(
                            margin: const EdgeInsets.all(10),
                            elevation: 5,
                            shadowColor: Colors.black45,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // CLIENTE / CADENA / LOCAL
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.apartment,
                                                size: 18),
                                            const SizedBox(width: 6),
                                            Text(
                                              "Cliente: ${order['cliente']?['razonsocial'] ?? '-'}",
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            const Icon(Icons.storefront,
                                                size: 18),
                                            const SizedBox(width: 6),
                                            Text(
                                              "Cadena: ${order['cadena']?['nombre'] ?? '-'}",
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            const Icon(Icons.location_on,
                                                size: 18),
                                            const SizedBox(width: 6),
                                            Text(
                                              "Local: ${order['local']?['nombre'] ?? '-'}",
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 15),

                                  // BLOQUEADO
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text("Bloqueado"),
                                    trailing: Switch(
                                      value: swLocked,
                                      onChanged: (value) {
                                        setState(() {
                                          swLocked = value;
                                        });
                                      },
                                    ),
                                  ),

                                  const Divider(height: 15),

                                  // INFO DEL SKU
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      "Marca: ${order['sku'][_skuIndex]['ds_marca'] ?? '-'}\n"
                                      "Producto: ${order['sku'][_skuIndex]['descripcion'] ?? '-'}\n"
                                      "Presentación: ${order['sku'][_skuIndex]['presentacion'] ?? '-'}\n"
                                      "Sabor: ${order['sku'][_skuIndex]['sabor'] ?? '-'}",
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                  ),

                                  const Divider(height: 20),

                                  // PROMOCIÓN
                                  SwitchListTile(
                                    title: const Text("Promoción"),
                                    value: swPromocion,
                                    onChanged: (value) {
                                      setState(() {
                                        swPromocion = value;
                                      });
                                    },
                                  ),

                                  // PRECIO
                                  TextFormField(
                                    controller: precioInput,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      prefixIcon: Icon(Icons.attach_money),
                                      labelText: 'Precio',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  // OBSERVACIONES
                                  TextFormField(
                                    controller: observacionInput,
                                    maxLines: 3,
                                    decoration: const InputDecoration(
                                      prefixIcon: Icon(Icons.comment),
                                      labelText: 'Observaciones',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),

                                  const SizedBox(height: 15),

                                  // BOTÓN DE GRABAR
                                  Center(
                                    child: ElevatedButton.icon(
                                      onPressed: saveDocument,
                                      icon: const Icon(Icons.save_alt),
                                      label: Text(
                                        textActionCard,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: colorActionCard,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 24, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 25), // espacio final
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

              // TAB 2: Imágenes
              ListView.builder(
                itemCount: _list_images.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      leading: Image.network(_list_images[index]['url']),
                      title: Text("Foto #${index + 1}"),
                      subtitle: Text(_list_images[index]['nombre']),
                    ),
                  );
                },
              )
            ],
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          floatingActionButton: MediaQuery.of(context).viewInsets.bottom == 0
              ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      FloatingActionButton(
                        onPressed: getImage,
                        heroTag: 'foto',
                        backgroundColor: Colors.lightBlue.shade800,
                        child: const Icon(Icons.camera_alt_outlined),
                      ),
                      FloatingActionButton(
                        onPressed: () {
                          showAddSkuDialog(context);
                        },
                        heroTag: 'addSku',
                        backgroundColor: Colors.green.shade700,
                        child: const Icon(Icons.add),
                        tooltip: 'Agregar SKU',
                      ),
                      FloatingActionButton(
                        onPressed: finalizeOrder,
                        heroTag: 'finalizar',
                        backgroundColor: Colors.lightBlue.shade800,
                        child: const Icon(Icons.check_outlined),
                      ),
                    ],
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
