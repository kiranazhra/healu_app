// ignore_for_file: avoid_print, deprecated_member_use

import 'package:flutter/material.dart';
import 'services/api_client.dart';
import 'dart:convert';
import 'dart:async';
import 'gender_avatar_helper.dart';

class ChatScreen extends StatefulWidget {
  final String idKonsultasi;
  final String namaLawanBicara;
  final String idUser;
  final String idRole;
  // Opsional: kirim ini dari layar pemanggil kalau data jenis_kelamin
  // dokter sudah tersedia (mis. dari get_dokters.php), supaya avatar
  // tidak perlu menebak dari nama.
  final String? jenisKelaminLawanBicara;

  const ChatScreen({
    super.key,
    required this.idKonsultasi,
    required this.namaLawanBicara,
    required this.idUser,
    required this.idRole,
    this.jenisKelaminLawanBicara,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<dynamic> _listChat = [];
  bool _isLoading = true;
  Timer? _timer;

  final String baseUrl =
      "https://chump-vividness-escapable.ngrok-free.dev/healu_api";

  @override
  void initState() {
    super.initState();
    _fetchIsiChat();

    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _fetchIsiChat(isPolling: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchIsiChat({bool isPolling = false}) async {
    try {
      var response = await ApiClient.instance.get(
        Uri.parse(
          "$baseUrl/get_isi_chat.php?id_konsultasi=${widget.idKonsultasi}",
        ),
      );

      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);
        if (json['status'] == 'success') {
          if (!mounted) return;

          setState(() {
            _listChat = json['data'];
            _isLoading = false;
          });

          _scrollToBottom();
        }
      }
    } catch (e) {
      print("Error fetch chat: $e");
      if (!mounted) return;
      if (!isPolling) setState(() => _isLoading = false);
    }
  }

  Future<void> _kirimPesan() async {
    String teksPesan = _chatController.text.trim();
    if (teksPesan.isEmpty) return;

    _chatController.clear();

    try {
      var response = await ApiClient.instance.post(
        Uri.parse("$baseUrl/kirim_chat.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "id_konsultasi": widget.idKonsultasi,
          "id_pengirim": widget.idUser,
          "pesan": teksPesan,
        }),
      );

      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);
        if (json['status'] == 'success') {
          _fetchIsiChat();
        }
      }
    } catch (e) {
      print("Error kirim chat: $e");
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF93B174),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            // ChatScreen dipakai bergantian oleh dokter (melihat profil
            // pasien) maupun pasien (melihat profil dokter). Kalau yang
            // dilihat adalah profil dokter (idRole == 'pasien'), avatar
            // memakai ikon sesuai gender dokter agar konsisten dengan
            // KonsultasiScreen & SesiKonsultasiScreen -- tidak kosong lagi.
            // Kalau yang dilihat adalah profil pasien, tetap avatar generik
            // karena belum ada sumber data gender pasien.
            widget.idRole.toLowerCase() == 'pasien'
                ? GenderAvatarHelper.buildAvatar(
                    widget.namaLawanBicara,
                    jenisKelamin: widget.jenisKelaminLawanBicara,
                    radius: 18,
                  )
                : CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.grey.shade200,
                    child: Icon(
                      Icons.person,
                      color: Colors.grey.shade500,
                      size: 20,
                    ),
                  ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.namaLawanBicara,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    "Online",
                    style: TextStyle(color: Colors.green, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF93B174)),
                  )
                : _listChat.isEmpty
                ? const Center(
                    child: Text("Belum ada pesan. Silakan mulai menyapa!"),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _listChat.length,
                    itemBuilder: (context, index) {
                      var chat = _listChat[index];

                      bool isMe =
                          chat['id_pengirim'].toString() == widget.idUser;

                      // 🟢 PERBAIKAN UTAMA: Menggunakan 'Waktu_kirim' dengan 'W' kapital
                      String formatWaktu = "00:00";
                      if (chat['Waktu_kirim'] != null &&
                          chat['Waktu_kirim'].toString().length >= 16) {
                        // Mengambil karakter jam dan menit saja (contoh: dari "2026-05-28 21:25:28" diambil "21:25")
                        formatWaktu = chat['Waktu_kirim'].toString().substring(
                          11,
                          16,
                        );
                      }

                      return _buildChatBubble(
                        pesan: chat['pesan'] ?? '',
                        waktu: formatWaktu,
                        isMe: isMe,
                      );
                    },
                  ),
          ),
          _buildInputChat(),
        ],
      ),
    );
  }

  Widget _buildChatBubble({
    required String pesan,
    required String waktu,
    required bool isMe,
  }) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFE6EBC5) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft: Radius.circular(isMe ? 15 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 15),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              pesan,
              style: const TextStyle(color: Colors.black87, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              waktu,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputChat() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.transparent,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _chatController,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _kirimPesan(),
                  decoration: const InputDecoration(
                    hintText: "Ketik pesan...",
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _kirimPesan,
            child: const CircleAvatar(
              radius: 24,
              backgroundColor: Color(0xFF93B174),
              child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}