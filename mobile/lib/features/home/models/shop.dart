class Shop {
  final String id;
  final String name;
  final String category;
  final String location;
  final bool isOpen;
  final double rating;
  final String imageAsset;
  final String preparationTime;

  const Shop({
    required this.id,
    required this.name,
    required this.category,
    required this.location,
    required this.rating,
    required this.isOpen,
    required this.imageAsset,
    this.preparationTime = '10–15 mins',
  });
}

// Preview content from the supplied screen; these are not live shop listings.
const mockShops = [
  Shop(
    id: '1',
    name: 'Royal Box',
    category: 'Rice & Curry',
    location: 'Campus',
    rating: 4.5,
    isOpen: true,
    imageAsset: 'assets/shops/royal-box.jpg',
  ),
  Shop(
    id: '2',
    name: 'Shan Food Cabin',
    category: 'Short Eats',
    location: 'Campus',
    rating: 4.2,
    isOpen: true,
    imageAsset: 'assets/shops/shan-food-cabin.jpg',
  ),
  Shop(
    id: '3',
    name: 'Eat Art',
    category: 'Beverages',
    location: 'Campus',
    rating: 4.7,
    isOpen: true,
    imageAsset: 'assets/shops/eat-art.jpg',
  ),
];
