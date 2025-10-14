import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import '../models/event.dart';
import 'event_detail_page.dart';
import '../widgets/ads_carousel.dart';

class SummitPage extends StatefulWidget {
  const SummitPage({super.key});

  @override
  State<SummitPage> createState() => _SummitPageState();
}

class _SummitPageState extends State<SummitPage> {
  // Events data with proper image mapping from assets folder
  final List<Event> events = [
    Event(
      id: '1',
      title: "African FinTech Summit 2025",
      date: DateTime(2025, 11, 12, 10, 0),
      location: "Lagos, Nigeria",
      description: "Join the largest gathering of African FinTech innovators, investors, and thought leaders. Discover the latest trends in digital payments, blockchain technology, and financial inclusion across Africa.",
      longDescription: "The African FinTech Summit 2025 brings together over 500 industry leaders, startups, and investors to explore the rapidly evolving financial technology landscape in Africa. This premier event features keynote presentations, panel discussions, networking sessions, and product demonstrations from leading companies.\n\nKey topics include:\n• Digital Payment Solutions\n• Blockchain and Cryptocurrency\n• Financial Inclusion Initiatives\n• Regulatory Frameworks\n• Investment Opportunities\n• Mobile Banking Innovation\n\nDon't miss this opportunity to connect with industry pioneers and discover the future of finance in Africa.",
      isPaid: true,
      price: 150.00,
      currency: "USD",
      imageUrl: "assets/images/summit1.png",
      category: "FinTech",
      attendeeCount: 487,
      maxAttendees: 500,
    organizer: "CoinNewsExtra",
    organizerUrl: 'https://coinnewsextra.com/',
      tags: ["FinTech", "Blockchain", "Investment", "Innovation"],
      speakers: [
        {"name": "Dr. Amina Hassan", "title": "CEO, African FinTech Union"},
        {"name": "John Okafor", "title": "Blockchain Lead, Flutterwave"},
        {"name": "Sarah Ibrahim", "title": "Investment Director, TLcom Capital"},
      ],
    ),
    Event(
      id: '2',
      title: "Nigeria Fashion Week 2025",
      date: DateTime(2025, 12, 2, 14, 0),
      location: "Abuja, Nigeria",
      description: "CoinNewsExtra will be covering Africa's premier fashion showcase featuring top designers, models, and fashion innovators from across the continent.",
      longDescription: "Nigeria Fashion Week 2025 is the continent's most prestigious fashion event, showcasing the creativity and innovation of African designers. This year's theme focuses on sustainable fashion and the intersection of technology with traditional African aesthetics.\n\nEvent Highlights:\n• Runway shows from 50+ designers\n• Sustainable fashion workshops\n• Fashion technology exhibitions\n• Networking events for industry professionals\n• Pop-up shopping experiences\n• Photography and styling masterclasses\n\nCoinNewsExtra will provide exclusive behind-the-scenes coverage, designer interviews, and trend analysis throughout the event.",
      isPaid: false,
      price: 0,
      currency: "USD",
      imageUrl: "assets/images/summit2.png",
      category: "Fashion",
      attendeeCount: 1250,
      maxAttendees: 1500,
    organizer: "CoinNewsExtra",
    organizerUrl: 'https://coinnewsextra.com/',
      tags: ["Fashion", "Design", "Sustainability", "Culture"],
      speakers: [
        {"name": "Adunni Ade", "title": "Fashion Designer & Entrepreneur"},
        {"name": "Temi Otedola", "title": "Fashion Influencer & Actress"},
        {"name": "Mai Atafo", "title": "Creative Director, Mai Atafo Inspired"},
      ],
    ),
    Event(
      id: '3',
      title: "African Credit & Lending Expo 2025",
      date: DateTime(2025, 12, 15, 9, 0),
      location: "Cape Town, South Africa",
      description: "Exploring the future of digital credit, alternative lending, and blockchain-based financial services across African markets.",
      longDescription: "The African Credit & Lending Expo 2025 focuses on revolutionary changes in credit assessment, digital lending platforms, and blockchain-based financial services. Industry experts will discuss how technology is democratizing access to credit across African markets.\n\nExpo Features:\n• Credit scoring innovation workshops\n• Blockchain lending platforms demo\n• Regulatory compliance sessions\n• Alternative lending case studies\n• Partnership and networking opportunities\n• Investment pitch sessions\n\nThis event is essential for fintech entrepreneurs, traditional financial institutions, regulators, and investors looking to understand the evolving credit landscape in Africa.",
      isPaid: true,
      price: 200.00,
      currency: "USD",
      imageUrl: "assets/images/summit3.png",
      category: "Finance",
      attendeeCount: 312,
      maxAttendees: 400,
    organizer: "CoinNewsExtra",
    organizerUrl: 'https://coinnewsextra.com/',
      tags: ["Credit", "Lending", "Blockchain", "FinTech"],
      speakers: [
        {"name": "Michael Oluwasegun", "title": "CEO, Carbon (formerly Paylater)"},
        {"name": "Rebecca Enonchong", "title": "Founder, AppsTech"},
        {"name": "Kola Aina", "title": "Founder, Ventures Platform"},
      ],
    ),
  ];

  String selectedCategory = 'All';
  final List<String> categories = ['All', 'FinTech', 'Fashion', 'Finance', 'Technology'];

  // Helper method to get event image path based on ID - same as original implementation
  String _getEventImagePath(String eventId) {
    switch (eventId) {
      case '1':
        return 'assets/images/summit1.png';
      case '2':
        return 'assets/images/summit2.png';
      case '3':
        return 'assets/images/summit3.png';
      default:
        return 'assets/images/summit1.png';
    }
  }

  int _getListItemCount(List<Event> events) {
    if (events.isEmpty) return 0;
    if (events.length == 1) return 1;
    return events.length + 1; // +1 for the ad carousel after first event
  }

  Widget _buildListItem(BuildContext context, List<Event> events, int index) {
    if (events.length > 1 && index == 1) {
      // Show ad carousel after first event
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: AdsCarousel(),
      );
    }
    
    // Adjust event index if we've shown the ad carousel
    final eventIndex = events.length > 1 && index > 1 ? index - 1 : index;
    final event = events[eventIndex];
    return _buildEventCard(context, event);
  }

  @override
  Widget build(BuildContext context) {
    final filteredEvents = selectedCategory == 'All' 
        ? events 
        : events.where((event) => event.category == selectedCategory).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "Summit",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Lato',
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(FeatherIcons.search, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Search functionality coming soon!'),
                  backgroundColor: Color(0xFF006833),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header section with subtitle
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Discover exclusive events covered by CoinNewsExtra',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                    fontFamily: 'Lato',
                  ),
                ),
                const SizedBox(height: 16),
                
                // Category filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories.map((category) {
                      final isSelected = selectedCategory == category;
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(
                            category,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey[300],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Lato',
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              selectedCategory = category;
                            });
                          },
                          selectedColor: const Color(0xFF006833),
                          backgroundColor: Colors.grey[800],
                          side: BorderSide(
                            color: isSelected ? const Color(0xFF006833) : Colors.grey[700]!,
                            width: 1,
                          ),
                          showCheckmark: false,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          
          // Events list
          Expanded(
            child: filteredEvents.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: _getListItemCount(filteredEvents),
                    itemBuilder: (context, index) {
                      return _buildListItem(context, filteredEvents, index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, Event event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EventDetailPage(event: event),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Event image with proper mapping
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF006833).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF006833).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          _getEventImagePath(event.id),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              FeatherIcons.calendar,
                              color: Color(0xFF006833),
                              size: 32,
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Event details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Lato',
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          
                          // Date and location
                          Row(
                            children: [
                              Icon(
                                FeatherIcons.clock,
                                color: Colors.grey[400],
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDateTime(event.date),
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                  fontFamily: 'Lato',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          
                          Row(
                            children: [
                              Icon(
                                FeatherIcons.mapPin,
                                color: Colors.grey[400],
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  event.location,
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                    fontFamily: 'Lato',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Price tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: event.isPaid ? Colors.orange.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: event.isPaid ? Colors.orange.withOpacity(0.5) : Colors.green.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        event.isPaid ? '${event.price.toStringAsFixed(0)}' : 'FREE',
                        style: TextStyle(
                          color: event.isPaid ? Colors.orange : Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Lato',
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Description
                Text(
                  event.description,
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 13,
                    height: 1.4,
                    fontFamily: 'Lato',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 12),
                
                // Bottom row with category, attendees, and action
                Row(
                  children: [
                    // Category tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF006833).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        event.category,
                        style: const TextStyle(
                          color: Color(0xFF006833),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Lato',
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // Attendee count
                    Icon(
                      FeatherIcons.users,
                      color: Colors.grey[500],
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${event.attendeeCount}/${event.maxAttendees}',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 11,
                        fontFamily: 'Lato',
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // View details button
                    const Text(
                      'View Details',
                      style: TextStyle(
                        color: Color(0xFF006833),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Lato',
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      FeatherIcons.arrowRight,
                      color: Color(0xFF006833),
                      size: 14,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FeatherIcons.calendar,
            color: Colors.grey[600],
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'No events found',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'Lato',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back soon for upcoming events',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontFamily: 'Lato',
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    final day = date.day;
    final month = months[date.month - 1];
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    
    return '$day $month • $displayHour:$minute $period';
  }
}