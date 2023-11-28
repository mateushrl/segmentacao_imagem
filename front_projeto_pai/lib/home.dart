import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
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
        String imagemBase64 = base64Encode(imagem!.files.first.bytes!);
        String backgroundBase64 = base64Encode(background!.files.first.bytes!);

        Map<String, String> body = {
          "imagem_original_base64": imagemBase64,
          "imagem_background_base64": backgroundBase64,
        };

        var response = await http.post(
          Uri.parse("http://127.0.0.1:5000/processar_imagem"),
          body: body,
        );

        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        final String imagemBase64Resposta = responseBody['imagem_base64'];

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
      bottomNavigationBar: Container(
        alignment: Alignment.centerLeft,
        height: 50,
        color: const Color.fromARGB(255, 175, 157, 1),
        child: const Text(
          "Desenvolvido por: Mateus e Mikael",
          style: TextStyle(
            fontSize: 15,
            color: Colors.white,
          ),
        ),
      ),
      appBar: AppBar(
        toolbarHeight: 70,
        title: const Text(
          'Segmentação de Imagem',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color.fromARGB(255, 255, 230, 0),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(64, 35, 64, 36),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    GestureDetector(
                      onTap: _loadImage,
                      child: Container(
                        width: 300, // Largura desejada
                        height: 200, // Altura desejada
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 5,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
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
                    ),
                    const Text(
                      "+",
                      style: TextStyle(fontSize: 64),
                    ),
                    GestureDetector(
                      onTap: _loadBackground,
                      child: Container(
                        width: 300, // Largura desejada
                        height: 200, // Altura desejada
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 5,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
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
                    )
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(64, 36, 64, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: _sendImagesToServer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            elevation: 5, // Altura da elevação
                            padding: const EdgeInsets.symmetric(
                                vertical: 32,
                                horizontal:
                                    64), // Ajuste o padding conforme necessário
                          ),
                          child: const Text(
                            "Enviar Imagens para a API",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
