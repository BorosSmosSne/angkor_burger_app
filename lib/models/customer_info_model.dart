class CustomerInfoModel {
  final String fullName;
  final String phoneNumber;
  final String? email;
  final String address;
  final String? buildingFloor;
  final String? noteToDriver;

  CustomerInfoModel({
    required this.fullName,
    required this.phoneNumber,
    this.email,
    required this.address,
    this.buildingFloor,
    this.noteToDriver,
  });
}
