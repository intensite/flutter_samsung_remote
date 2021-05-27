import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

// import 'package:http/http.dart' as http;
// import 'package:upnp/upnp.dart';
// import 'package:web_socket_channel/io.dart';

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
  // IOWebSocketChannel ws;
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
    print("Send key command ${key} ${key.toString().split('.').last}");


    var payload = preparePayload(key);
    if(payload == null) {
        return;
    }

    final data = json.encode(payload);

    // final data = json.encode({
    //   "method": 'ms.remote.control',
    //   "params": {
    //     "Cmd": 'Click',
    //     "DataOfCmd": key.toString().split('.').last,
    //     "Option": false,
    //     "TypeOfRemote": 'SendRemoteKey',
    //   }
    // });
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

  /**
   * Used to convert the string keycode in the proper MQTT Message with actual hexadecimal IR Keycodes sequence
   * Some operation requires multiple IR Keycodes and those are packed in an array.
   */
  preparePayload(KEY_CODES key) {
    // var keyName = key.toString().split('.').last;
    List<Map<String, Object>> payload;

    const DEVICE_TYPE_SAMSUNG = 7;
    const DEVICE_TYPE_BELL = 21;

    switch (key) {
      case KEY_CODES.KEY_POWER:
        {
         payload =  [
            {"type": DEVICE_TYPE_SAMSUNG, "value": samsungCodeList.firstWhere((item) => item["key"] == 'POWER')["code"], "repeat": 2},
            {"type": DEVICE_TYPE_BELL, "value": bellCodeList.firstWhere((item) => item["key"] == 'POWER')["code"], "repeat": 2}
          ];
        }
        break;
      case KEY_CODES.KEY_VOLUP:
        {
          payload = [ {"type": DEVICE_TYPE_SAMSUNG, "value":  samsungCodeList.firstWhere((item) => item["key"] == 'VOL+')["code"], "repeat": 1} ];
        }
        break;
      case KEY_CODES.KEY_VOLDOWN:
        {
          payload = [ {"type": DEVICE_TYPE_SAMSUNG, "value":  samsungCodeList.firstWhere((item) => item["key"] == 'VOL-')["code"], "repeat": 1} ];
        }
        break;
      case KEY_CODES.KEY_MUTE:
        {
          payload = [ {"type": DEVICE_TYPE_SAMSUNG, "value":  samsungCodeList.firstWhere((item) => item["key"] == 'MUTE')["code"], "repeat": 1} ];
        }
        break;
      case KEY_CODES.KEY_CHUP:
        {
          payload = [ {"type": DEVICE_TYPE_BELL, "value":  bellCodeList.firstWhere((item) => item["key"] == 'CHANNEL+')["code"], "repeat": 2} ];
        }
        break;
      case KEY_CODES.KEY_CHDOWN:
        {
          payload = [ {"type": DEVICE_TYPE_BELL, "value":  bellCodeList.firstWhere((item) => item["key"] == 'CHANNEL-')["code"], "repeat": 2} ];
        }
        break;
      case KEY_CODES.KEY_PVR:
        {
          payload = [ {"type": DEVICE_TYPE_BELL, "value":  bellCodeList.firstWhere((item) => item["key"] == 'PVR')["code"], "repeat": 1} ];
        }
        break;
      case KEY_CODES.KEY_MORE:
        {
          payload = [ {"type": DEVICE_TYPE_BELL, "value":  bellCodeList.firstWhere((item) => item["key"] == 'INFO')["code"], "repeat": 1} ];
        }
        break;




      case KEY_CODES.KEY_1:
        {
          payload = [ {"type": DEVICE_TYPE_BELL, "value":  bellCodeList.firstWhere((item) => item["key"] == '1')["code"], "repeat": 1} ];
        }
        break;
      case KEY_CODES.KEY_2:
        {
          payload = [ {"type": DEVICE_TYPE_BELL, "value":  bellCodeList.firstWhere((item) => item["key"] == '2')["code"], "repeat": 1} ];
        }
        break;
      case KEY_CODES.KEY_3:
        {
          payload = [ {"type": DEVICE_TYPE_BELL, "value":  bellCodeList.firstWhere((item) => item["key"] == '3')["code"], "repeat": 1} ];
        }
        break;
      case KEY_CODES.KEY_4:
        {
          payload = [ {"type": DEVICE_TYPE_BELL, "value":  bellCodeList.firstWhere((item) => item["key"] == '4')["code"], "repeat": 1} ];
        }
        break;
      case KEY_CODES.KEY_5:
        {
          payload = [ {"type": DEVICE_TYPE_BELL, "value":  bellCodeList.firstWhere((item) => item["key"] == '5')["code"], "repeat": 1} ];
        }
        break;
      case KEY_CODES.KEY_6:
        {
          payload = [ {"type": DEVICE_TYPE_BELL, "value":  bellCodeList.firstWhere((item) => item["key"] == '6')["code"], "repeat": 1} ];
        }
        break;
      case KEY_CODES.KEY_7:
        {
          payload = [ {"type": DEVICE_TYPE_BELL, "value":  bellCodeList.firstWhere((item) => item["key"] == '7')["code"], "repeat": 1} ];
        }
        break;
      case KEY_CODES.KEY_8:
        {
          payload = [ {"type": DEVICE_TYPE_BELL, "value":  bellCodeList.firstWhere((item) => item["key"] == '8')["code"], "repeat": 1} ];
        }
        break;
      case KEY_CODES.KEY_9:
        {
          payload = [ {"type": DEVICE_TYPE_BELL, "value":  bellCodeList.firstWhere((item) => item["key"] == '9')["code"], "repeat": 1} ];
        }
        break;
      case KEY_CODES.KEY_0:
        {
          payload = [ {"type": DEVICE_TYPE_BELL, "value":  bellCodeList.firstWhere((item) => item["key"] == '0')["code"], "repeat": 1} ];
        }
        break;
      case KEY_CODES.KEY_LAST:
        {
          payload = [ {"type": DEVICE_TYPE_BELL, "value":  bellCodeList.firstWhere((item) => item["key"] == 'LAST')["code"], "repeat": 1} ];
        }
        break;
      case KEY_CODES.KEY_GUIDE:
        {
          payload = [ {"type": DEVICE_TYPE_BELL, "value":  bellCodeList.firstWhere((item) => item["key"] == 'GUIDE')["code"], "repeat": 2} ];
        }
        break;

      case KEY_CODES.KEY_REWIND:
        {
          payload = [ {"type": DEVICE_TYPE_BELL, "value":  bellCodeList.firstWhere((item) => item["key"] == 'SKIP_BACK')["code"], "repeat": 1} ];
        }
        break;
      case KEY_CODES.KEY_REC:
        {
          payload = [ {"type": DEVICE_TYPE_BELL, "value":  bellCodeList.firstWhere((item) => item["key"] == 'RECORD')["code"], "repeat": 1} ];
        }
        break;
      case KEY_CODES.KEY_PLAY:
      case KEY_CODES.KEY_PAUSE:
        {
          payload = [ {"type": DEVICE_TYPE_BELL, "value":  bellCodeList.firstWhere((item) => item["key"] == 'PLAY_PAUSE')["code"], "repeat": 1} ];
        }
        break;
      case KEY_CODES.KEY_STOP:
        {
          payload = [ {"type": DEVICE_TYPE_BELL, "value":  bellCodeList.firstWhere((item) => item["key"] == 'STOP')["code"], "repeat": 1} ];
        }
        break;
      case KEY_CODES.KEY_FF:
        {
          payload = [ {"type": DEVICE_TYPE_BELL, "value":  bellCodeList.firstWhere((item) => item["key"] == 'SKIP_FWD')["code"], "repeat": 1} ];
        }
        break;


      case KEY_CODES.KEY_APP_LIST:
        {
          payload = [ {"type": DEVICE_TYPE_BELL, "value":  bellCodeList.firstWhere((item) => item["key"] == 'APPS')["code"], "repeat": 1} ];
        }
        break;
      case KEY_CODES.KEY_SOURCE:
        {
          payload = [ {"type": DEVICE_TYPE_SAMSUNG, "value":  samsungCodeList.firstWhere((item) => item["key"] == 'SOURCE')["code"], "repeat": 1} ];
        }
        break;
      case KEY_CODES.KEY_UP:
        {
          payload = [ {"type": DEVICE_TYPE_BELL, "value":  bellCodeList.firstWhere((item) => item["key"] == 'UP')["code"], "repeat": 1} ];
        }
        break;
      case KEY_CODES.KEY_DOWN:
        {
          payload = [ {"type": DEVICE_TYPE_BELL, "value":  bellCodeList.firstWhere((item) => item["key"] == 'DOWN')["code"], "repeat": 1} ];
        }
        break;
      case KEY_CODES.KEY_LEFT:
        {
          payload = [ {"type": DEVICE_TYPE_BELL, "value":  bellCodeList.firstWhere((item) => item["key"] == 'LEFT')["code"], "repeat": 1} ];
        }
        break;
      case KEY_CODES.KEY_RIGHT:
        {
          payload = [ {"type": DEVICE_TYPE_BELL, "value":  bellCodeList.firstWhere((item) => item["key"] == 'RIGHT')["code"], "repeat": 1} ];
        }
        break;
      case KEY_CODES.KEY_ENTER:
        {
          payload = [ {"type": DEVICE_TYPE_BELL, "value":  bellCodeList.firstWhere((item) => item["key"] == 'SELECT')["code"], "repeat": 1} ];
        }
        break;
      case KEY_CODES.KEY_RETURN:
      case KEY_CODES.KEY_EXT41:
        {
          payload = [ {"type": DEVICE_TYPE_BELL, "value":  bellCodeList.firstWhere((item) => item["key"] == 'BACK_EXIT')["code"], "repeat": 1} ];
        }
        break;
      default:
        {
          //statements;
          payload = null;

        }
        break;
    }

    return payload;
  }
}
