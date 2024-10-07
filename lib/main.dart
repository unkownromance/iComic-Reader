import 'dart:io'; // 添加导入
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart'; // 添加文件选择器的包
import 'package:pdfx/pdfx.dart';
import 'package:epub_view/epub_view.dart'; // 导入 epub_view

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        //应用的主框架
        title: 'Comic Reader',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.lightBlue,
            brightness: Brightness.light,
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.lightBlue.shade700, // 设置 AppBar 颜色
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.lightBlue.shade600, // 按钮背景色为柔和的蓝色
              foregroundColor: Colors.white, // 按钮文本颜色
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30), // 按钮圆角
              ),
              textStyle: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              elevation: 5, // 按钮阴影效果
            ),
          ),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

//下面是添加“业务逻辑”的区域
class MyAppState extends ChangeNotifier {
  String? selectedFilePath; // 保存选中的文件路径
  String? selectedFileName; // 保存选中的文件名称

  // 创建一个历史记录列表，保存已选择的文件路径和名称
  List<Map<String, String>> fileHistory = [];

  // 处理文件选择的逻辑
  Future<void> pickFile() async {
    print("Picking a file...");
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'epub'], // 允许选择的文件类型
      );
      if (result != null && result.files.single.path != null) {
        selectedFilePath = result.files.single.path;
        // 保留文件名和扩展名
        selectedFileName = result.files.single.name; // 保存完整的文件名称（包括扩展名）
        print("Selected file: $selectedFilePath");

        // 将选中的文件添加到历史记录
        fileHistory.add({
          'name': selectedFileName!,
          'path': selectedFilePath!,
        });
        notifyListeners();
      } else {
        print("No file selected.");
      }
    } catch (e) {
      print("Error picking file: $e");
    }
  }

  // 清空文件历史记录的函数
  void clearFileHistory() {
    fileHistory.clear();
    notifyListeners(); // 通知界面更新
  }

  void deleteSelectedFiles(Set<int> selectedFiles) {
    // 删除选中的文件
    fileHistory.removeWhere(
        (file) => selectedFiles.contains(fileHistory.indexOf(file)));
    notifyListeners(); // 通知界面更新
  }
}

class MyHomePage extends StatefulWidget {
  //主页面
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget page;

    switch (_selectedIndex) {
      case 0:
        page = GeneratorPage();
        break;
      case 1:
        page = FavoritesPage();
        break;
      default:
        page = GeneratorPage();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comic Reader'),
      ),
      body: Center(
        child: page,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '首页',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.send),
            label: '传输',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        onTap: _onItemTapped,

        // 通过设置字体样式来更改标签的字体
        selectedLabelStyle: TextStyle(
          fontSize: 16, // 设置选中时的字体大小
          fontWeight: FontWeight.bold, // 设置字体加粗
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 14, // 设置未选中时的字体大小
          fontWeight: FontWeight.normal, // 普通字体
        ),
      ),
    );
  }
}

class GeneratorPage extends StatefulWidget {
  @override
  _GeneratorPageState createState() => _GeneratorPageState();
}

class _GeneratorPageState extends State<GeneratorPage> {
  bool isEditing = false; // 是否处于编辑模式
  Set<int> selectedFiles = {}; // 记录选中的文件索引

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlue[100], // 设置浅色工具栏
        actions: [
          // 删除按钮：只有当有文件时才显示删除按钮
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: appState.fileHistory.isNotEmpty
                ? () {
                    _showDeleteConfirmationDialog(context, appState);
                  }
                : null, // 如果没有文件，禁用按钮
          ),
          IconButton(
            icon: Icon(isEditing ? Icons.done : Icons.edit),
            onPressed: appState.fileHistory.isNotEmpty
                ? () {
                    setState(() {
                      isEditing = !isEditing; // 切换编辑模式
                      if (!isEditing) {
                        selectedFiles.clear(); // 退出编辑模式时清空选择
                      }
                    });
                  }
                : null, // 如果没有文件，禁用按钮
          ),
        ],
      ),
      body: Center(
        child: appState.fileHistory.isEmpty
            ? Text(
                '还没有漫画？请先上传漫画',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: appState.fileHistory.length,
                      itemBuilder: (context, index) {
                        var file = appState.fileHistory[index];
                        bool isSelected = selectedFiles.contains(index);

                        return ListTile(
                          title: Text(file['name']!),
                          onTap: () {
                            if (isEditing) {
                              // 处于编辑模式时点击选择文件
                              setState(() {
                                if (isSelected) {
                                  selectedFiles.remove(index);
                                } else {
                                  selectedFiles.add(index);
                                }
                              });
                            } else {
                              // 非编辑模式下打开文件
                              if (file['name']!.endsWith('.pdf')) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        PdfViewerPage(filePath: file['path']!),
                                  ),
                                );
                              } else if (file['name']!.endsWith('.epub')) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        EpubViewerPage(filePath: file['path']!),
                                  ),
                                );
                              }
                            }
                          },
                          leading: isEditing
                              ? Checkbox(
                                  value: isSelected,
                                  onChanged: (bool? checked) {
                                    setState(() {
                                      if (checked!) {
                                        selectedFiles.add(index);
                                      } else {
                                        selectedFiles.remove(index);
                                      }
                                    });
                                  },
                                )
                              : null,
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // 显示删除确认对话框
  void _showDeleteConfirmationDialog(
      BuildContext context, MyAppState appState) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("删除选中的文件"),
          content: Text("确定要删除选中的文件吗？"),
          actions: [
            TextButton(
              child: Text("取消"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("确定"),
              onPressed: () {
                appState.deleteSelectedFiles(selectedFiles); // 删除选中的文件
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

class FavoritesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    return Center(
      child: ElevatedButton(
        onPressed: () {
          appState.pickFile(); // 点击按钮时调用选择文件的方法
        },
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(
              horizontal: 50, vertical: 20), // 调整按钮的内部填充，使其更大
          textStyle:
              TextStyle(fontSize: 20, fontWeight: FontWeight.bold), // 设置按钮文本的样式
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30), // 让按钮变得圆润
          ),
          backgroundColor: Color(0xFFADD8E6), // 设置柔和的浅蓝色背景颜色
          foregroundColor: Colors.white, // 设置按钮的文本颜色
          shadowColor: Color(0xFFB0C4DE), // 设置阴影颜色为淡蓝色
          elevation: 5, // 增加阴影效果
        ),
        child: Text('上传文件'),
      ),
    );
  }
}

class PdfViewerPage extends StatelessWidget {
  final String filePath;

  const PdfViewerPage({super.key, required this.filePath});

  @override
  Widget build(BuildContext context) {
    try {
      // 创建 PdfController 来控制 PDF 文档
      final PdfController pdfController = PdfController(
        document: PdfDocument.openFile(filePath), // 使用 pdfx 打开文件
      );

      return Scaffold(
        appBar: AppBar(
          title: Text('PDF Viewer'),
        ),
        body: Column(
          children: [
            Expanded(
              child: PdfView(
                controller: pdfController, // 传递 controller
                scrollDirection: Axis.vertical,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () {
                    pdfController.previousPage(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeIn,
                    );
                  },
                  child: Text('上一页'),
                ),
                ElevatedButton(
                  onPressed: () {
                    pdfController.nextPage(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeIn,
                    );
                  },
                  child: Text('下一页'),
                ),
              ],
            )
          ],
        ),
      );
    } catch (e) {
      print('Error opening PDF file: $e'); // 捕获异常
      return Scaffold(
        appBar: AppBar(
          title: Text('PDF Viewer'),
        ),
        body: Center(
          child: Text('无法打开 PDF 文件: $e'), // 显示错误信息
        ),
      );
    }
  }
}

class EpubViewerPage extends StatefulWidget {
  final String filePath;

  const EpubViewerPage({super.key, required this.filePath});

  @override
  _EpubViewerPageState createState() => _EpubViewerPageState();
}

class _EpubViewerPageState extends State<EpubViewerPage> {
  late EpubController _epubController;

  @override
  void initState() {
    super.initState();
    try {
      _epubController = EpubController(
        document: EpubDocument.openFile(File(widget.filePath)),
      );
    } catch (e) {
      print('Error loading EPUB file: $e');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: EpubViewActualChapter(
            controller: _epubController,
            builder: (chapterValue) => Text(
              'Chapter: ${chapterValue?.chapter?.Title?.replaceAll('\n', '').trim() ?? ''}',
              textAlign: TextAlign.start,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.exit_to_app),
              onPressed: () {
                Navigator.pop(context); // 返回上一个页面
              },
            ),
          ],
        ),
        drawer: Drawer(
          child: EpubViewTableOfContents(
            controller: _epubController,
          ),
        ),
        body: EpubView(
          controller: _epubController,
          onExternalLinkPressed: (href) {},
          onDocumentLoaded: (document) {
            print('Document loaded: $document');
          },
          onChapterChanged: (chapter) {
            print('Chapter changed: $chapter');
          },
          onDocumentError: (error) {
            print('Document error: $error');
          },
        ),
      );
}
