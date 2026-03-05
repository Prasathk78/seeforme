import 'dart:convert';
import 'package:http/http.dart' as http;

class BackendAPI {
  final String baseUrl = 'http://10.45.247.185:5000'; // Replace with your Flask server IP

  /// Sends the captured image to the backend and returns objects and caption.
  Future<Map<String, dynamic>> sendImage(String imagePath) async {
    try {
      // Prepare multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/predict'),
      );

      request.files.add(await http.MultipartFile.fromPath('file', imagePath));

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // Parse JSON response
        final Map<String, dynamic> data = json.decode(response.body);

        // Ensure safe defaults
        final List<String> objects =
            data['objects'] != null ? List<String>.from(data['objects']) : [];
        final String caption = data['caption'] ?? '';

        return {
          'objects': objects,
          'caption': caption,
        };
      } else {
        // Backend returned an error
        return {'objects': [], 'caption': 'Error: ${response.statusCode}'};
      }
    } catch (e) {
      // Network or parsing error
      return {'objects': [], 'caption': 'Error: $e'};
    }
  }
}
