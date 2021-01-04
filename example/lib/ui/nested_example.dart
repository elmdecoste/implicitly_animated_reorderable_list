import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:implicitly_animated_reorderable_list/transitions.dart';

class VerticalNestedExample extends StatefulWidget {
  const VerticalNestedExample();

  @override
  State<StatefulWidget> createState() => VerticalNestedExampleState();
}

class VerticalNestedExampleState extends State<VerticalNestedExample> {
  static const maxLength = 1000;

  List<int> nestedList = List.generate(maxLength, (i) => i);

  @override
  void initState() {
    super.initState();

    Timer.periodic(
      const Duration(milliseconds: 1500),
      (_) async {
        nestedList = List.generate(Random().nextInt(maxLength), (i) => i)..shuffle();
        setState(() {});
        await Future.delayed(const Duration(milliseconds: 500));
        nestedList = List.generate(Random().nextInt(maxLength), (i) => i)..shuffle();
        setState(() {});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.amber),
      body: ImplicitlyAnimatedReorderableList<int>(
        padding: const EdgeInsets.all(24),
        items: nestedList,
        areItemsTheSame: (oldItem, newItem) => oldItem == newItem,
        onReorderFinished: (item, from, to, newList) {
          setState(() {
            nestedList
              ..clear()
              ..addAll(newList);
          });
        },
        header: Container(
          height: 120,
          color: Colors.red,
          child: Center(
            child: Text(
              'Header',
              style: textTheme.headline6.copyWith(color: Colors.white),
            ),
          ),
        ),
        footer: Container(
          height: 120,
          color: Colors.red,
          child: Center(
            child: Text(
              'Footer',
              style: textTheme.headline6.copyWith(color: Colors.white),
            ),
          ),
        ),
        itemBuilder: (context, itemAnimation, item, index) {
          return Reorderable(
            key: ValueKey(item),
            builder: (context, dragAnimation, inDrag) => AnimatedBuilder(
              animation: dragAnimation,
              builder: (context, child) => Card(
                elevation: 4,
                // SizeFadeTransition clips, so use the
                // Card as a parent to avoid the box shadow
                // to be clipped.
                child: SizeFadeTransition(
                  animation: itemAnimation,
                  child: Handle(
                    delay: const Duration(milliseconds: 600),
                    child: Container(
                      height: 120,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text('$item'),
                          /* const Handle(
                            child: Icon(Icons.menu),
                            capturePointer: true,
                          ), */
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
