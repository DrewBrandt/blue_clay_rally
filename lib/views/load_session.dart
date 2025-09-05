// load_session_page.dart
import 'package:blue_clay_rally/providers/app_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
// typedef StoredSession = (int id, SessionInfo info);

class LoadSessionPage extends ConsumerWidget {
  const LoadSessionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(sessionSummariesProvider);
    final app = ref.read(appNotifierProvider.notifier);
    final fmt = DateFormat.yMMMd().add_jm();

    return Scaffold(
      appBar: AppBar(title: const Text('Load Old Session')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(sessionSummariesProvider);
          await ref.read(sessionSummariesProvider.future);
        },
        child: asyncList.when(
          data: (items) {
            if (items.isEmpty) {
              return const Center(child: Text('No stored sessions found.'));
            }
            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final (id, info) = items[i];
                final startedAt = info.cps.isNotEmpty ? info.cps.first.time.toLocal() : null;
                final startedStr = startedAt != null ? fmt.format(startedAt) : 'Not started';
                final subtitle = '${info.trackFileName} • ${info.trackFileType.toUpperCase()}'
                    ' • ${info.cps.length} CP'
                    '${info.finished ? ' • Finished' : ''}';

                return ListTile(
                  leading: Icon(info.finished ? Icons.flag : Icons.playlist_add_check),
                  title: Text(startedStr),
                  subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await app.loadSessionById(id);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Failed to load sessions:\n$e'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
