import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Analisador de Texto",
      theme: ThemeData(
        primarySwatch: Colors.green, 
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const TelaLogin(),
    );
  }
}

// banco de dados simulado
class UserDatabase {
  static final UserDatabase _instance = UserDatabase._internal();
  factory UserDatabase() => _instance;
  UserDatabase._internal();

  final List<Map<String, dynamic>> _users = [];

  Future<int> insertUser(Map<String, dynamic> user) async {
    // Verificar se email já existe
    if (_users.any((u) => u['email'] == user['email'])) {
      throw Exception('E-mail já cadastrado');
    }

    // Verificar se CPF já existe
    if (_users.any((u) => u['cpf'] == user['cpf'])) {
      throw Exception('CPF já cadastrado');
    }

    final newUser = {...user, 'id': DateTime.now().millisecondsSinceEpoch};

    _users.add(newUser);
    return 1;
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      return _users.firstWhere((user) => user['email'] == email);
    } catch (e) {
      return null;
    }
  }

  Future<bool> validateLogin(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final user = await getUserByEmail(email);
    return user != null && user['senha'] == password;
  }
}

class CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String newText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (newText.length > 9) {
      newText =
          '${newText.substring(0, 3)}.${newText.substring(3, 6)}.${newText.substring(6, 9)}-${newText.substring(9, newText.length > 11 ? 11 : newText.length)}';
    } else if (newText.length > 6) {
      newText =
          '${newText.substring(0, 3)}.${newText.substring(3, 6)}.${newText.substring(6)}';
    } else if (newText.length > 3) {
      newText = '${newText.substring(0, 3)}.${newText.substring(3)}';
    }

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class DataInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String newText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (newText.length > 4) {
      newText =
          '${newText.substring(0, 2)}/${newText.substring(2, 4)}/${newText.substring(4, newText.length > 8 ? 8 : newText.length)}';
    } else if (newText.length > 2) {
      newText = '${newText.substring(0, 2)}/${newText.substring(2)}';
    }

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

//  TELA DE LOGIN 
class TelaLogin extends StatefulWidget {
  const TelaLogin({super.key});

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final UserDatabase _database = UserDatabase();
  bool _senhaVisible = false;
  bool _isLoading = false;
  Future<void> _fazerLogin() async {
    if (_emailController.text.isEmpty || _senhaController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Preencha todos os campos')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final isValid = await _database.validateLogin(
        _emailController.text.trim(),
        _senhaController.text,
      );

      if (isValid && mounted) {
        final user = await _database.getUserByEmail(
          _emailController.text.trim(),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                TelaPrincipal(userName: user!['nome_completo']),
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('E-mail ou senha incorretos')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao fazer login: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        centerTitle: true,
        backgroundColor: Colors.green, // Botão verde no AppBar
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                
                color: Colors.green.withOpacity(0.1), 
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.analytics_outlined,
                size: 60,
                color: Colors.green, 
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Analisador de Texto',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Análise Inteligente de Textos',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 40),

            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'E-mail',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _senhaController,
              decoration: InputDecoration(
                labelText: 'Senha',
                prefixIcon: const Icon(Icons.lock),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _senhaVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () =>
                      setState(() => _senhaVisible = !_senhaVisible),
                ),
              ),
              obscureText: !_senhaVisible,
            ),
            const SizedBox(height: 24),

            // BOTÃO ENTRAR 
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _fazerLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  disabledBackgroundColor: Colors.green.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Entrar',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // LINK 
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TelaCadastro(),
                        ),
                      );
                    },
              child: const Text(
                'Ainda não tem conta? Cadastre-se',
                style: TextStyle(color: Colors.green),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }
}

//  TELA DE CADASTRO 
class TelaCadastro extends StatefulWidget {
  const TelaCadastro({super.key});

  @override
  State<TelaCadastro> createState() => _TelaCadastroState();
}

class _TelaCadastroState extends State<TelaCadastro> {
  final _formKey = GlobalKey<FormState>();
  final UserDatabase _database = UserDatabase();

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _cpfController = TextEditingController();
  final TextEditingController _dataController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _confirmacaoController = TextEditingController();

  final cpfMask = CpfInputFormatter();
  final dataMask = DataInputFormatter();

  bool _hasUpperCase = false;
  bool _hasLowerCase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;
  bool _hasMinLength = false;
  bool _senhaVisible = false;
  bool _confirmacaoVisible = false;

  void _validatePassword(String password) {
    setState(() {
      _hasUpperCase = RegExp(r'[A-Z]').hasMatch(password);
      _hasLowerCase = RegExp(r'[a-z]').hasMatch(password);
      _hasNumber = RegExp(r'[0-9]').hasMatch(password);
      _hasSpecialChar = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
      _hasMinLength = password.length >= 8;
    });
  }

  bool get _isPasswordValid {
    return _hasUpperCase &&
        _hasLowerCase &&
        _hasNumber &&
        _hasSpecialChar &&
        _hasMinLength;
  }

  bool get _isFormValid {
    return _nomeController.text.isNotEmpty &&
        _cpfController.text.length == 14 &&
        _dataController.text.length == 10 &&
        RegExp(
          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
        ).hasMatch(_emailController.text) &&
        _isPasswordValid &&
        _senhaController.text == _confirmacaoController.text;
  }

  String? _validateNome(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nome completo é obrigatório';
    }
    if (value.trim().split(' ').length < 2) {
      return 'Digite nome e sobrenome';
    }
    return null;
  }

  String? _validateCPF(String? value) {
    if (value == null || value.isEmpty) {
      return 'CPF é obrigatório';
    }

    String cpfNumeros = value.replaceAll(RegExp(r'[^\d]'), '');

    if (cpfNumeros.length != 11) {
      return 'CPF deve ter 11 dígitos';
    }

    if (_isCPFRepetido(cpfNumeros)) {
      return 'CPF inválido';
    }

    return null;
  }

  bool _isCPFRepetido(String cpf) {
    return RegExp(r'^(\d)\1{10}$').hasMatch(cpf);
  }

  String? _validateData(String? value) {
    if (value == null || value.isEmpty) {
      return 'Data de nascimento é obrigatória';
    }

    if (value.length != 10) {
      return 'Data incompleta (DD/MM/AAAA)';
    }

    try {
      List<String> partes = value.split('/');
      if (partes.length != 3) return 'Formato inválido';

      int dia = int.parse(partes[0]);
      int mes = int.parse(partes[1]);
      int ano = int.parse(partes[2]);

      if (dia < 1 || dia > 31) return 'Dia inválido';
      if (mes < 1 || mes > 12) return 'Mês inválido';
      if (ano < 1900 || ano > DateTime.now().year) return 'Ano inválido';

      DateTime dataNascimento = DateTime(ano, mes, dia);
      if (dataNascimento.year != ano ||
          dataNascimento.month != mes ||
          dataNascimento.day != dia) {
        return 'Data inválida';
      }

      DateTime hoje = DateTime.now();
      DateTime maioridade = DateTime(hoje.year - 18, hoje.month, hoje.day);
      if (dataNascimento.isAfter(maioridade)) {
        return 'É necessário ser maior de 18 anos';
      }
    } catch (e) {
      return 'Data inválida';
    }

    return null;
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      final formattedDate =
          "${picked.day.toString().padLeft(2, '0')}/"
          "${picked.month.toString().padLeft(2, '0')}/"
          "${picked.year}";
      _dataController.text = formattedDate;
    }
  }

  Future<void> _cadastrarUsuario() async {
    if (_formKey.currentState!.validate()) {
      try {
        final user = {
          'nome_completo': _nomeController.text.trim(),
          'cpf': _cpfController.text,
          'data_nascimento': _dataController.text,
          'email': _emailController.text.trim(),
          'senha': _senhaController.text,
        };

        await _database.insertUser(user);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cadastro realizado com sucesso!'),
              backgroundColor: Colors.green, 
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao cadastrar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro'),
        centerTitle: true,
        backgroundColor: Colors.green, 
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome Completo',
                  prefixIcon: Icon(Icons.person),
                  hintText: 'Digite nome e sobrenome',
                  border: OutlineInputBorder(),
                ),
                validator: _validateNome,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _cpfController,
                decoration: const InputDecoration(
                  labelText: 'CPF',
                  prefixIcon: Icon(Icons.badge),
                  hintText: '000.000.000-00',
                  border: OutlineInputBorder(),
                ),
                inputFormatters: [cpfMask],
                keyboardType: TextInputType.number,
                validator: _validateCPF,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _dataController,
                decoration: InputDecoration(
                  labelText: 'Data de Nascimento',
                  prefixIcon: const Icon(Icons.calendar_today),
                  hintText: 'DD/MM/AAAA',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(
                      Icons.calendar_month,
                      color: Colors.green,
                    ), // Ícone verde
                    onPressed: _selectDate,
                  ),
                ),
                inputFormatters: [dataMask],
                keyboardType: TextInputType.datetime,
                validator: _validateData,
                onChanged: (_) => setState(() {}),
                readOnly: true,
                onTap: _selectDate,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  prefixIcon: Icon(Icons.email),
                  hintText: 'seu@email.com',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'E-mail é obrigatório';
                  }
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(value)) {
                    return 'E-mail inválido';
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _senhaController,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  prefixIcon: const Icon(Icons.lock),
                  hintText: 'Mínimo 8 caracteres',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _senhaVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.green, // Ícone verde
                    ),
                    onPressed: () =>
                        setState(() => _senhaVisible = !_senhaVisible),
                  ),
                ),
                obscureText: !_senhaVisible,
                onChanged: _validatePassword,
              ),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildValidationItem('Mínimo 8 caracteres', _hasMinLength),
                    _buildValidationItem(
                      'Letra maiúscula (A-Z)',
                      _hasUpperCase,
                    ),
                    _buildValidationItem(
                      'Letra minúscula (a-z)',
                      _hasLowerCase,
                    ),
                    _buildValidationItem('Número (0-9)', _hasNumber),
                    _buildValidationItem(
                      'Caractere especial (!@#\$)',
                      _hasSpecialChar,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _confirmacaoController,
                decoration: InputDecoration(
                  labelText: 'Confirmação de Senha',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _confirmacaoVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.green, 
                    ),
                    onPressed: () => setState(
                      () => _confirmacaoVisible = !_confirmacaoVisible,
                    ),
                  ),
                ),
                obscureText: !_confirmacaoVisible,
                validator: (value) {
                  if (value != _senhaController.text) {
                    return 'Senhas não conferem';
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 32),

              // BOTÃO CADASTRAR 
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isFormValid ? _cadastrarUsuario : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    disabledBackgroundColor: Colors.green.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Cadastrar',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildValidationItem(String text, bool isValid) {
    return Row(
      children: [
        Icon(
          isValid ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isValid ? Colors.green : Colors.grey,
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(color: isValid ? Colors.green : Colors.grey),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cpfController.dispose();
    _dataController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmacaoController.dispose();
    super.dispose();
  }
}

//  TELA PRINCIPAL 
class TelaPrincipal extends StatefulWidget {
  final String userName;

  const TelaPrincipal({super.key, required this.userName});

  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal> {
  final TextEditingController _controller = TextEditingController();
  final List<String> stopwords = const [
    "a",
    "o",
    "que",
    "de",
    "para",
    "com",
    "sem",
    "mas",
    "e",
    "ou",
    "entre",
    "em",
    "por",
    "da",
    "do",
  ];

  String? analyzedText;

  int _countCharacters(String text, {bool incluirEspacos = true}) {
    return incluirEspacos ? text.length : text.replaceAll(" ", "").length;
  }

  int _countWords(String text) {
    final List<String> words = text
        .split(RegExp(r'\s+'))
        .where((String s) => s.isNotEmpty)
        .toList();
    return words.length;
  }

  int _countSentences(String text) {
    final List<String> sentences = text
        .split(RegExp(r'[.!?]+'))
        .where((String s) => s.trim().isNotEmpty)
        .toList();
    return sentences.length;
  }

  List<MapEntry<String, int>> _wordFrequency(String text) {
    final words = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty && !stopwords.contains(w))
        .toList();

    final Map<String, int> freq = {};
    for (var w in words) {
      freq[w] = (freq[w] ?? 0) + 1;
    }

    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(10).toList();
  }

  double _readingTime(String text) {
    final words = _countWords(text);
    return words / 250;
  }

  void _analisarTexto() {
    if (_controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Digite algum texto para analisar!"),
          backgroundColor: Colors.green, // SnackBar verde
        ),
      );
      return;
    }

    setState(() {
      analyzedText = _controller.text;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TelaResultados(
          texto: _controller.text,
          charCount: _countCharacters(_controller.text, incluirEspacos: true),
          charCountNoSpaces: _countCharacters(
            _controller.text,
            incluirEspacos: false,
          ),
          wordCount: _countWords(_controller.text),
          sentenceCount: _countSentences(_controller.text),
          topWords: _wordFrequency(_controller.text),
          readingTime: _readingTime(_controller.text),
        ),
      ),
    );
  }

  void _limparTexto() {
    _controller.clear();
    setState(() {
      analyzedText = null;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Analisador de Texto"),
        centerTitle: true,
        backgroundColor: Colors.green, 
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white), // Ícone branco
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const TelaLogin()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.green.withOpacity(0.1), 
            child: Text(
              "Bem-vindo, ${widget.userName}!",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: "Digite ou cole seu texto aqui...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(
                      Icons.clear,
                      color: Colors.green,
                    ), 
                    onPressed: _limparTexto,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _analisarTexto,
              child: const Text(
                "Analisar",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),

          Container(
            width: double.infinity,
            color: Colors.grey.shade200,
            padding: const EdgeInsets.all(8.0),
            child: const Text(
              "Por Andrew Oliveira Neves Silva",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }
}

// TELA DE RESULTADOS 
class TelaResultados extends StatelessWidget {
  final String texto;
  final int charCount;
  final int charCountNoSpaces;
  final int wordCount;
  final int sentenceCount;
  final List<MapEntry<String, int>> topWords;
  final double readingTime;

  const TelaResultados({
    super.key,
    required this.texto,
    required this.charCount,
    required this.charCountNoSpaces,
    required this.wordCount,
    required this.sentenceCount,
    required this.topWords,
    required this.readingTime,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Resultados da Análise"),
        centerTitle: true,
        backgroundColor: Colors.green, // AppBar verde
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Estatísticas do Texto:",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildStatItem('Caracteres (com espaços):', '$charCount'),
                    _buildStatItem(
                      'Caracteres (sem espaços):',
                      '$charCountNoSpaces',
                    ),
                    _buildStatItem('Palavras:', '$wordCount'),
                    _buildStatItem('Sentenças:', '$sentenceCount'),
                    _buildStatItem(
                      'Tempo de leitura estimado:',
                      '${readingTime.toStringAsFixed(2)} min',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Top 10 palavras mais frequentes:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...topWords.map(
                      (e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                e.key,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(
                                  0.1,
                                ), 
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${e.value}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green, 
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (topWords.isEmpty)
                      const Text(
                        'Nenhuma palavra frequente encontrada',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green, // ME PASSA PROFESSOR POR FAVOOOOORRRR
            ),
          ),
        ],
      ),
    );
  }
}
