import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/event.dart';

class EventDetailPage extends StatefulWidget {
  final Event event;

  const EventDetailPage({super.key, required this.event});

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  bool isRegistered = false;

  Widget _buildEventImage() {
    // Map event IDs to summit images - same as original implementation
    String getImagePath() {
      switch (widget.event.id) {
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

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          getImagePath(),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: const Color(0xFF006833).withOpacity(0.3),
              child: const Center(
                child: Icon(
                  FeatherIcons.calendar,
                  color: Colors.white,
                  size: 80,
                ),
              ),
            );
          },
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.8),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          // App bar with hero image
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: Colors.black,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(FeatherIcons.share2, color: Colors.white),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Share functionality coming soon!'),
                        backgroundColor: Color(0xFF006833),
                      ),
                    );
                  },
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _buildEventImage(),
            ),
          ),
          
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event title and basic info
                  _buildEventHeader(),
                  
                  const SizedBox(height: 24),
                  
                  // Key details section
                  _buildKeyDetailsSection(),
                  
                  const SizedBox(height: 24),
                  
                  // About section
                  _buildAboutSection(),
                  
                  const SizedBox(height: 24),
                  
                  // Speakers section
                  _buildSpeakersSection(),
                  
                  const SizedBox(height: 24),
                  
                  // Tags section
                  _buildTagsSection(),
                  
                  const SizedBox(height: 32),
                  
                  // Registration button
                  _buildRegistrationButton(),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category and price
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF006833).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF006833).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                widget.event.category.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF006833),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  fontFamily: 'Lato',
                ),
              ),
            ),
            
            const Spacer(),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: widget.event.isPaid ? Colors.orange.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: widget.event.isPaid ? Colors.orange.withOpacity(0.5) : Colors.green.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Text(
                widget.event.isPaid ? '${widget.event.price.toStringAsFixed(0)}' : 'FREE',
                style: TextStyle(
                  color: widget.event.isPaid ? Colors.orange : Colors.green,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Lato',
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Event title
        Text(
          widget.event.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            height: 1.3,
            fontFamily: 'Lato',
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Organizer
        Row(
          children: [
            Text(
              'Organized by ',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
                fontFamily: 'Lato',
              ),
            ),
            Text(
              widget.event.organizer,
              style: const TextStyle(
                color: Color(0xFF006833),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Lato',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKeyDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Event Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Lato',
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Date and time
        _buildDetailItem(
          FeatherIcons.calendar,
          'Date & Time',
          _formatFullDateTime(widget.event.date),
        ),
        
        const SizedBox(height: 12),
        
        // Location
        _buildDetailItem(
          FeatherIcons.mapPin,
          'Location',
          widget.event.location,
        ),
        
        const SizedBox(height: 12),
        
        // Attendees
        _buildDetailItem(
          FeatherIcons.users,
          'Attendees',
          '${widget.event.attendeeCount} of ${widget.event.maxAttendees} registered',
        ),
        
        const SizedBox(height: 16),
        
        // Attendance progress bar
        _buildAttendanceProgress(),
      ],
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: const Color(0xFF006833),
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Lato',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'Lato',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceProgress() {
    final progress = widget.event.attendeeCount / widget.event.maxAttendees;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Registration Progress',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Lato',
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: const TextStyle(
                color: Color(0xFF006833),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'Lato',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(3),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.transparent,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF006833)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'About This Event',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Lato',
          ),
        ),
        
        const SizedBox(height: 12),
        
        Text(
          widget.event.longDescription,
          style: TextStyle(
            color: Colors.grey[300],
            fontSize: 14,
            height: 1.6,
            fontFamily: 'Lato',
          ),
        ),
      ],
    );
  }

  Widget _buildSpeakersSection() {
    if (widget.event.speakers.isEmpty) return const SizedBox();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Featured Speakers',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Lato',
          ),
        ),
        
        const SizedBox(height: 16),
        
        ...widget.event.speakers.map((speaker) => _buildSpeakerItem(speaker)).toList(),
      ],
    );
  }

  Widget _buildSpeakerItem(Map<String, String> speaker) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[800]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Speaker avatar placeholder
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF006833).withOpacity(0.2),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFF006833).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: const Icon(
              FeatherIcons.user,
              color: Color(0xFF006833),
              size: 24,
            ),
          ),
          
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  speaker['name'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Lato',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  speaker['title'] ?? '',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontFamily: 'Lato',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection() {
    if (widget.event.tags.isEmpty) return const SizedBox();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tags',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Lato',
          ),
        ),
        
        const SizedBox(height: 12),
        
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.event.tags.map((tag) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey[700]!,
                  width: 1,
                ),
              ),
              child: Text(
                '#$tag',
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 12,
                  fontFamily: 'Lato',
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRegistrationButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () async {
          // If an organizer URL is provided, open it in external browser
          // Prefer the event's organizerUrl, but fall back to the company site
          final defaultUrl = 'https://coinnewsextra.com/';
          final urlString = (widget.event.organizerUrl != null && widget.event.organizerUrl!.isNotEmpty)
              ? widget.event.organizerUrl!
              : defaultUrl;

          final uri = Uri.tryParse(urlString);
          if (uri != null && await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            return;
          }

          // Fallback: toggle registration locally
          setState(() {
            isRegistered = !isRegistered;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isRegistered 
                    ? 'Successfully registered for ${widget.event.title}!' 
                    : 'Registration cancelled',
              ),
              backgroundColor: isRegistered ? const Color(0xFF006833) : Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isRegistered ? Colors.orange : const Color(0xFF006833),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isRegistered ? FeatherIcons.check : FeatherIcons.calendar,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              isRegistered ? 'Registered' : (widget.event.isPaid ? 'Register - ${widget.event.price.toStringAsFixed(0)}' : 'Register for Free'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Lato',
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatFullDateTime(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    final weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    
    final weekday = weekdays[date.weekday - 1];
    final day = date.day;
    final month = months[date.month - 1];
    final year = date.year;
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    
    return '$weekday, $month $day, $year at $displayHour:$minute $period';
  }
}