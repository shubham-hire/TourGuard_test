import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tourguard/core/constants/app_colors.dart';
import '../models/place_model.dart';
import 'enhanced_place_details_sheet.dart';

class PlaceCard extends StatefulWidget {
  final Place place;
  final VoidCallback? onAddToItinerary;

  const PlaceCard({super.key, required this.place, this.onAddToItinerary});

  @override
  State<PlaceCard> createState() => _PlaceCardState();
}

class _PlaceCardState extends State<PlaceCard> {
  bool _isExpanded = false;

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'tourist_attraction':
      case 'famous':
        return AppColors.saffron;
      case 'restaurant':
      case 'food':
        return Colors.orange;
      case 'amusement_park':
      case 'adventure':
        return Colors.redAccent;
      case 'park':
      case 'hidden-gem':
        return AppColors.indiaGreen;
      default:
        return AppColors.navyBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4), // Margin 0 to fit ListView padding
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // Slightly less rounded
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Image Section
              Hero(
                tag: widget.place.name,
                child: Container(
                  width: 76,  // Reduced from 84
                  height: 76, // Reduced from 84
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withOpacity(0.1)),
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(widget.place.imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // 2. Content Section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Star
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Expanded(
                           child: Text(
                             widget.place.name,
                             style: const TextStyle(
                               fontSize: 15, // Reduced from 16
                               fontWeight: FontWeight.bold,
                               color: AppColors.navyBlue,
                               height: 1.1,
                             ),
                             maxLines: 2,
                             overflow: TextOverflow.ellipsis,
                           ),
                         ),
                         Row(
                           children: [
                             const SizedBox(width: 4),
                             Icon(Icons.star_rounded, size: 16, color: Colors.amber[700]), // Reduced size
                             const SizedBox(width: 2),
                             Text(
                               widget.place.rating.toStringAsFixed(1),
                               style: const TextStyle(
                                 fontWeight: FontWeight.bold,
                                 fontSize: 13, // Reduced size
                                 color: AppColors.textDark,
                               ),
                             ),
                           ],
                         ),
                      ],
                    ),
                    const SizedBox(height: 4), // Reduced spacing

                    // Description
                    Text(
                      widget.place.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textDark.withOpacity(0.7),
                        height: 1.2, // Tighter line height
                      ),
                      maxLines: _isExpanded ? 10 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    if (!_isExpanded)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                             _isExpanded = true;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'Read More',
                            style: TextStyle(
                              color: AppColors.navyBlue.withOpacity(0.8),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          // 3. Bottom Actions
          const SizedBox(height: 4), // Reduced spacing from 8
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center, // Align center
            children: [
               GestureDetector(
                 onTap: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                 },
                 child: Container(
                   padding: const EdgeInsets.all(6), // Reduced padding
                   decoration: BoxDecoration(
                     color: Colors.grey[50],
                     shape: BoxShape.circle,
                     border: Border.all(color: Colors.grey.withOpacity(0.1)),
                   ),
                   child: AnimatedRotation(
                     turns: _isExpanded ? 0.5 : 0,
                     duration: const Duration(milliseconds: 300),
                     child: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey[600], size: 20),
                   ),
                 ),
               ),

               if (widget.onAddToItinerary != null)
                 SizedBox(
                   height: 36, // Force smaller height
                   child: ElevatedButton(
                      onPressed: widget.onAddToItinerary,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navyBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Add to Trip',
                        style: TextStyle(
                          fontSize: 13, // Reduced font size
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                   ),
                 )
                else
                  SizedBox(
                    height: 36,
                    child: OutlinedButton(
                       onPressed: () => _showPlaceDetails(context, widget.place),
                       style: OutlinedButton.styleFrom(
                         foregroundColor: AppColors.navyBlue,
                         side: const BorderSide(color: AppColors.navyBlue),
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                         padding: const EdgeInsets.symmetric(horizontal: 16),
                       ),
                       child: const Text('View', style: TextStyle(fontSize: 13)),
                    ),
                  ),
            ],
          ),

          if (_isExpanded) ...[
             const SizedBox(height: 12),
             Container(
               padding: const EdgeInsets.all(12),
               decoration: BoxDecoration(
                 color: AppColors.surfaceWhite,
                 borderRadius: BorderRadius.circular(12),
               ),
               child: Column(
                 children: [
                    _buildDetailRow(Icons.category_outlined, 'Category', widget.place.category),
                    const SizedBox(height: 8),
                    _buildDetailRow(Icons.access_time_rounded, 'Status', widget.place.isOpen ? 'Open Now' : 'Closed'),
                    const SizedBox(height: 8),
                    _buildDetailRow(Icons.location_on_outlined, 'Distance', '${widget.place.distance} away'),
                 ],
               ),
             ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textGrey),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.navyBlue),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showPlaceDetails(BuildContext context, Place place) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return EnhancedPlaceDetailsSheet(
            place: place,
            onAddToItinerary: widget.onAddToItinerary,
          );
        },
      ),
    );
  }
}