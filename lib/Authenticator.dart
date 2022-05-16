import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'dart:io';
import 'package:googleapis/drive/v3.dart' as ga;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:http/io_client.dart';
import 'package:google_sign_in/google_sign_in.dart';

const _clientId = "1062142738282-4nhn5q5kii6dc8896tgbcua8tvnmusgi.apps.googleusercontent.com";
const _scopes = [ga.DriveApi.driveScope];

class SecureStorage {
  final storage = FlutterSecureStorage();

  //Save Credentials
  Future saveCredentials(AccessToken token, String refreshToken) async {
    print(token.expiry.toIso8601String());
    await storage.write(key: "type", value: token.type);
    await storage.write(key: "data", value: token.data);
    await storage.write(key: "expiry", value: token.expiry.toString());
    await storage.write(key: "refreshToken", value: refreshToken);
  }

  //Get Saved Credentials
  Future<Map<String, dynamic>?> getCredentials() async {
    var result = await storage.readAll();
    if (result.isEmpty) return null;
    return result;
  }

  //Clear Saved Credentials
  Future clear() {
    return storage.deleteAll();
  }
}

class GoogleDrive {
  final storage = SecureStorage();
  //Get Authenticated Http Client
  Future<http.Client> getHttpClient() async {
    //Get Credentials
    var credentials = await storage.getCredentials();
    if (credentials == null) {
      //Needs user authentication
      var authClient = await clientViaUserConsent(
          ClientId(_clientId),_scopes, (url) {
        //Open Url in Browser
        launchUrlString(url);
      });
      //Save Credentials
      await storage.saveCredentials(authClient.credentials.accessToken,
          authClient.credentials.refreshToken!);
      return authClient;
    } else {
      print(credentials["expiry"]);
      //Already authenticated
      return authenticatedClient(
          http.Client(),
          AccessCredentials(
              AccessToken(credentials["type"], credentials["data"],
                  DateTime.tryParse(credentials["expiry"])!),
              credentials["refreshToken"],
              _scopes));
    }
  }

  // check if the directory folder is already available in drive , if available return its id
  // if not available create a folder in drive and return id
  // if not able to create id then it means user authentication has failed
  Future<String?> _getFolderId(ga.DriveApi driveApi) async {
    final mimeType = "application/vnd.google-apps.folder";
    String folderName = "mementoBackup";

    try {
      final found = await driveApi.files.list(
        q: "mimeType = '$mimeType' and name = '$folderName'",
        $fields: "files(id, name)",
      );
      final files = found.files;
      if (files == null) {
        print("Sign-in first Error");
        return null;
      }

      // The folder already exists
      if (files.isNotEmpty) {
        return files.first.id;
      }

      // Create a folder
      ga.File folder = ga.File();
      folder.name = folderName;
      folder.mimeType = mimeType;
      final folderCreation = await driveApi.files.create(folder);
      print("Folder ID: ${folderCreation.id}");

      return folderCreation.id;
    } catch (e) {
      print(e);
      return null;
    }
  }


  Future<void> uploadFileToGoogleDrive(File file) async {
    var client = await getHttpClient();
    var drive = ga.DriveApi(client);
    String? folderId =  await _getFolderId(drive);
    if(folderId == null){
      print("Sign-in first Error");
    }else {
      ga.File fileToUpload = ga.File();
      fileToUpload.parents = [folderId];
      fileToUpload.name = p.basename(file.absolute.path);
      var response = await drive.files.create(
        fileToUpload,
        uploadMedia: ga.Media(file.openRead(), file.lengthSync()),
      );
      print(response);
    }

  }

  Future<void> downloadGoogleDriveFile(String fName, String gdID) async {
    var client = await getHttpClient();
    var drive = ga.DriveApi(client);
    ga.Media file = (await drive.files.get(gdID, downloadOptions: ga.DownloadOptions.fullMedia)) as ga.Media;
    print(file.stream);

    final directory = await getExternalStorageDirectory();
    print(directory);
    final saveFile = File('$directory/${DateTime.now().millisecondsSinceEpoch}$fName');
    List<int> dataStore = [];
    file.stream.listen((data) {
      print("DataReceived: ${data.length}");
      dataStore.insertAll(dataStore.length, data);
    }, onDone: () {
      print("Task Done");
      saveFile.writeAsBytes(dataStore);
      print("File saved at ${saveFile.path}");
    }, onError: (error) {
      print("Some Error");
    });
  }

}

/*
class GoogleHttpClient extends IOClient {
  Map<String, String> _headers;
  GoogleHttpClient(this._headers) : super();
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      super.send(request..headers.addAll(_headers));
  @override
  Future<http.Response> head(Object url, {Map<String, String> headers}) =>
      super.head(url, headers: headers..addAll(_headers));
}

class GoogleDrive {
  _uploadFileToGoogleDrive() async {
    var client = GoogleHttpClient(await googleSignInAccount.authHeaders);
    var drive = ga.DriveApi(client);
    ga.File fileToUpload = ga.File();
    var file = await FilePicker.getFile();
    fileToUpload.parents = ["appDataFolder"];
    fileToUpload.name = path.basename(file.absolute.path);
    var response = await drive.files.create(
      fileToUpload,
      uploadMedia: ga.Media(file.openRead(), file.lengthSync()),
    );
    print(response);
  }
}
*/
