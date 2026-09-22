import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:learn_bloc/business_logic/cubit/home_cubit.dart';
import 'package:learn_bloc/business_logic/cubit/home_state.dart';
import 'package:learn_bloc/consteins/strings.dart';
import 'package:learn_bloc/data/models/model.dart';
import 'package:learn_bloc/presentation/widgets/stat_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.public, color: colorScheme.primary, size: 22),
            ),
            const SizedBox(width: 10),
            const Text('Rick & Morty', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Random Character',
            icon: const Icon(Icons.casino_outlined),
            onPressed: () => _openRandomCharacter(context),
          ),
          IconButton(
            tooltip: 'Explore Characters',
            icon: const Icon(Icons.explore_outlined),
            onPressed: () => Navigator.of(context).pushNamed(charactersScreen),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<HomeCubit>().loadHomeData(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _buildAboutCard(context),
            const SizedBox(height: 24),
            _buildStatisticsSection(context),
            const SizedBox(height: 24),
            _buildFeaturedSection(context),
            const SizedBox(height: 24),
            _buildExploreBanner(context),
          ],
        ),
      ),
    );
  }

  void _openRandomCharacter(BuildContext context) {
    final randomChar = context.read<HomeCubit>().getRandomCharacter();
    if (randomChar != null) {
      Navigator.of(context).pushNamed(charactersDetails, arguments: randomChar);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loading characters, please wait a moment...')),
      );
    }
  }

  Widget _buildAboutCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.primary.withValues(alpha: 0.25),
        ),
      ),
      color: colorScheme.primaryContainer.withValues(alpha: 0.25),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'About Rick & Morty',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'An animated cosmic adventure tracking cynical genius scientist Rick Sanchez and his grandson Morty Smith across infinite dimensions, surreal galaxies, and bizarre alternate realities.',
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.45,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Show Overview',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            if (state.isLoadingStats && state.statistics == null) {
              return const SizedBox(
                height: 140,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (state.statsError != null && state.statistics == null) {
              return Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(child: Text(state.statsError!)),
                      TextButton(
                        onPressed: () => context.read<HomeCubit>().loadStatistics(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final stats = state.statistics;
            final charCount = stats?.totalCharacters.toString() ?? '826';
            final locCount = stats?.totalLocations.toString() ?? '126';
            final epCount = stats?.totalEpisodes.toString() ?? '51';
            final seasonCount = stats?.totalSeasons.toString() ?? '5';

            return LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 600;
                return GridView.count(
                  crossAxisCount: isWide ? 4 : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: isWide ? 1.6 : 1.4,
                  children: [
                    StatCard(
                      title: 'Characters',
                      value: charCount,
                      icon: Icons.people_outline,
                      color: const Color(0xFF42B883),
                    ),
                    StatCard(
                      title: 'Locations',
                      value: locCount,
                      icon: Icons.place_outlined,
                      color: const Color(0xFF38A3A5),
                    ),
                    StatCard(
                      title: 'Episodes',
                      value: epCount,
                      icon: Icons.movie_outlined,
                      color: const Color(0xFF57CC99),
                    ),
                    StatCard(
                      title: 'Seasons',
                      value: seasonCount,
                      icon: Icons.live_tv_outlined,
                      color: const Color(0xFF80ED99),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildFeaturedSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Featured Characters',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pushNamed(charactersScreen),
              child: const Text('View all'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            if (state.isLoadingFeatured && state.featuredCharacters.isEmpty) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (state.featuredError != null && state.featuredCharacters.isEmpty) {
              return Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(child: Text(state.featuredError!)),
                      TextButton(
                        onPressed: () => context.read<HomeCubit>().loadFeaturedCharacters(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final characters = state.featuredCharacters;
            if (characters.isEmpty) return const SizedBox.shrink();

            return SizedBox(
              height: 210,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: characters.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final character = characters[index];
                  return _FeaturedCharacterCard(character: character);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildExploreBanner(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary,
              colorScheme.primary.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.travel_explore, color: Colors.white, size: 32),
            const SizedBox(height: 12),
            Text(
              'Explore the Multiverse',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Search and filter hundreds of characters with real-time infinite pagination.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () => Navigator.of(context).pushNamed(charactersScreen),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: colorScheme.primary,
              ),
              child: const Text('Explore Characters', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedCharacterCard extends StatelessWidget {
  const _FeaturedCharacterCard({required this.character});
  final Character character;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => Navigator.of(context).pushNamed(
          charactersDetails,
          arguments: character,
        ),
        child: SizedBox(
          width: 140,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Hero(
                  tag: 'featured-${character.id}',
                  child: Image.network(
                    character.image,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Center(
                      child: Icon(Icons.broken_image_outlined),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 2),
                child: Text(
                  character.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: _statusColor(character.status),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        character.species,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) => switch (status.toLowerCase()) {
        'alive' => Colors.green,
        'dead' => Colors.red,
        _ => Colors.grey,
      };
}
