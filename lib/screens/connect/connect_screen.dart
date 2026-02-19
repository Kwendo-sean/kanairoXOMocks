import 'package:flutter/material.dart';
import 'package:kanairoxo/widgets/connect/accept_invitation_card.dart';
import 'package:kanairoxo/widgets/connect/invite_partner_card.dart';

class ConnectScreen extends StatelessWidget {
  const ConnectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            InvitePartnerCard(),
            SizedBox(height: 24),
            AcceptInvitationCard(),
          ],
        ),
      ),
    );
  }
}
