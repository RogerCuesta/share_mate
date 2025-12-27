// lib/features/friends/presentation/screens/friends_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_project_agents/features/friends/presentation/providers/friends_list_provider.dart';
import 'package:flutter_project_agents/features/friends/presentation/providers/pending_requests_provider.dart';
import 'package:flutter_project_agents/features/friends/presentation/widgets/friend_list_item.dart';
import 'package:flutter_project_agents/features/friends/presentation/widgets/friend_request_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Friends screen with tabs for Friends and Pending Requests
class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1E),
        elevation: 0,
        title: const Text(
          'Friends',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, color: Color(0xFF6B4FBB)),
            onPressed: () => context.push('/add-friend'),
            tooltip: 'Add Friend',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF6B4FBB),
          labelColor: const Color(0xFF6B4FBB),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Friends'),
            Tab(text: 'Requests'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _FriendsTab(),
          _RequestsTab(),
        ],
      ),
    );
  }
}

/// Tab showing the friends list
class _FriendsTab extends ConsumerWidget {
  const _FriendsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(friendsListProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(friendsListProvider.future),
      color: const Color(0xFF6B4FBB),
      backgroundColor: const Color(0xFF1E1E2E),
      child: friendsAsync.when(
        data: (friends) {
          if (friends.isEmpty) {
            return _buildEmptyState(
              icon: Icons.people_outline,
              title: 'No Friends Yet',
              message: 'Add friends to see them here',
              actionLabel: 'Add Friend',
              onAction: () => context.push('/add-friend'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: friends.length,
            itemBuilder: (context, index) {
              return FriendListItem(friend: friends[index]);
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF6B4FBB),
          ),
        ),
        error: (error, stack) => _buildErrorState(
          error: error.toString(),
          onRetry: () => ref.invalidate(friendsListProvider),
        ),
      ),
    );
  }
}

/// Tab showing pending friend requests
class _RequestsTab extends ConsumerWidget {
  const _RequestsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(pendingRequestsProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(pendingRequestsProvider.future),
      color: const Color(0xFF6B4FBB),
      backgroundColor: const Color(0xFF1E1E2E),
      child: requestsAsync.when(
        data: (requests) {
          if (requests.isEmpty) {
            return _buildEmptyState(
              icon: Icons.inbox_outlined,
              title: 'No Pending Requests',
              message: 'Friend requests will appear here',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              return FriendRequestCard(request: requests[index]);
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF6B4FBB),
          ),
        ),
        error: (error, stack) => _buildErrorState(
          error: error.toString(),
          onRetry: () => ref.invalidate(pendingRequestsProvider),
        ),
      ),
    );
  }
}

/// Build empty state widget
Widget _buildEmptyState({
  required IconData icon,
  required String title,
  required String message,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey[700],
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.person_add),
              label: Text(actionLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B4FBB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

/// Build error state widget
Widget _buildErrorState({
  required String error,
  required VoidCallback onRetry,
}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red[300],
          ),
          const SizedBox(height: 24),
          const Text(
            'Oops! Something went wrong',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B4FBB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
