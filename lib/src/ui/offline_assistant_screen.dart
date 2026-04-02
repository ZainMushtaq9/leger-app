import 'package:flutter/material.dart';

import '../controller.dart';
import '../theme.dart';
import 'common_widgets.dart';

class OfflineAssistantScreen extends StatefulWidget {
  const OfflineAssistantScreen({super.key, required this.controller});

  final HisabRakhoController controller;

  @override
  State<OfflineAssistantScreen> createState() => _OfflineAssistantScreenState();
}

class _OfflineAssistantScreenState extends State<OfflineAssistantScreen> {
  final TextEditingController _queryController = TextEditingController();
  final List<_AssistantMessage> _messages = <_AssistantMessage>[];

  @override
  void initState() {
    super.initState();
    _messages.add(
      _AssistantMessage(
        isUser: false,
        text: widget.controller.answerOfflineAssistantQuery(''),
      ),
    );
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _submit([String? presetQuery]) {
    final query = (presetQuery ?? _queryController.text).trim();
    if (query.isEmpty) {
      return;
    }
    final answer = widget.controller.answerOfflineAssistantQuery(query);
    setState(() {
      _messages.add(_AssistantMessage(isUser: true, text: query));
      _messages.add(_AssistantMessage(isUser: false, text: answer));
    });
    _queryController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offline Assistant')),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                children: <Widget>[
                  const SectionHeader(
                    title: 'Local Business Assistant',
                    subtitle:
                        'Ask about recovery, stock, suppliers, payroll, or sales. Answers are generated from data already stored on this device.',
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: widget.controller.offlineAssistantPrompts
                        .map(
                          (prompt) => ActionChip(
                            label: Text(prompt),
                            onPressed: () => _submit(prompt),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 18),
                  ..._messages.map((message) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Align(
                        alignment: message.isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 680),
                          child: Card(
                            color: message.isUser
                                ? kKhataGreen.withValues(alpha: 0.1)
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    message.isUser ? 'You' : 'Assistant',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: message.isUser
                                              ? kKhataGreen
                                              : kKhataAmber,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  SelectableText(message.text),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _queryController,
                        textInputAction: TextInputAction.send,
                        minLines: 1,
                        maxLines: 3,
                        onSubmitted: (_) => _submit(),
                        decoration: const InputDecoration(
                          labelText: 'Ask something',
                          hintText: 'Who needs follow-up today?',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('Send'),
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
}

class _AssistantMessage {
  const _AssistantMessage({required this.isUser, required this.text});

  final bool isUser;
  final String text;
}
