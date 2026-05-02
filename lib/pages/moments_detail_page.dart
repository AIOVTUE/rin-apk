import 'package:flutter/material.dart';

import '../models/moment.dart';
import '../widgets/markdown_view.dart';

class MomentsDetailPage extends StatelessWidget {
  const MomentsDetailPage({super.key, required this.moment});

  final Moment moment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = moment.createdAt;
    final title = date == null ? '动态' : '动态 · ${date.toLocal()}'.split('.').first;

    return Scaffold(
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            floating: false,
            snap: false,
            pinned: false,
            toolbarHeight: 48,
            titleSpacing: 4,
            title: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium,
            ),
          ),
          SliverToBoxAdapter(
            child: MarkdownView(
              data: moment.content,
              asBody: true,
            ),
          ),
        ],
      ),
    );
  }
}

