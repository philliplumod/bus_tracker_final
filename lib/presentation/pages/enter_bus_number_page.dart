import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/bus_search/bus_search_bloc.dart';
import '../bloc/bus_search/bus_search_event.dart';
import '../bloc/bus_search/bus_search_state.dart';
import 'bus_route_page.dart';

class EnterBusNumberPage extends StatefulWidget {
  const EnterBusNumberPage({super.key});

  @override
  State<EnterBusNumberPage> createState() => _EnterBusNumberPageState();
}

class _EnterBusNumberPageState extends State<EnterBusNumberPage> {
  final TextEditingController _busNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<BusSearchBloc>().add(LoadAllBuses());
      }
    });
  }

  @override
  void dispose() {
    _busNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter Bus Number')),
      body: BlocBuilder<BusSearchBloc, BusSearchState>(
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Search for a Bus',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _busNumberController,
                          decoration: InputDecoration(
                            hintText: 'Enter bus number',
                            prefixIcon: const Icon(Icons.directions_bus),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onSubmitted:
                              (_) => context.read<BusSearchBloc>().add(
                                SearchBusByNumber(_busNumberController.text),
                              ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            if (_busNumberController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter a bus number'),
                                ),
                              );
                              return;
                            }
                            context.read<BusSearchBloc>().add(
                              SearchBusByNumber(_busNumberController.text),
                            );
                          },
                          icon: const Icon(Icons.search),
                          label: const Text('Search'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(child: _buildResultsList(state)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultsList(BusSearchState state) {
    if (state is BusSearchLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading buses...'),
          ],
        ),
      );
    }

    if (state is BusSearchError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Error: ${state.message}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (state is! BusSearchLoaded) {
      return const SizedBox();
    }

    if (!state.hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Enter a bus number to search',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (state.filteredBuses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bus_alert, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No buses found matching "${state.searchQuery}"',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Try refreshing or searching for another bus number',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: state.filteredBuses.length,
      itemBuilder: (context, index) {
        final bus = state.filteredBuses[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.directions_bus, color: Colors.white),
            ),
            title: Text(
              bus.busNumber != null ? 'Bus ${bus.busNumber}' : 'Bus ${bus.id}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (bus.route != null)
                  Text('Route: ${bus.route}')
                else
                  const Text('Route: Not specified'),
                Text(
                  'Speed: ${bus.speed.toStringAsFixed(1)} km/h',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BusRoutePage(bus: bus)),
              );
            },
          ),
        );
      },
    );
  }
}
