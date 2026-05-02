// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

import '../utils/ui.dart';

class MarkdownView extends StatelessWidget {
  const MarkdownView({
    super.key,
    required this.data,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    this.asBody = false,
  });

  final String data;
  final EdgeInsets padding;
  final bool asBody;

  MarkdownStyleSheet _styleSheet(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return MarkdownStyleSheet.fromTheme(theme).copyWith(
      p: theme.textTheme.bodyLarge?.copyWith(
        fontSize: 15,
        height: 1.66,
        color: cs.onSurface,
      ),
      h1: theme.textTheme.headlineMedium?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        height: 1.28,
        color: cs.primary,
      ),
      h2: theme.textTheme.headlineSmall?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: cs.primary,
      ),
      h3: theme.textTheme.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.32,
        color: cs.primary,
      ),
      h4: theme.textTheme.titleMedium?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.34,
        color: cs.primary,
      ),
      h5: theme.textTheme.titleSmall?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: cs.primary,
      ),
      h6: theme.textTheme.bodyMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: cs.primary,
      ),
      h1Padding: const EdgeInsets.only(top: 10, bottom: 14),
      h2Padding: const EdgeInsets.only(top: 8, bottom: 12),
      h3Padding: const EdgeInsets.only(top: 7, bottom: 11),
      h4Padding: const EdgeInsets.only(top: 6, bottom: 10),
      h5Padding: const EdgeInsets.only(top: 6, bottom: 9),
      h6Padding: const EdgeInsets.only(top: 5, bottom: 8),
      pPadding: const EdgeInsets.only(bottom: 10),
      blockSpacing: 10,
      listIndent: 26,
      listBulletPadding: const EdgeInsets.only(right: 6),
      blockquotePadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      blockquoteDecoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(color: cs.outline, width: 3),
        ),
      ),
      blockquote: theme.textTheme.bodyMedium?.copyWith(
        color: cs.onSurface,
        height: 1.6,
      ),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: cs.outlineVariant,
            width: 1,
          ),
        ),
      ),
      code: TextStyle(
        fontFamily: 'monospace',
        fontSize: 13,
        height: 1.5,
        color: cs.onSurface,
        backgroundColor: cs.surfaceContainerHighest,
      ),
      codeblockPadding: const EdgeInsets.all(12),
      codeblockDecoration: const BoxDecoration(),
      tableHead: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w700,
        height: 1.5,
        color: cs.onSurface,
      ),
      tableBody: theme.textTheme.bodyMedium?.copyWith(height: 1.5, color: cs.onSurface),
      tableCellsPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      tableBorder: TableBorder.all(
        color: cs.outlineVariant,
        width: 1,
      ),
      a: TextStyle(
        color: cs.primary,
        decoration: TextDecoration.underline,
        decorationColor: cs.primary,
      ),
      img: theme.textTheme.bodySmall?.copyWith(color: cs.outline),
    );
  }

  Future<void> _onTapLink(BuildContext context, String text, String? href, String title) async {
    final raw = href?.trim();
    if (raw == null || raw.isEmpty) return;
    final uri = Uri.tryParse(raw);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _preprocessContent(String input) {
    var out = input;

    // Support HTML details block.
    out = out.replaceAllMapped(
      RegExp(r'<details>\s*<summary>([\s\S]*?)</summary>([\s\S]*?)</details>', caseSensitive: false),
      (m) => ':::details ${m.group(1)!.trim()}\n${m.group(2)!.trim()}\n:::',
    );

    // Basic HTML -> markdown compatibility.
    out = out
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<\/?strong>', caseSensitive: false), '**')
        .replaceAll(RegExp(r'<\/?b>', caseSensitive: false), '**')
        .replaceAll(RegExp(r'<\/?em>', caseSensitive: false), '*')
        .replaceAll(RegExp(r'<\/?i>', caseSensitive: false), '*')
        .replaceAll(RegExp(r'<\/?code>', caseSensitive: false), '`');

    // html mark -> ==text== (custom highlight syntax)
    out = out.replaceAllMapped(
      RegExp(r'<mark>([\s\S]*?)</mark>', caseSensitive: false),
      (m) => '==${m.group(1) ?? ''}==',
    );

    return out;
  }

  @override
  Widget build(BuildContext context) {
    final content = _preprocessContent(data.trim().isEmpty ? '_空内容_' : data);
    final sections = _splitDetailsSections(content);
    final builders = <String, MarkdownElementBuilder>{
      'pre': _PreBlockBuilder(context),
      'mark': _MarkBuilder(context),
      'blockquote': _BlockquoteBuilder(context),
    };
    Widget imageBuilder(Uri uri, String? title, String? alt) => _RoundedMarkdownImage(uri: uri);
    Future<void> tap(String text, String? href, String title) => _onTapLink(context, text, href, title);
    final inlineSyntaxes = <md.InlineSyntax>[_HighlightSyntax()];
    Widget renderBody(String text) => MarkdownBody(
          data: text,
          selectable: true,
          extensionSet: md.ExtensionSet.gitHubWeb,
          inlineSyntaxes: inlineSyntaxes,
          styleSheet: _styleSheet(context),
          builders: builders,
          imageBuilder: imageBuilder,
          onTapLink: tap,
        );

    Widget renderSections() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final s in sections)
            if (!s.isDetails)
              renderBody(s.content)
            else
              Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                ),
                child: ExpansionTile(
                  title: Text(s.summary ?? '详情'),
                  tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                  childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                  children: [renderBody(s.content)],
                ),
              ),
        ],
      );
    }

    if (asBody) {
      return Padding(
        padding: padding,
        child: renderSections(),
      );
    }

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: padding,
        child: renderSections(),
      ),
    );
  }

  List<_MdSection> _splitDetailsSections(String input) {
    final reg = RegExp(r'^:::\s*details(?:\s+(.*))?\s*$([\s\S]*?)^:::\s*$', multiLine: true);
    final sections = <_MdSection>[];
    var offset = 0;
    for (final m in reg.allMatches(input)) {
      if (m.start > offset) {
        final normal = input.substring(offset, m.start).trim();
        if (normal.isNotEmpty) sections.add(_MdSection.normal(normal));
      }
      final summary = (m.group(1) ?? '详情').trim();
      final body = (m.group(2) ?? '').trim();
      sections.add(_MdSection.details(summary: summary, content: body));
      offset = m.end;
    }
    if (offset < input.length) {
      final tail = input.substring(offset).trim();
      if (tail.isNotEmpty) sections.add(_MdSection.normal(tail));
    }
    if (sections.isEmpty) return [_MdSection.normal(input)];
    return sections;
  }
}

class _PreBlockBuilder extends MarkdownElementBuilder {
  _PreBlockBuilder(this.context);

  final BuildContext context;

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final code = element.textContent;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return LayoutBuilder(
      builder: (ctx, c) => SizedBox(
        width: c.maxWidth,
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 6, bottom: 8),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(12),
                child: SelectableText(
                  code,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    height: 1.5,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 8,
              top: 10,
              child: IconButton(
                tooltip: '复制代码',
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  minimumSize: const Size(28, 28),
                  padding: const EdgeInsets.all(4),
                  backgroundColor: cs.surface,
                ),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: code));
                  if (!context.mounted) return;
                  Ui.toast(context, '已复制代码');
                },
                icon: Icon(Icons.copy_outlined, size: 16, color: cs.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarkBuilder extends MarkdownElementBuilder {
  _MarkBuilder(this.context);

  final BuildContext context;

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: cs.tertiaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        element.textContent,
        style: (preferredStyle ?? Theme.of(context).textTheme.bodyMedium)?.copyWith(
          color: cs.onTertiaryContainer,
        ),
      ),
    );
  }
}

class _BlockquoteBuilder extends MarkdownElementBuilder {
  _BlockquoteBuilder(this.context);

  final BuildContext context;

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final text = element.textContent.trim();

    return LayoutBuilder(
      builder: (ctx, c) => SizedBox(
        width: c.maxWidth,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
            border: Border(left: BorderSide(color: cs.outline, width: 3)),
          ),
          child: MarkdownBody(
            data: text,
            selectable: true,
            extensionSet: md.ExtensionSet.gitHubWeb,
            inlineSyntaxes: const [],
            styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
              p: theme.textTheme.bodyMedium?.copyWith(
                height: 1.6,
                color: cs.onSurface,
              ),
              pPadding: EdgeInsets.zero,
              blockSpacing: 6,
              a: TextStyle(
                color: cs.primary,
                decoration: TextDecoration.underline,
                decorationColor: cs.primary,
              ),
              code: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                height: 1.5,
                color: cs.onSurface,
                backgroundColor: cs.surface,
              ),
            ),
            onTapLink: (t, href, title) async {
              final raw = href?.trim();
              if (raw == null || raw.isEmpty) return;
              final uri = Uri.tryParse(raw);
              if (uri == null) return;
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
          ),
        ),
      ),
    );
  }
}

class _HighlightSyntax extends md.InlineSyntax {
  _HighlightSyntax() : super(r'==(.+?)==');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final text = match.group(1) ?? '';
    parser.addNode(md.Element.text('mark', text));
    return true;
  }
}

class _RoundedMarkdownImage extends StatelessWidget {
  const _RoundedMarkdownImage({
    required this.uri,
  });

  final Uri uri;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GestureDetector(
        onTap: () {
          showDialog<void>(
            context: context,
            builder: (ctx) => Dialog(
              insetPadding: const EdgeInsets.all(16),
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Image.network(uri.toString(), fit: BoxFit.contain),
              ),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            uri.toString(),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(12),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Icon(
                Icons.broken_image_outlined,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MdSection {
  const _MdSection._({
    required this.isDetails,
    required this.content,
    this.summary,
  });

  factory _MdSection.normal(String content) => _MdSection._(isDetails: false, content: content);
  factory _MdSection.details({required String summary, required String content}) =>
      _MdSection._(isDetails: true, summary: summary, content: content);

  final bool isDetails;
  final String? summary;
  final String content;
}

