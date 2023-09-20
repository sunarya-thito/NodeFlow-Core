import 'package:flutter/material.dart';
import 'package:nodeflow/components/page_holder.dart';

class DebugPage extends StatelessWidget {
  const DebugPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SubNavigator(
      home: Builder(builder: (context) {
        return Scaffold(
          body: Center(
            child: Text('Debug Page'),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              SubNavigator.of(context).go(Builder(
                builder: (context) {
                  return Scaffold(
                    body: GestureDetector(
                      onTap: () {
                        SubNavigator.of(context).goBack();
                      },
                      child: Container(
                        color: Colors.red,
                      ),
                    ),
                  );
                },
              ));
            },
          ),
        );
      }),
    );
  }
}
