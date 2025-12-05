import 'package:flutter/material.dart';
import 'package:projectx/data/notifiers.dart';
import 'package:projectx/views/pages/expenses_page.dart';
import 'package:projectx/views/pages/home_page.dart';
import 'package:projectx/views/pages/items_page.dart';
import 'package:projectx/views/pages/profile_page.dart';
import 'package:projectx/views/widgets/drawer_widget.dart';
import 'package:projectx/views/widgets/navbar_widget.dart';

List<Widget> pages=[HomePage(),ItemsPage(),ExpensePage(),ProfilePage()];

class WidgetTree extends StatelessWidget {
  const WidgetTree({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("ProjectX"), centerTitle: true,),
        drawer: DrawerWidget(),
        body: ValueListenableBuilder(valueListenable: selectedPageNotifier, builder: (context, selectedPage, child) {
          return pages.elementAt(selectedPage);
        },),
        bottomNavigationBar: NavbarWidget(),
      );
  }
}