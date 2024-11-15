import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:lottie/lottie.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter OCR Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'OCR Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  XFile? pickedImage;
  String resultText = 'No text recognized yet.';

  Future<void> pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: source);
      if (image != null) {
        final text = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecognitionPage(image: image),
          ),
        ) as String;
        setState(() {
          pickedImage = image;
          resultText = text;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Click the button to scan the text:'),
            const SizedBox(height: 16.0),
            pickedImage == null
                ? const Text('No image selected yet.')
                : Image.file(
                    File(pickedImage!.path),
                    height: 200,
                    width: 200,
                  ),
            const SizedBox(height: 16.0),
            Text(
              resultText,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
            ),
            builder: (context) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.camera_alt_outlined),
                    title: const Text('Camera'),
                    onTap: () async {
                      Navigator.pop(context);
                      await pickImage(ImageSource.camera);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_library_outlined),
                    title: const Text('Gallery'),
                    onTap: () async {
                      Navigator.pop(context);
                      await pickImage(ImageSource.gallery);
                    },
                  ),
                ],
              );
            },
          );
        },
        child: const Icon(Icons.camera_alt_outlined),
      ),
    );
  }
}

class RecognitionPage extends StatefulWidget {
  final XFile image;

  const RecognitionPage({super.key, required this.image});

  @override
  State<RecognitionPage> createState() => _RecognitionPageState();
}

class _RecognitionPageState extends State<RecognitionPage> {
  bool isScanning = false;
  String scannedText = '';
  bool isList = false;

  Future<void> performOCR(XFile image) async {
    setState(() {
      isScanning = true;
    });

    final inputImage = InputImage.fromFilePath(image.path);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final recognizedText = await textRecognizer.processImage(inputImage);
      scannedText = '';
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          scannedText += isList ? '${line.text}\n' : '${line.text} ';
        }
      }
    } catch (e) {
      debugPrint('Error during text recognition: $e');
      scannedText = 'Error recognizing text.';
    } finally {
      await textRecognizer.close();
      setState(() {
        isScanning = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    performOCR(widget.image);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OCR Result')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 300,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Image.file(File(widget.image.path), fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 16.0),
            CheckboxListTile(
              title: const Text('Is there a list in the image?'),
              value: isList,
              onChanged: (value) {
                setState(() {
                  isList = value!;
                  performOCR(widget.image);
                });
              },
            ),
            const Divider(),
            isScanning
                ? Center(
                    child: Lottie.asset(
                      'assets/scan_img.json',
                      height: 100,
                      width: 100,
                    ),
                  )
                : Text(
                    scannedText,
                    style: const TextStyle(fontSize: 16.0),
                  ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pop(
              context, scannedText.isEmpty ? 'No text detected.' : scannedText);
        },
        label: const Text('Done'),
        icon: const Icon(Icons.check),
      ),
    );
  }
}
