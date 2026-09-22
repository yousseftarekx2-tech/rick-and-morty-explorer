import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:learn_bloc/business_logic/cubit/charcters_cubit.dart';
import 'package:learn_bloc/consteins/strings.dart';
import 'package:learn_bloc/data/models/model.dart';
import 'package:learn_bloc/presentation/widgets/character_skeleton.dart';
import 'package:learn_bloc/presentation/widgets/filter_bottom_sheet.dart';

class CharacterScreen extends StatefulWidget {
  const CharacterScreen({super.key});

  @override
  State<CharacterScreen> createState() => _CharacterScreenState();
}

class _CharacterScreenState extends State<CharacterScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= maxScroll - 300) {
      context.read<CharctersCubit>().loadNextPage();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        context.read<CharctersCubit>().clearSearch();
      }
    });
  }

  void _openFilters(CharctersSuccess state) {
    FilterBottomSheet.show(
      context: context,
      currentFilter: state.filter,
      availableLocations: state.availableLocations,
      onApply: (newFilter) => context.read<CharctersCubit>().updateFilter(newFilter),
    );
  }

  void _openRandomCharacter() {
    final randomChar = context.read<CharctersCubit>().getRandomLoadedCharacter();
    if (randomChar != null) {
      Navigator.of(context).pushNamed(charactersDetails, arguments: randomChar);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No characters loaded yet')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CharctersCubit, CharctersState>(
      builder: (context, state) {
        final successState = state is CharctersSuccess ? state : null;

        return Scaffold(
          appBar: AppBar(
            title: _isSearching
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Search character name...',
                      border: InputBorder.none,
                    ),
                    onChanged: (val) => context.read<CharctersCubit>().updateSearchQuery(val),
                  )
                : const Text('Characters Explorer', style: TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              if (_isSearching)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<CharctersCubit>().clearSearch();
                  },
                )
              else
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _toggleSearch,
                ),
              if (successState != null) ...[
                IconButton(
                  tooltip: 'Random Character',
                  icon: const Icon(Icons.casino_outlined),
                  onPressed: _openRandomCharacter,
                ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      tooltip: 'Filter',
                      icon: const Icon(Icons.filter_list_rounded),
                      onPressed: () => _openFilters(successState),
                    ),
                    if (successState.isFilterActive)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Text(
                            '${successState.filter.activeCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, CharctersState state) {
    if (state is CharctersLoading || state is CharctersInitial) {
      return const CharacterSkeletonGrid();
    }

    if (state is CharctersFailure) {
      return _MessageState(
        icon: Icons.wifi_off_rounded,
        message: state.message,
        action: 'Try again',
        onPressed: () => context.read<CharctersCubit>().loadCharacters(),
      );
    }

    if (state is CharctersEmpty) {
      return const _MessageState(
        icon: Icons.person_search_outlined,
        message: 'No characters found in the catalog.',
      );
    }

    final successState = state as CharctersSuccess;
    final displayed = successState.displayedCharacters;

    if (displayed.isEmpty) {
      return _buildEmptySearchOrFilter(context, successState);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1200
            ? 5
            : constraints.maxWidth >= 840
                ? 4
                : constraints.maxWidth >= 600
                    ? 3
                    : 2;

        return RefreshIndicator(
          onRefresh: () => context.read<CharctersCubit>().loadCharacters(),
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (successState.hasFiltersOrSearch)
                SliverToBoxAdapter(
                  child: _buildActiveFilterBar(context, successState),
                ),
              SliverPadding(
                padding: const EdgeInsets.all(14),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: .62,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _CharacterCard(
                      key: ValueKey(displayed[index].id),
                      character: displayed[index],
                    ),
                    childCount: displayed.length,
                  ),
                ),
              ),
              if (successState.isLoadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              if (successState.paginationError != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            successState.paginationError!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          FilledButton.tonalIcon(
                            onPressed: () => context.read<CharctersCubit>().loadNextPage(),
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Retry loading next page'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActiveFilterBar(BuildContext context, CharctersSuccess state) {
    final chips = <Widget>[];

    if (state.isSearchActive) {
      chips.add(
        InputChip(
          label: Text('Search: "${state.searchQuery}"'),
          onDeleted: () {
            _searchController.clear();
            context.read<CharctersCubit>().clearSearch();
          },
        ),
      );
    }

    if (state.filter.status != null && state.filter.status != 'All') {
      chips.add(
        InputChip(
          label: Text('Status: ${state.filter.status}'),
          onDeleted: () => context.read<CharctersCubit>().updateFilter(
                state.filter.copyWith(clearStatus: true),
              ),
        ),
      );
    }

    if (state.filter.species != null && state.filter.species != 'All') {
      chips.add(
        InputChip(
          label: Text('Species: ${state.filter.species}'),
          onDeleted: () => context.read<CharctersCubit>().updateFilter(
                state.filter.copyWith(clearSpecies: true),
              ),
        ),
      );
    }

    if (state.filter.location != null && state.filter.location != 'All') {
      chips.add(
        InputChip(
          label: Text('Location: ${state.filter.location}'),
          onDeleted: () => context.read<CharctersCubit>().updateFilter(
                state.filter.copyWith(clearLocation: true),
              ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: chips
                    .map((c) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: c,
                        ))
                    .toList(),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              _searchController.clear();
              context.read<CharctersCubit>().clearSearch();
              context.read<CharctersCubit>().clearFilters();
            },
            child: const Text('Clear all', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySearchOrFilter(BuildContext context, CharctersSuccess state) {
    final hasMore = state.hasMore;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No matches in loaded characters',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              hasMore
                  ? 'More characters may exist in subsequent pages of the catalog.'
                  : 'Try adjusting your search query or filters.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton(
                  onPressed: () {
                    _searchController.clear();
                    context.read<CharctersCubit>().clearSearch();
                    context.read<CharctersCubit>().clearFilters();
                  },
                  child: const Text('Clear Filters & Search'),
                ),
                if (hasMore) ...[
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: state.isLoadingMore
                        ? null
                        : () => context.read<CharctersCubit>().loadNextPage(),
                    icon: state.isLoadingMore
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Load More Pages'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CharacterCard extends StatefulWidget {
  const _CharacterCard({super.key, required this.character});
  final Character character;

  @override
  State<_CharacterCard> createState() => _CharacterCardState();
}

class _CharacterCardState extends State<_CharacterCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final char = widget.character;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: () => Navigator.of(context).pushNamed(
            charactersDetails,
            arguments: char,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Hero(
                  tag: 'char-${char.id}',
                  child: Image.network(
                    char.image,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Center(
                      child: Icon(Icons.broken_image_outlined, size: 40),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
                child: Text(
                  char.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _statusColor(char.status),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${char.status} • ${char.species}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 2, 12, 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.place_outlined,
                      size: 14,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        char.location.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
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

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.message,
    this.action,
    this.onPressed,
  });

  final IconData icon;
  final String message;
  final String? action;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 52),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
              if (action != null) ...[
                const SizedBox(height: 16),
                FilledButton(onPressed: onPressed, child: Text(action!)),
              ],
            ],
          ),
        ),
      );
}
