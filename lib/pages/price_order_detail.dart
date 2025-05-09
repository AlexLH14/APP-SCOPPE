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

      // Solo renderizar si hay al menos un SKU
      if (_skuLimit > 0) {
        rendering(true);
      }
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
    if (swLocked) {
      // Eliminar los campos si está bloqueado
      order['sku'][_skuIndex].remove('precio');
      order['sku'][_skuIndex].remove('promocion');
      order['sku'][_skuIndex].remove('observacion');
    } else {
      // Validar precio solo si no está bloqueado
      final precioTexto = precioInput.text.trim();
      final precio = double.tryParse(precioTexto);
      if (precioTexto.isEmpty || precio == null || precio <= 0) {
        showAlertDialog(
            "Precio inválido", "Debes ingresar un número válido mayor a 0.");
        return;
      }

      // Asignar campos si no está bloqueado
      order['sku'][_skuIndex]['precio'] = precio;
      order['sku'][_skuIndex]['promocion'] = swPromocion;
      order['sku'][_skuIndex]['observacion'] = observacionInput.text.trim();
    }

    // Guardar estado de bloqueado y bandera de guardado
    order['sku'][_skuIndex]['bloqueado'] = swLocked;
    order['sku'][_skuIndex]['saved'] = true;

    // Guardar en Firestore
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

  saveLocked() async {
    if (swLocked) {
      order['sku'][_skuIndex]['bloqueado'] = true;
      order['sku'][_skuIndex].remove('precio');
      order['sku'][_skuIndex].remove('observacion');
      order['sku'][_skuIndex].remove('promocion');
      order['sku'][_skuIndex]['saved'] = true;

      bool updated = await updatePriceOrderSku(id, order);
      if (updated) {
        Fluttertoast.showToast(
          msg: "SKU bloqueado correctamente",
          toastLength: Toast.LENGTH_SHORT,
          backgroundColor: Colors.black,
          textColor: Colors.white,
        );
        saveStatus("EN PROGRESO");
        setState(() {
          textActionCard = 'Actualizar';
          colorActionCard = Colors.green;
          swPromocion = false;
          precioInput.clear();
          observacionInput.clear();
        });
      }
    }
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
    if (order['sku'] == null || order['sku'].isEmpty) {
      showAlertDialog("Orden vacía", "No puedes finalizar una orden sin SKUs.");
      return;
    }
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

  Future<bool> showConfirmDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text("Confirmar"),
            content: const Text(
                "¿Estás seguro de finalizar la orden?\nEsta acción no se puede deshacer."),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("Cancelar"),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text("Finalizar"),
              ),
            ],
          ),
        ) ??
        false;
  }

  void showAddSkuDialog(BuildContext context) {
    final skuInput = TextEditingController();
    final marcaInput = TextEditingController();
    final descripcionInput = TextEditingController();
    final presentacionInput = TextEditingController();
    final saborInput = TextEditingController();
    bool sinSku = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Agregar nuevo SKU"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: skuInput,
                        enabled: !sinSku,
                        decoration:
                            const InputDecoration(labelText: "Código SKU"),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () {
                        skuInput
                            .clear(); // <- Borramos cualquier texto anterior
                        sinSku = !sinSku;
                        (context as Element)
                            .markNeedsBuild(); // <- Forzamos a redibujar el diálogo
                      },
                      icon: Icon(
                        sinSku ? Icons.undo : Icons.block,
                        size: 16,
                      ),
                      label: Text(sinSku ? "Usar SKU" : "Sin SKU"),
                    ),
                  ],
                ),
                FutureBuilder<List<String>>(
                  future: getMarcasUnicas(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }

                    return Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text == '') {
                          return const Iterable<String>.empty();
                        }
                        return snapshot.data!.where((String option) {
                          return option
                              .toLowerCase()
                              .contains(textEditingValue.text.toLowerCase());
                        });
                      },
                      onSelected: (String selection) {
                        marcaInput.text =
                            selection; // actualizamos nuestro controlador
                      },
                      fieldViewBuilder: (context, textEditingController,
                          focusNode, onEditingComplete) {
                        // Sincronizar cambios al escribir
                        textEditingController.addListener(() {
                          marcaInput.text = textEditingController.text;
                        });

                        return TextFormField(
                          controller: textEditingController,
                          focusNode: focusNode,
                          onEditingComplete: onEditingComplete,
                          decoration: const InputDecoration(
                              labelText: "Marca (autocomplete)"),
                        );
                      },
                    );
                  },
                ),
                FutureBuilder<List<String>>(
                  future: getDescripcionesUnicas(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator(); // mientras carga
                    }

                    return Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text == '') {
                          return const Iterable<String>.empty();
                        }
                        return snapshot.data!.where((String option) {
                          return option
                              .toLowerCase()
                              .contains(textEditingValue.text.toLowerCase());
                        });
                      },
                      onSelected: (String selection) {
                        descripcionInput.text = selection;
                      },
                      fieldViewBuilder: (context, textEditingController,
                          focusNode, onEditingComplete) {
                        // Sincronizamos con tu TextEditingController
                        textEditingController.addListener(() {
                          descripcionInput.text = textEditingController.text;
                        });

                        return TextFormField(
                          controller: textEditingController,
                          focusNode: focusNode,
                          onEditingComplete: onEditingComplete,
                          decoration: const InputDecoration(
                            labelText: "Producto (autocomplete)",
                          ),
                        );
                      },
                    );
                  },
                ),
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
                if (descripcionInput.text.isEmpty) {
                  Fluttertoast.showToast(msg: "El producto es obligatorio");
                  return;
                }

                final nuevoSku = {
                  if (!sinSku) "sku": skuInput.text.trim(),
                  "ds_marca": marcaInput.text.trim(),
                  "descripcion": descripcionInput.text.trim(),
                  "presentacion": presentacionInput.text.trim(),
                  "sabor": saborInput.text.trim(),
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
                    rendering(false);
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
                        ? Colors.blue
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined,
                              size: 80, color: Colors.grey),
                          SizedBox(height: 20),
                          Text(
                            "No hay SKUs en esta orden",
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 10),
                          Text(
                            "Usa el botón + para agregar uno",
                            style:
                                TextStyle(fontSize: 14, color: Colors.black54),
                            textAlign: TextAlign.center,
                          ),
                        ],
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
                                  /*
                                  // BOTON BLOQUEADO

                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text("Bloqueado"),
                                    trailing: Switch(
                                      value: swLocked,
                                      onChanged: (value) {
                                        setState(() {
                                          swLocked = value;
                                          if (value) {
                                            swPromocion = false;
                                          }
                                        });
                                        saveLocked();
                                      },
                                    ),
                                  ),

                                  const Divider(height: 15),
                                  */

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
                                    onChanged: swLocked
                                        ? null // ← Si está bloqueado, el switch queda desactivado
                                        : (value) {
                                            setState(() {
                                              swPromocion = value;
                                            });
                                          },
                                  ),

                                  // PRECIO
                                  TextFormField(
                                    controller: precioInput,
                                    enabled: !swLocked,
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
                                    enabled: !swLocked,
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
              _list_images.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_not_supported,
                              size: 80, color: Colors.grey),
                          SizedBox(height: 20),
                          Text(
                            "No hay imágenes",
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 10),
                          Text(
                            "Toma una foto con el ícono de cámara",
                            style:
                                TextStyle(fontSize: 14, color: Colors.black54),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _list_images.length,
                      itemBuilder: (context, index) {
                        return Card(
                          child: ListTile(
                            leading: GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => Dialog(
                                    backgroundColor: Colors.transparent,
                                    child: InteractiveViewer(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(
                                          _list_images[index]['url'],
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  _list_images[index]['url'],
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
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
                        onPressed: () async {
                          final confirm = await showConfirmDialog(context);
                          if (confirm) {
                            finalizeOrder();
                          }
                        },
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
