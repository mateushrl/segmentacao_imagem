import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
    FilePickerResult? imagem;
  FilePickerResult? background;

  Future<void> _loadImage() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
    );
    setState(() {
      imagem = result;
    });
  }

  Future<void> _loadBackground() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
    );
    setState(() {
      background = result;
    });
  }

  Future<void> _sendImagesToServer() async {
    if (imagem != null && background != null) {
      try {
        // Converter as imagens para base64
        String imagemBase64 = base64Encode(imagem!.files.first.bytes!);
        String backgroundBase64 = base64Encode(background!.files.first.bytes!);

        // Construir o corpo da solicitação
        Map<String, String> body = {
          "imagem_original_base64": imagemBase64,
          "imagem_background_base64": backgroundBase64,
        };

        // Fazer a solicitação POST para a API local
        var response = await http.post(
          Uri.parse("http://127.0.0.1:5000/processar_imagem"),
          body: body,
        );

        // Converter a resposta da API para um mapa
        final Map<String, dynamic> responseBody = jsonDecode(response.body);

        // Extrair a imagem base64 do mapa
        final String imagemBase64Resposta = responseBody['imagem_base64'];

        // Decodificar a imagem base64 para dados binários
        Uint8List decodedBytes = base64Decode(imagemBase64Resposta);

        // Exibir a imagem na tela
        // ignore: use_build_context_synchronously
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              content: Image.memory(decodedBytes),
            );
          },
        );
      } catch (e) {
        print("Erro ao enviar imagens para a API: $e");
      }
    } else {
      print("Carregue as imagens antes de enviar para a API.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Segmentation'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _loadImage,
                child: Container(
                  color: Colors.blue,
                  child: imagem?.files.isNotEmpty ?? false
                      ? Image.memory(
                          imagem!.files.first.bytes!,
                          fit: BoxFit.cover,
                        )
                      : const Text(
                          "Carregar imagem",
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 20),
              GestureDetector(
                onTap: _loadBackground,
                child: Container(
                  color: Colors.blue,
                  child: background?.files.isNotEmpty ?? false
                      ? Image.memory(
                          background!.files.first.bytes!,
                          fit: BoxFit.cover,
                        )
                      : const Text(
                          "Carregar Background",
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _sendImagesToServer,
                child: Text("Enviar Imagens para a API"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}