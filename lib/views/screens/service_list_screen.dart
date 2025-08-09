import 'package:flutter/material.dart';
import 'package:scooby_app_new/models/service_provider.dart';
//import 'package:scooby_app_new/views/screens/home_screen.dart';
//import 'service_details_screen.dart';

class ServiceListScreen extends StatelessWidget {
  final String category;
  final List<ServiceProvider> services;

  const ServiceListScreen({
    super.key,
    required this.category,
    required this.services,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(category)),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, childAspectRatio: 0.8, crossAxisSpacing: 12, mainAxisSpacing: 12,
        ),
        itemCount: services.length,
        itemBuilder: (context, index) {
          return null;
        
         // return ServiceCard(
           // provider: services[index],
          //  onTap: () {
            //  Navigator.push(
             //   context,
             //   MaterialPageRoute(
              //    builder: (_) => ServiceDetailsScreen(serviceProvider: services[index]),
              //  ),
            //  );
          //  }, name: '', category: '', imageUrl: '',
        //  );
        },
    ),
    );
  
  }
}

