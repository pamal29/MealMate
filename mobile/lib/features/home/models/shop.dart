class Shop {
  final String id;
  final String name;
  final String category;
  final String location;
  final bool isOpen;
  final double rating;

  const Shop({
    required this.id,
    required this.name,
    required this.category,
    required this.location,
    required this.rating,
    required this.isOpen,
  });
}

//mockdata
const mockShops = [
  Shop(id: '1', name: 'Canteen Central', category: 'Rice & Curry', location: 'Main Canteen', rating: 4.5, isOpen: true),
  Shop(id: '2', name: 'Bite Corner', category: 'Snacks', location: 'Faculty Block A', rating: 4.2, isOpen: true),
  Shop(id: '3', name: 'Juice Bar', category: 'Beverages', location: 'Library Front', rating: 4.7, isOpen: true),
  Shop(id: '4', name: 'Night Bites', category: 'Fast Food', location: 'Hostel Road', rating: 4.0, isOpen: false),
];