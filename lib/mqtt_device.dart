import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import 'package:http/http.dart' as http;
// import 'package:upnp/upnp.dart';
import 'package:web_socket_channel/io.dart';

import 'key_codes.dart';

final int kConnectionTimeout = 60;
final kKeyDelay = 200;
final kWakeOnLanDelay = 5000;
final kUpnpTimeout = 1000;
final pubTopic = 'IR/command';



// import wol from 'wake_on_lan'
// import WebSocket from 'ws'
// import request from 'request-promise'
// import SSDP from 'node-ssdp'

// import { getLogger } from 'appium-logger'
// import { KEY_CODES } from './constants'

// const log = getLogger('SamsungRemote')

// const CONNECTION_TIMEOUT = 60000
// const KEY_DELAY = 200
// const WAKE_ON_LAN_DELAY = 5000
// const UPNP_TIMEOUT = 1000

class SamsungSmartTV {
  final client = MqttServerClient('192.168.70.233', 'Android');
  // final List<Map<String, dynamic>> services;
  // final String host;
  // final String mac;
  // final String api;
  // final String wsapi;
  bool isConnected = false;
  String token;
  dynamic info;
  IOWebSocketChannel ws;
  Timer timer;

  // SamsungSmartTV({
  //   this.host,
  //   this.mac,
  // })  : api = "http://$host:8001/api/v2/",
  //       wsapi = "wss://$host:8002/api/v2/",
  //       services = [];

  SamsungSmartTV() {

      /// Set logging on if needed, defaults to off
      this.client.logging(on: false);

      /// If you intend to use a keep alive you must set it here otherwise keep alive will be disabled.
      this.client.keepAlivePeriod = 20;

      /// Add the unsolicited disconnection callback
      this.client.onDisconnected = onDisconnected;

      /// Add the successful connection callback
      this.client.onConnected = onConnected;

  }

  /**
     * add UPNP service
     * @param [Object] service  UPNP service description
     */
  // addService(service) {
  //   this.services.add(service);
  // }

  connect({appName = 'DartSamsungSmartTVDriver'}) async {
    var completer = new Completer();

    if (this.isConnected) {
      return;
    }

      /// Connect the client, any errors here are communicated by raising of the appropriate exception. Note
      /// in some circumstances the broker will just disconnect us, see the spec about this, we however will
      /// never send malformed messages.
      try {
        await client.connect();
      } on NoConnectionException catch (e) {
        // Raised by the client when connection fails.
        print('EXAMPLE::client exception - $e');
        client.disconnect();
      } on SocketException catch (e) {
        // Raised by the socket layer
        print('EXAMPLE::socket exception - $e');
        client.disconnect();
      }

      /// Check we are connected
      if (client.connectionStatus.state == MqttConnectionState.connected) {
        print('EXAMPLE::Mosquitto client connected');
      } else {
        /// Use status here rather than state if you also want the broker return code.
        print(
            'EXAMPLE::ERROR Mosquitto client connection failed - disconnecting, status is ${client.connectionStatus}');
        client.disconnect();
        exit(-1);
      }


    return completer.future;
  }

  // request TV info like udid or model name

  // Future<http.Response> getDeviceInfo() async {
  //   print("Get device info from $api");
  //   return http.get(this.api);
  // }

  // disconnect from device

  // disconnect() {
  //   // ws.sink.close(status.goingAway);
  //   ws.sink.close();
  // }

  /// The unsolicited disconnect callback
  onDisconnected() {
    print('EXAMPLE::OnDisconnected client callback - Client disconnection');
    if (client.connectionStatus.disconnectionOrigin ==
        MqttDisconnectionOrigin.solicited) {
      print('EXAMPLE::OnDisconnected callback is solicited, this is correct');
    }
    exit(-1);
  }

  /// The successful connect callback
  void onConnected() {
    print(
        'EXAMPLE::OnConnected client callback - Client connection was sucessful');
        this.isConnected = true;
  }

  sendKey(KEY_CODES key) async {
    if (!isConnected) {
      throw ('Not connected to device. Call `tv.connect()` first!');
    }

    final builder = MqttClientPayloadBuilder();
    
    // Original sendkey code bellow
    print("Send key command  ${key.toString().split('.').last}");
    final data = json.encode({
      "method": 'ms.remote.control',
      "params": {
        "Cmd": 'Click',
        "DataOfCmd": key.toString().split('.').last,
        "Option": false,
        "TypeOfRemote": 'SendRemoteKey',
      }
    });
    builder.addString(data);
    /// Publish it
    print('EXAMPLE::Publishing our topic');
    client.publishMessage(pubTopic, MqttQos.exactlyOnce, builder.payload);

    // ws.sink.add(data);

    // add a delay so TV has time to execute
    // Timer(Duration(seconds: kConnectionTimeout), () {
    //   throw ('Unable to connect to TV: timeout');
    // });

    return Future.delayed(Duration(milliseconds: kKeyDelay));
  }

  //static method to discover Samsung Smart TVs in the network using the UPNP protocol

  // static discover() async {
  //   var completer = new Completer();

  //   final client = DeviceDiscoverer();
  //   final List<SamsungSmartTV> tvs = [];

  //   await client.start(ipv6: false);

  //   client.quickDiscoverClients().listen((client) async {
  //     RegExp re = RegExp(r'^.*?Samsung.+UPnP.+SDK\/1\.0$');

  //     //ignore other devices
  //     if (!re.hasMatch(client.server)) {
  //       return;
  //     }
  //     try {
  //       final device = await client.getDevice();

  //       Uri locaion = Uri.parse(client.location);

  //       final deviceExists = tvs.firstWhere((tv) => tv.host == locaion.host, orElse: () => null);

  //       if (deviceExists == null) {
  //         print("Found ${device.friendlyName} on IP ${locaion.host}");
  //         final tv = SamsungSmartTV(host: locaion.host);
  //         tv.addService({"location": client.location, "server": client.server, "st": client.st, "usn": client.usn});
  //         tvs.add(tv);
  //       }
  //     } catch (e, stack) {
  //       print("ERROR: $e - ${client.location}");
  //       print(stack);
  //     }
  //   }).onDone(() {
  //     if (tvs.isEmpty) {
  //       completer.completeError("No Samsung TVs found. Make sure the UPNP protocol is enabled in your network.");
  //     }
  //     completer.complete(tvs.first);
  //   });

  //   return completer.future;
  // }
}
