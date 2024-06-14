* reads the specified number of bytes from a TCP socket
<?code-excerpt "readme_excerpts.dart (Write)"?>

* for client
```dart

import 'dart:io';
import 'package:future_soket/future_soket.dart';

void main(List<String> arguments) async {
  final soket = FutureSoket();
  await soket.connect(InternetAddress("127.0.0.1"), 8855, Duration(seconds: 1));

  final buf1 = await soket.read(9);
  final buf2 = await soket.read(8);

}
```
* for server:
```dart

import 'dart:io';
import 'package:future_soket/future_soket.dart';

void main(List<String> arguments) async {
  final server = await ServerSocket.bind("127.0.0.1", 7777);
 
  await for (var soket in server) {
    final fSoket = FutureSoket.fromSoket(soket);
    final buf1 = await fSoket.read(55);
  }
}
```
# future_soket
