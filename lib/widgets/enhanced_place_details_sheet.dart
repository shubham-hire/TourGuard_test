import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/place_model.dart';
import '../services/historical_info_service.dart';

class EnhancedPlaceDetailsSheet extends StatefulWidget {
  final Place place;
  final VoidCallback? onAddToItinerary;

  const EnhancedPlaceDetailsSheet({
    super.key,
    required this.place,
    this.onAddToItinerary,
  });

  @override
  State<EnhancedPlaceDetailsSheet> createState() => _EnhancedPlaceDetailsSheetState();
}

class _EnhancedPlaceDetailsSheetState extends State<EnhancedPlaceDetailsSheet> {
  Map<String, dynamic>? _historicalInfo;
  bool _loadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadHistoricalInfo();
  }

  Future<void> _loadHistoricalInfo() async {
    final info = await HistoricalInfoService.getHistoricalInfo(
      widget.place.name,
      widget.place.category,
      widget.place.latitude,
      widget.place.longitude,
    );
    
    if (mounted) {
      setState(() {
        _historicalInfo = info;
        _loadingHistory = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: widget.place.imageUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: const Icon(Icons.error),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Title and category
                  Text(
                    widget.place.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Ratings and status
                  Row(
                    children: [
                      Icon(Icons.star, size: 20, color: Colors.amber[700]),
                      const SizedBox(width: 4),
                      Text(
                        widget.place.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (widget.place.userRatingsTotal > 0) ...[
                        const SizedBox(width: 4),
                        Text(
                          '(${widget.place.userRatingsTotal})',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                      const SizedBox(width: 16),
                      Icon(
                        widget.place.isOpen ? Icons.circle : Icons.circle_outlined,
                        size: 12,
                        color: widget.place.isOpen ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.place.isOpen ? 'Open now' : 'Closed',
                        style: TextStyle(
                          color: widget.place.isOpen ? Colors.green[700] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Description
                  Text(
                    widget.place.description,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Historical Information
                  if (_loadingHistory)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_historicalInfo != null) ...[
                    _buildHistoricalSection(),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Add to itinerary button
                  if (widget.onAddToItinerary != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: widget.onAddToItinerary,
                        icon: const Icon(Icons.add_location_alt),
                        label: const Text('Add to My Itinerary'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoricalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with icon
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.history_edu, color: Colors.amber[800]),
            ),
            const SizedBox(width: 12),
            const Text(
              'Historical & Cultural Info',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Historical story
        if (_historicalInfo!['historicalStory'] != null)
          _buildInfoCard(
            Icons.auto_stories,
            'Historical Story',
            _historicalInfo!['historicalStory'],
            Colors.purple,
          ),
        
        const SizedBox(height: 12),
        
        // Cultural significance
        if (_historicalInfo!['culturalSignificance'] != null)
          _buildInfoCard(
            Icons.location_city,
            'Cultural Significance',
            _historicalInfo!['culturalSignificance'],
            Colors.blue,
          ),
        
        const SizedBox(height: 12),
        
        // Ratings
        Row(
          children: [
            if (_historicalInfo!['adventureRating'] != null)
              Expanded(
                child: _buildRatingCard(
                  'Adventure',
                  _historicalInfo!['adventureRating'],
                  Colors.orange,
                  Icons.hiking,
                ),
              ),
            const SizedBox(width: 12),
            if (_historicalInfo!['historicalRating'] != null)
              Expanded(
                child: _buildRatingCard(
                  'Historical',
                  _historicalInfo!['historicalRating'],
                  Colors.amber,
                  Icons.account_balance,
                ),
              ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Tips section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green[50]!, Colors.green[100]!],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb, color: Colors.green[700], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Insider Tips',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[900],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_historicalInfo!['bestTime'] != null) ...[
                _buildTipRow(Icons.access_time, _historicalInfo!['bestTime']),
                const SizedBox(height: 4),
              ],
              if (_historicalInfo!['localTip'] != null) ...[
                _buildTipRow(Icons.tips_and_updates, _historicalInfo!['localTip']),
                const SizedBox(height: 4),
              ],
              if (_historicalInfo!['funFact'] != null)
                _buildTipRow(Icons.celebration, _historicalInfo!['funFact']),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String content, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color.withOpacity(0.9),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingCard(String label, int rating, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.2)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return Icon(
                index < rating ? Icons.star : Icons.star_border,
                size: 16,
                color: color,
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTipRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.green[700]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[800],
            ),
          ),
        ),
      ],
    );
  }
}
