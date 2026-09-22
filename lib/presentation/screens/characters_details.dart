import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:learn_bloc/business_logic/cubit/episode_cubit.dart';
import 'package:learn_bloc/business_logic/cubit/episode_state.dart';
import 'package:learn_bloc/data/models/model.dart';
import 'package:learn_bloc/presentation/widgets/episode_tile.dart';

class CharacterDetails extends StatefulWidget {
  const CharacterDetails({super.key, required this.character});
  final Character character;

  @override
  State<CharacterDetails> createState() => _CharacterDetailsState();
}

class _CharacterDetailsState extends State<CharacterDetails> {
  bool _isEpisodesExpanded = false;

  @override
  Widget build(BuildContext context) {
    final char = widget.character;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(char.name, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
        children: [
          // Large Hero Character Image
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Hero(
                tag: 'char-${char.id}',
                child: char.image.isNotEmpty
                    ? Image.network(
                        char.image,
                        width: 260,
                        height: 260,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox(
                          width: 260,
                          height: 260,
                          child: Icon(Icons.broken_image_outlined, size: 60),
                        ),
                      )
                    : const SizedBox(
                        width: 260,
                        height: 260,
                        child: Icon(Icons.person_outline, size: 60),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Character Name
          Center(
            child: Text(
              char.name,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),

          // Status Badge
          Center(
            child: Chip(
              avatar: CircleAvatar(
                backgroundColor: _statusColor(char.status),
                radius: 5,
              ),
              label: Text(
                '${char.status} • ${char.species}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              side: BorderSide.none,
            ),
          ),
          const SizedBox(height: 24),

          // Origin vs Location Cards
          Row(
            children: [
              Expanded(
                child: _LocationCard(
                  title: 'Origin',
                  value: char.origin.name,
                  icon: Icons.explore_outlined,
                  color: const Color(0xFF38A3A5),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _LocationCard(
                  title: 'Current Location',
                  value: char.location.name,
                  icon: Icons.place_outlined,
                  color: const Color(0xFF42B883),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Personal Details Section
          Text(
            'Information',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  _InfoRow(label: 'Species', value: char.species),
                  const Divider(height: 1),
                  _InfoRow(
                    label: 'Type',
                    value: char.type.isEmpty ? 'Standard' : char.type,
                  ),
                  const Divider(height: 1),
                  _InfoRow(label: 'Gender', value: char.gender),
                  const Divider(height: 1),
                  _InfoRow(
                    label: 'Appearances',
                    value: 'Appears in ${char.episode.length} episodes',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // On-Demand Episodes Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Episodes (${char.episode.length})',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _isEpisodesExpanded = !_isEpisodesExpanded;
                  });
                  if (_isEpisodesExpanded) {
                    context.read<EpisodeCubit>().loadEpisodes(char);
                  }
                },
                icon: Icon(
                  _isEpisodesExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                ),
                label: Text(_isEpisodesExpanded ? 'Hide' : 'Explore'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (_isEpisodesExpanded) _buildEpisodesView(context, char),
        ],
      ),
    );
  }

  Widget _buildEpisodesView(BuildContext context, Character character) {
    return BlocBuilder<EpisodeCubit, EpisodeState>(
      builder: (context, state) {
        if (state is EpisodeLoading || state is EpisodeInitial) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is EpisodeFailure) {
          return Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                  const SizedBox(width: 12),
                  Expanded(child: Text(state.message)),
                  TextButton(
                    onPressed: () => context.read<EpisodeCubit>().loadEpisodes(character),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final episodes = (state as EpisodeSuccess).episodes;
        if (episodes.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: Text('No episode details available.')),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: episodes.length,
          itemBuilder: (_, index) => EpisodeTile(episode: episodes[index]),
        );
      },
    );
  }

  Color _statusColor(String status) => switch (status.toLowerCase()) {
        'alive' => Colors.green,
        'dead' => Colors.red,
        _ => Colors.grey,
      };
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      color: color.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      );
}
