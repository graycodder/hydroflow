import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watermemo/core/bloc/connectivity/connectivity_bloc.dart';
import 'package:watermemo/core/bloc/connectivity/connectivity_state.dart';

class ConnectivityWrapper extends StatelessWidget {
  final Widget child;

  const ConnectivityWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BlocBuilder<ConnectivityBloc, ConnectivityState>(
          builder: (context, state) {
            if (state.status == ConnectivityStatus.disconnected) {
              return Material(
                color: Colors.red,
                child: Container(
                  width: double.infinity,
                  height: 40,
                  padding: const EdgeInsets.symmetric(vertical: 4),

                  child: const Center(
                    child: Text(
                      'No Internet Connection',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        Expanded(child: child),
      ],
    );
  }
}
