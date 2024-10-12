import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplicación Bluetooth con Flutter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BluetoothPage(),
    );
  }
}

class BluetoothPage extends StatefulWidget {
  @override
  _BluetoothPageState createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  static const platform = MethodChannel('com.example.bluetooth/channel');
  List<dynamic> devices = [];

  bool isLedOn = false;  // Variable para mantener el estado del LED 1
  bool isLed2On = false; // Variable para mantener el estado del LED 2
  bool isConnected = false;  // Variable para mantener el estado de conexión
  String password = "";  // Contraseña ingresada

  Future<void> _getPairedDevices() async {
    // Solicitar permisos
    if (await _requestPermissions()) {
      try {
        final List<dynamic> result =
            await platform.invokeMethod('getPairedDevices');
        setState(() {
          devices = result;
        });
      } on PlatformException catch (e) {
        print("Error al obtener dispositivos emparejados: ${e.message}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al obtener dispositivos: ${e.message}')),
        );
      }
    } else {
      print("Permisos denegados");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permisos de Bluetooth denegados')),
      );
    }
  }

  Future<void> _connectToDevice(String address) async {
    try {
      await platform.invokeMethod('connectToDevice', {'address': address});
      print("Conectado a $address");
      setState(() {
        isConnected = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Conectado a $address')),
      );
    } on PlatformException catch (e) {
      print("Error al conectar al dispositivo: ${e.message}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al conectar: ${e.message}')),
      );
    }
  }

  Future<void> _sendData(String data) async {
    try {
      await platform.invokeMethod('sendData', {'data': data});
      print("Datos enviados: $data");
    } on PlatformException catch (e) {
      print("Error al enviar datos: ${e.message}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar datos: ${e.message}')),
      );
    }
  }

  Future<bool> _requestPermissions() async {
    if (await Permission.bluetooth.isGranted &&
        await Permission.bluetoothConnect.isGranted) {
      return true;
    } else {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetooth,
        Permission.bluetoothConnect,
      ].request();
      return statuses[Permission.bluetooth]?.isGranted == true &&
          statuses[Permission.bluetoothConnect]?.isGranted == true;
    }
  }

  void _sendPassword() {
    if (password.isNotEmpty) {
      _sendData(password + "#");  // Enviar la contraseña seguida de #
    }
  }

  @override
  void initState() {
    super.initState();
    // Puedes descomentar la siguiente línea si deseas obtener los dispositivos emparejados al iniciar la app
    // _getPairedDevices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Casa Domótica'),
        centerTitle: true,
        actions: [
          Icon(
            isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
            color: Colors.white,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.bluetooth_searching),
            label: const Text('Buscar conexiones'),
            onPressed: _getPairedDevices,
          ),
          Expanded(
            child: ListView.builder(
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final device = devices[index] as Map<dynamic, dynamic>;
                return ListTile(
                  leading: const Icon(Icons.bluetooth),
                  title: Text(device['name'] ?? 'Sin nombre'),
                  subtitle: Text(device['address']),
                  onTap: () => _connectToDevice(device['address']),
                );
              },
            ),
          ),
          // Sección superior con los interruptores de los LEDs
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    isLedOn ? Icons.lightbulb : Icons.lightbulb_outline,
                    color: isLedOn ? Colors.blue : Colors.grey,
                  ),
                  title: const Text('Encender/Apagar Habitación 1'),
                  trailing: Switch(
                    value: isLedOn,
                    onChanged: isConnected
                        ? (value) {
                            setState(() {
                              isLedOn = value;
                            });
                            _sendData(isLedOn ? "1" : "0");
                          }
                        : null, // Deshabilita el interruptor si no está conectado
                  ),
                ),
                ListTile(
                  leading: Icon(
                    isLed2On ? Icons.lightbulb : Icons.lightbulb_outline,
                    color: isLed2On ? Colors.red : Colors.grey,
                  ),
                  title: const Text('Encender/Apagar Habitación 2'),
                  trailing: Switch(
                    value: isLed2On,
                    onChanged: isConnected
                        ? (value) {
                            setState(() {
                              isLed2On = value;
                            });
                            _sendData(isLed2On ? "2" : "3");
                          }
                        : null, // Deshabilita el interruptor si no está conectado
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),  // Añadir espacio entre los interruptores y la contraseña
          // Sección inferior con el icono de llave y el campo de texto
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.lock, size: 32), // Icono de llave
                const SizedBox(width: 16), // Espacio entre el icono y el campo de texto
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Ingrese la contraseña',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      password = value;
                    },
                  ),
                ),
                const SizedBox(width: 16), // Espacio entre el campo de texto y el botón
                IconButton(
                  icon: const Icon(Icons.send, size: 32),
                  onPressed: _sendPassword,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
