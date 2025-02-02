import 'package:flutter/material.dart';

class WarningMsgScreen<T> extends StatelessWidget {
  final T state; // Generic state parameter
  final Future<void> Function() onRefresh; // Callback for refresh
  final String msg;

  const WarningMsgScreen({
    super.key,
    required this.state,
    required this.onRefresh,
    required this.msg,
  });

  @override
  Widget build(BuildContext context) {
    // Assume `state.error` exists. You can further refine for type safety.
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Container(
                height: MediaQuery.of(context).size.height,
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      msg, // Cast to dynamic to access error
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18,color: Colors.black,),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
