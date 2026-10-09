import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_header.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/app_theme.dart';
import '../utils/navigation_helper.dart';
import '../login_screen.dart';

class ChatbotScreen extends StatefulWidget {
  final bool isEmbedded;
  const ChatbotScreen({super.key, this.isEmbedded = false});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;

  List<String> _getQuickQuestions(BuildContext context) {
    final role = Provider.of<AuthProvider>(context, listen: false).user?.role;
    if (role == 'farmer' || role == 'user') {
      return [
        'Cara mengatasi hawar daun / busuk daun tanaman kentang',
        'Racikan pupuk organik cair (POC) penekan biaya modal',
        'Konversi panen ke olahan bebas biaya ganda (Rp 0 kas)',
        'Cara sterilisasi baglog jamur tiram anti kontaminasi',
      ];
    }
    return [
      'Strategi penetrasi pasar produk olahan desa & kemasan',
      'Manajemen kapasitas gudang desa & susut panen raya',
      'Alur pemrosesan pesanan katalog via WhatsApp & SLA',
      'Analisis keuangan komisi platform 3% & alokasi PADes',
    ];
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend(String text) async {
    if (_isTyping) return;

    final cleanText = text.trim();
    if (cleanText.isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final role = authProvider.user?.role;
    final roleContext = (role == 'farmer' || role == 'user') ? 'farmer' : 'super_admin';

    // Susun riwayat percakapan valid untuk dikirim ke backend (max 8 turn)
    final List<Map<String, String>> historyPayload = _messages
        .where((m) => m['text'] != null && (m['text'] as String).trim().isNotEmpty && m['source'] != 'error')
        .map((m) {
          final text = (m['text'] as String).trim();
          final safeContent = text.length > 1500 ? text.substring(0, 1500) : text;
          return {
            'role': (m['isUser'] == true) ? 'user' : 'assistant',
            'content': safeContent,
          };
        })
        .toList();
    final recentHistory = historyPayload.length > 8
        ? historyPayload.sublist(historyPayload.length - 8)
        : historyPayload;

    _messageController.clear();

    setState(() {
      _messages.add({
        'text': cleanText,
        'isUser': true,
        'timestamp': DateTime.now(),
      });
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      final response = await _apiService.sendChatMessage(
        cleanText,
        roleContext: roleContext,
        history: recentHistory,
      );

      if (!mounted) return;

      setState(() {
        _messages.add({
          'text': response['reply'] ?? 'Maaf, terjadi kesalahan.',
          'isUser': false,
          'timestamp': DateTime.now(),
          'source': response['source'],
          'model': response['model'],
        });
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _messages.add({
          'text': 'Gagal mengirim pesan. Silakan periksa koneksi internet Anda.',
          'isUser': false,
          'timestamp': DateTime.now(),
          'source': 'error',
        });
      });
    } finally {
      if (mounted) {
        setState(() {
          _isTyping = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              final nav = Navigator.of(context);
              final auth = context.read<AuthProvider>();
              nav.pop();
              await auth.logout();
              nav.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
            child: const Text('Keluar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEmbedded) {
      return Column(
        children: [
          Expanded(
            child: _messages.isEmpty ? _buildWelcomeView() : _buildChatList(),
          ),
          if (_isTyping) _buildTypingIndicator(),
          _buildInputArea(),
        ],
      );
    }

    final user = context.read<AuthProvider>().user;
    final name = user?.name ?? 'Super Admin';
    final email = user?.email ?? '';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'S';
    final isFarmer = user?.role == 'farmer' || user?.role == 'user';
    final chatTitle = isFarmer ? 'TaniBot Pertanian' : 'TaniBot Bisnis (BUMDes)';
    final chatSubtitle = isFarmer
        ? 'Asisten budidaya tanaman, penanganan hama & penyakit, pupuk, dan modal kebun'
        : 'Konsultan bisnis produk olahan, serapan panen, manajemen katalog, dan komisi platform 3%';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;

        return Scaffold(
          backgroundColor: AppTheme.pageBg,
          appBar: isDesktop
              ? null
              : AppMobileAppBar(
                  title: chatTitle,
                  userInitials: initials,
                  onNotificationTap: () {},
                ),
          drawer: isDesktop
              ? null
              : AppDrawer(
                  userName: name,
                  userEmail: email,
                  userInitials: initials,
                  onLogout: () => _showLogoutDialog(context),
                  navItems: NavigationHelper.buildNavItems(context, 'chatbot'),
                  secondaryItems: NavigationHelper.buildSecondaryNavItems(context, 'chatbot'),
                ),
          body: Row(
            children: [
              if (isDesktop)
                AppSidebar(
                  userName: name,
                  userEmail: email,
                  userInitials: initials,
                  onLogout: () => _showLogoutDialog(context),
                  navItems: NavigationHelper.buildNavItems(context, 'chatbot'),
                  secondaryItems: NavigationHelper.buildSecondaryNavItems(context, 'chatbot'),
                ),
              Expanded(
                child: Column(
                  children: [
                    if (isDesktop)
                      AppHeader(
                        title: chatTitle,
                        subtitle: chatSubtitle,
                        userInitials: initials,
                        actions: [
                          if (_messages.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.delete_sweep_outlined),
                              tooltip: 'Bersihkan Chat',
                              onPressed: () {
                                setState(() => _messages.clear());
                              },
                            ),
                        ],
                      ),
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: _messages.isEmpty ? _buildWelcomeView() : _buildChatList(),
                          ),
                          if (_isTyping) _buildTypingIndicator(),
                          _buildInputArea(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWelcomeView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Builder(
            builder: (ctx) {
              final role = Provider.of<AuthProvider>(ctx, listen: false).user?.role;
              final isFarmer = role == 'farmer' || role == 'user';
              final iconEmoji = isFarmer ? '🌱' : '💼';
              final greetingTitle = isFarmer ? 'Halo! Saya TaniBot Pertanian 🌱' : 'Halo! Saya TaniBot Bisnis & BUMDes 💼';
              final desc = isFarmer
                  ? 'Pakar cerdas budidaya tanaman, penanganan hama & penyakit, efisiensi pupuk, dan kalkulasi modal kebun.'
                  : 'Konsultan cerdas bisnis agribisnis desa, strategi pemasaran olahan, serapan panen Poktan, dan komisi platform 3%.';

              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.green500.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Text(iconEmoji, style: const TextStyle(fontSize: 50)),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    greetingTitle,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.green700),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    desc,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.5),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 36),
          const Row(
            children: [
              Icon(Icons.tips_and_updates_outlined, color: AppTheme.green500, size: 20),
              SizedBox(width: 8),
              Text(
                'Pertanyaan Rekomendasi:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.green700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Builder(
            builder: (ctx) {
              final questions = _getQuickQuestions(ctx);
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  final question = questions[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: InkWell(
                      onTap: () => _handleSend(question),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.cardBorder),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                question,
                                style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.green500),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isUser = message['isUser'] as bool;
        return _buildChatBubble(message['text'] as String, isUser);
      },
    );
  }

  Widget _buildChatBubble(String text, bool isUser) {
    final role = Provider.of<AuthProvider>(context, listen: false).user?.role;
    final isFarmer = role == 'farmer' || role == 'user';
    final botIcon = isFarmer ? '🌱' : '💼';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              margin: const EdgeInsets.only(right: 10.0, top: 2.0),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isFarmer
                    ? AppTheme.green500.withValues(alpha: 0.12)
                    : Colors.blue.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isFarmer
                      ? AppTheme.green500.withValues(alpha: 0.3)
                      : Colors.blue.withValues(alpha: 0.3),
                ),
              ),
              alignment: Alignment.center,
              child: Text(botIcon, style: const TextStyle(fontSize: 16)),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
              decoration: BoxDecoration(
                color: isUser ? AppTheme.green700 : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser ? null : Border.all(color: AppTheme.cardBorder),
                boxShadow: AppTheme.cardShadow,
              ),
              child: isUser
                  ? Text(
                      text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.45,
                      ),
                    )
                  : MarkdownBody(
                      data: text,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                        p: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          height: 1.5,
                        ),
                        h1: const TextStyle(
                          color: AppTheme.green800,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          height: 1.4,
                        ),
                        h2: const TextStyle(
                          color: AppTheme.green800,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          height: 1.4,
                        ),
                        h3: const TextStyle(
                          color: AppTheme.green700,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          height: 1.4,
                        ),
                        strong: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        tableBody: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 12.5,
                        ),
                        tableHead: const TextStyle(
                          color: AppTheme.green800,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                        ),
                        tableBorder: TableBorder.all(
                          color: AppTheme.cardBorder,
                          width: 1,
                        ),
                        tableColumnWidth: const IntrinsicColumnWidth(),
                        tableCellsPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        tableCellsDecoration: const BoxDecoration(
                          color: Color(0xFFF9FBF9),
                        ),
                        horizontalRuleDecoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: AppTheme.cardBorder, width: 1),
                          ),
                        ),
                        listBullet: const TextStyle(
                          color: AppTheme.green700,
                          fontWeight: FontWeight.bold,
                        ),
                        code: TextStyle(
                          backgroundColor: Colors.grey.shade100,
                          color: AppTheme.green800,
                          fontSize: 13,
                          fontFamily: 'monospace',
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            margin: const EdgeInsets.only(right: 8.0),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.green500.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text('🌾', style: TextStyle(fontSize: 16)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int delayIndex) {
    return _DotAnimation(delayIndex: delayIndex);
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppTheme.cardBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.pageBg,
                borderRadius: BorderRadius.circular(24.0),
              ),
              child: TextField(
                controller: _messageController,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Tanya sesuatu ke TaniBot...',
                  hintStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _isTyping ? null : () => _handleSend(_messageController.text),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isTyping ? Colors.grey.shade400 : AppTheme.green700,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _DotAnimation extends StatefulWidget {
  final int delayIndex;
  const _DotAnimation({required this.delayIndex});

  @override
  State<_DotAnimation> createState() => _DotAnimationState();
}

class _DotAnimationState extends State<_DotAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
      ),
    );

    Future.delayed(Duration(milliseconds: widget.delayIndex * 150), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -4 * _animation.value),
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppTheme.textSecondary,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}