/**
 * Security Hardening Implementation for Mainnet Operations
 * 
 * This script implements comprehensive security measures including:
 * - Rate limiting and DDoS protection
 * - Fraud detection and anomaly monitoring
 * - Enhanced validation and input sanitization
 * - Security monitoring and alerting
 * - Audit logging and compliance
 */

const admin = require('firebase-admin');

class SecurityHardening {
    constructor() {
        this.securityConfig = {
            // Rate Limiting Configuration
            rateLimits: {
                rewards: {
                    maxPerMinute: 10,
                    maxPerHour: 100,
                    maxPerDay: 1000
                },
                transfers: {
                    maxPerMinute: 5,
                    maxPerHour: 50,
                    maxPerDay: 500
                },
                api: {
                    maxPerMinute: 60,
                    maxPerHour: 1000,
                    maxPerDay: 10000
                }
            },

            // Fraud Detection Thresholds
            fraudDetection: {
                suspiciousAmountThreshold: 100000, // CNE tokens
                rapidTransactionThreshold: 10, // transactions per minute
                maxDailyRewards: 1000, // CNE tokens per user per day
                maxTokenTransfer: 500000, // Maximum single transfer
                velocityCheckMinutes: 15
            },

            // Security Validation Rules
            validation: {
                minAccountAge: 24 * 60 * 60 * 1000, // 24 hours in milliseconds
                requireKyc: false, // Can be enabled for high-value operations
                ipWhitelist: [], // Empty means all IPs allowed
                requireMfa: true, // Multi-factor authentication for admin operations
                maxConcurrentSessions: 3
            },

            // Monitoring Configuration
            monitoring: {
                enableRealTimeAlerts: true,
                alertWebhook: process.env.SECURITY_WEBHOOK_URL,
                logLevel: 'info',
                enableAuditTrail: true,
                enableMetrics: true
            }
        };

        this.db = admin.firestore();
        this.rateLimitCache = new Map();
        this.fraudDetectionCache = new Map();
    }

    /**
     * Rate Limiting Implementation
     */
    async checkRateLimit(userId, operation, customLimits = null) {
        const limits = customLimits || this.securityConfig.rateLimits[operation];
        if (!limits) {
            throw new Error(`Rate limits not configured for operation: ${operation}`);
        }

        const now = Date.now();
        const cacheKey = `${userId}:${operation}`;
        
        // Get existing rate limit data
        let rateLimitData = this.rateLimitCache.get(cacheKey) || {
            minute: { count: 0, resetTime: now + 60000 },
            hour: { count: 0, resetTime: now + 3600000 },
            day: { count: 0, resetTime: now + 86400000 }
        };

        // Reset counters if time windows have passed
        if (now > rateLimitData.minute.resetTime) {
            rateLimitData.minute = { count: 0, resetTime: now + 60000 };
        }
        if (now > rateLimitData.hour.resetTime) {
            rateLimitData.hour = { count: 0, resetTime: now + 3600000 };
        }
        if (now > rateLimitData.day.resetTime) {
            rateLimitData.day = { count: 0, resetTime: now + 86400000 };
        }

        // Check against limits
        const violations = [];
        if (rateLimitData.minute.count >= limits.maxPerMinute) {
            violations.push({ type: 'minute', limit: limits.maxPerMinute, current: rateLimitData.minute.count });
        }
        if (rateLimitData.hour.count >= limits.maxPerHour) {
            violations.push({ type: 'hour', limit: limits.maxPerHour, current: rateLimitData.hour.count });
        }
        if (rateLimitData.day.count >= limits.maxPerDay) {
            violations.push({ type: 'day', limit: limits.maxPerDay, current: rateLimitData.day.count });
        }

        if (violations.length > 0) {
            await this.logSecurityEvent('RATE_LIMIT_EXCEEDED', {
                userId,
                operation,
                violations,
                timestamp: now
            });

            return {
                allowed: false,
                violations,
                resetTimes: {
                    minute: rateLimitData.minute.resetTime,
                    hour: rateLimitData.hour.resetTime,
                    day: rateLimitData.day.resetTime
                }
            };
        }

        // Increment counters
        rateLimitData.minute.count++;
        rateLimitData.hour.count++;
        rateLimitData.day.count++;

        // Update cache
        this.rateLimitCache.set(cacheKey, rateLimitData);

        return { allowed: true, remaining: {
            minute: limits.maxPerMinute - rateLimitData.minute.count,
            hour: limits.maxPerHour - rateLimitData.hour.count,
            day: limits.maxPerDay - rateLimitData.day.count
        }};
    }

    /**
     * Fraud Detection System
     */
    async detectFraud(userId, operation, data) {
        const fraudScore = await this.calculateFraudScore(userId, operation, data);
        const isHighRisk = fraudScore > 0.7;
        const isSuspicious = fraudScore > 0.4;

        const result = {
            userId,
            operation,
            fraudScore,
            riskLevel: isHighRisk ? 'HIGH' : (isSuspicious ? 'MEDIUM' : 'LOW'),
            allowed: !isHighRisk,
            requiresReview: isSuspicious || isHighRisk,
            factors: []
        };

        // Log fraud detection results
        if (isSuspicious) {
            await this.logSecurityEvent('FRAUD_DETECTION', {
                ...result,
                data,
                timestamp: Date.now()
            });
        }

        return result;
    }

    /**
     * Calculate fraud risk score (0-1, higher is more suspicious)
     */
    async calculateFraudScore(userId, operation, data) {
        let score = 0;
        const factors = [];

        try {
            // Check transaction velocity
            const velocity = await this.checkTransactionVelocity(userId);
            if (velocity > this.securityConfig.fraudDetection.rapidTransactionThreshold) {
                score += 0.3;
                factors.push(`High velocity: ${velocity} transactions/min`);
            }

            // Check amount thresholds with tiered scoring
            if (data.amount) {
                if (data.amount > this.securityConfig.fraudDetection.suspiciousAmountThreshold) {
                    score += 0.5; // High risk for very large amounts
                    factors.push(`Large amount: ${data.amount} CNE`);
                } else if (data.amount > this.securityConfig.fraudDetection.maxDailyRewards) {
                    score += 0.3; // Medium risk for elevated amounts
                    factors.push(`Elevated amount: ${data.amount} CNE`);
                }
            }

            // Check transfer limits
            if (operation === 'transfer' && data.amount > this.securityConfig.fraudDetection.maxTokenTransfer) {
                score += 0.4; // Additional score for exceeding transfer limits
                factors.push(`Exceeds transfer limit: ${data.amount} CNE`);
            }

            // Check daily rewards limit
            if (operation === 'rewards') {
                const dailyTotal = await this.getDailyRewardsTotal(userId);
                if (dailyTotal > this.securityConfig.fraudDetection.maxDailyRewards) {
                    score += 0.2; // Moderate risk for high rewards
                    factors.push(`High daily rewards: ${dailyTotal} CNE`);
                }
            }

            // Check account age
            const accountAge = await this.getAccountAge(userId);
            if (accountAge < this.securityConfig.validation.minAccountAge) {
                score += 0.2;
                factors.push(`New account: ${Math.round(accountAge / (60*60*1000))} hours old`);
            }

            // Additional risk factors for transfers
            if (operation === 'transfer' && data.amount > 50000 && data.amount <= this.securityConfig.fraudDetection.suspiciousAmountThreshold) {
                score += 0.1; // Light penalty for high-value but not suspicious transfers
                factors.push(`High-value transfer: ${data.amount} CNE`);
            }

            // Check for suspicious patterns
            const patterns = await this.checkSuspiciousPatterns(userId, operation, data);
            score += patterns.score;
            factors.push(...patterns.factors);

            return Math.min(score, 1); // Cap at 1.0

        } catch (error) {
            console.error('Error calculating fraud score:', error);
            return 0.5; // Default to medium risk on error
        }
    }

    /**
     * Enhanced Input Validation
     */
    validateInput(data, rules) {
        const errors = [];
        const warnings = [];

        for (const [field, fieldRules] of Object.entries(rules)) {
            const value = data[field];

            // Required field check
            if (fieldRules.required && (value === undefined || value === null || value === '')) {
                errors.push(`${field} is required`);
                continue;
            }

            // Skip validation if field is not provided and not required
            if (value === undefined || value === null) continue;

            // Type validation
            if (fieldRules.type && typeof value !== fieldRules.type) {
                errors.push(`${field} must be of type ${fieldRules.type}`);
            }

            // String validations
            if (fieldRules.type === 'string' && typeof value === 'string') {
                if (fieldRules.minLength && value.length < fieldRules.minLength) {
                    errors.push(`${field} must be at least ${fieldRules.minLength} characters`);
                }
                if (fieldRules.maxLength && value.length > fieldRules.maxLength) {
                    errors.push(`${field} must not exceed ${fieldRules.maxLength} characters`);
                }
                if (fieldRules.pattern && !fieldRules.pattern.test(value)) {
                    errors.push(`${field} format is invalid`);
                }
            }

            // Number validations
            if (fieldRules.type === 'number' && typeof value === 'number') {
                if (fieldRules.min !== undefined && value < fieldRules.min) {
                    errors.push(`${field} must be at least ${fieldRules.min}`);
                }
                if (fieldRules.max !== undefined && value > fieldRules.max) {
                    errors.push(`${field} must not exceed ${fieldRules.max}`);
                }
                if (fieldRules.integer && !Number.isInteger(value)) {
                    errors.push(`${field} must be an integer`);
                }
            }

            // Custom validations
            if (fieldRules.validate && typeof fieldRules.validate === 'function') {
                const customResult = fieldRules.validate(value, data);
                if (customResult !== true) {
                    errors.push(customResult || `${field} validation failed`);
                }
            }

            // Security-specific validations
            if (fieldRules.sanitize) {
                // Basic XSS prevention
                if (typeof value === 'string' && /<script|javascript:|on\w+=/i.test(value)) {
                    errors.push(`${field} contains potentially dangerous content`);
                }
            }
        }

        return {
            isValid: errors.length === 0,
            errors,
            warnings
        };
    }

    /**
     * Security Event Logging
     */
    async logSecurityEvent(eventType, data) {
        const securityEvent = {
            eventType,
            timestamp: Date.now(),
            data,
            severity: this.getEventSeverity(eventType),
            id: `sec_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`
        };

        try {
            // Store in Firestore
            await this.db.collection('securityEvents').add(securityEvent);

            // Send real-time alerts for high-severity events
            if (securityEvent.severity === 'HIGH' && this.securityConfig.monitoring.enableRealTimeAlerts) {
                await this.sendSecurityAlert(securityEvent);
            }

            // Log to console with appropriate level
            const logMethod = securityEvent.severity === 'HIGH' ? 'error' : 
                            securityEvent.severity === 'MEDIUM' ? 'warn' : 'info';
            console[logMethod](`Security Event [${eventType}]:`, data);

        } catch (error) {
            console.error('Failed to log security event:', error);
        }
    }

    /**
     * Send security alerts
     */
    async sendSecurityAlert(securityEvent) {
        if (!this.securityConfig.monitoring.alertWebhook) {
            console.warn('Security alert webhook not configured');
            return;
        }

        const alertPayload = {
            alert: 'CoinNewsExtra Security Alert',
            severity: securityEvent.severity,
            eventType: securityEvent.eventType,
            timestamp: new Date(securityEvent.timestamp).toISOString(),
            data: securityEvent.data,
            environment: 'mainnet'
        };

        try {
            // In a real implementation, you'd send this to your monitoring system
            console.error('🚨 SECURITY ALERT:', alertPayload);
            
            // Example webhook call (uncomment and configure as needed)
            /*
            const fetch = require('node-fetch');
            await fetch(this.securityConfig.monitoring.alertWebhook, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(alertPayload)
            });
            */

        } catch (error) {
            console.error('Failed to send security alert:', error);
        }
    }

    /**
     * Helper methods for fraud detection
     */
    async checkTransactionVelocity(userId) {
        const fifteenMinutesAgo = Date.now() - (15 * 60 * 1000);
        
        try {
            const recentTransactions = await this.db
                .collection('securityEvents')
                .where('data.userId', '==', userId)
                .where('timestamp', '>', fifteenMinutesAgo)
                .get();

            return recentTransactions.size / 15; // transactions per minute
        } catch (error) {
            console.error('Error checking transaction velocity:', error);
            return 0;
        }
    }

    async getDailyRewardsTotal(userId) {
        const oneDayAgo = Date.now() - (24 * 60 * 60 * 1000);
        
        try {
            const dailyRewards = await this.db
                .collection('userRewards')
                .where('userId', '==', userId)
                .where('timestamp', '>', oneDayAgo)
                .get();

            let total = 0;
            dailyRewards.forEach(doc => {
                total += doc.data().amount || 0;
            });

            return total;
        } catch (error) {
            console.error('Error getting daily rewards total:', error);
            return 0;
        }
    }

    async getAccountAge(userId) {
        try {
            const userDoc = await this.db.collection('users').doc(userId).get();
            if (!userDoc.exists) return 0;
            
            const userData = userDoc.data();
            const createdAt = userData.createdAt?.toMillis?.() || userData.createdAt || Date.now();
            return Date.now() - createdAt;
        } catch (error) {
            console.error('Error getting account age:', error);
            return 0;
        }
    }

    async checkSuspiciousPatterns(userId, operation, data) {
        let score = 0;
        const factors = [];

        // Check for repeated identical operations
        const recentSimilar = await this.getRecentSimilarOperations(userId, operation, data);
        if (recentSimilar > 5) {
            score += 0.3;
            factors.push(`Repeated operations: ${recentSimilar} similar in last hour`);
        }

        return { score, factors };
    }

    async getRecentSimilarOperations(userId, operation, data) {
        const oneHourAgo = Date.now() - (60 * 60 * 1000);
        
        try {
            const recentOps = await this.db
                .collection('securityEvents')
                .where('data.userId', '==', userId)
                .where('data.operation', '==', operation)
                .where('timestamp', '>', oneHourAgo)
                .get();

            return recentOps.size;
        } catch (error) {
            console.error('Error checking recent similar operations:', error);
            return 0;
        }
    }

    /**
     * Get event severity level
     */
    getEventSeverity(eventType) {
        const severityMap = {
            'RATE_LIMIT_EXCEEDED': 'MEDIUM',
            'FRAUD_DETECTION': 'HIGH',
            'SUSPICIOUS_ACTIVITY': 'HIGH',
            'VALIDATION_FAILED': 'LOW',
            'UNAUTHORIZED_ACCESS': 'HIGH',
            'LARGE_TRANSACTION': 'MEDIUM',
            'RAPID_TRANSACTIONS': 'MEDIUM',
            'NEW_ACCOUNT_ACTIVITY': 'LOW'
        };

        return severityMap[eventType] || 'LOW';
    }

    /**
     * Generate security middleware for Firebase Functions
     */
    createSecurityMiddleware() {
        return async (req, res, next) => {
            try {
                const userId = req.body.userId || req.query.userId;
                const operation = req.body.operation || req.path.split('/').pop();

                // Rate limiting check
                if (userId) {
                    const rateLimitResult = await this.checkRateLimit(userId, operation);
                    if (!rateLimitResult.allowed) {
                        return res.status(429).json({
                            error: 'Rate limit exceeded',
                            violations: rateLimitResult.violations,
                            resetTimes: rateLimitResult.resetTimes
                        });
                    }

                    // Add rate limit headers
                    res.set({
                        'X-RateLimit-Remaining-Minute': rateLimitResult.remaining?.minute || 0,
                        'X-RateLimit-Remaining-Hour': rateLimitResult.remaining?.hour || 0,
                        'X-RateLimit-Remaining-Day': rateLimitResult.remaining?.day || 0
                    });
                }

                // Fraud detection for high-value operations
                if (userId && ['rewards', 'transfer', 'mint'].includes(operation)) {
                    const fraudResult = await this.detectFraud(userId, operation, req.body);
                    if (!fraudResult.allowed) {
                        await this.logSecurityEvent('FRAUD_PREVENTION', {
                            userId,
                            operation,
                            fraudScore: fraudResult.fraudScore,
                            blocked: true
                        });

                        return res.status(403).json({
                            error: 'Transaction blocked due to security concerns',
                            riskLevel: fraudResult.riskLevel,
                            requiresReview: fraudResult.requiresReview
                        });
                    }
                }

                // Continue to next middleware
                if (next) next();
                
            } catch (error) {
                console.error('Security middleware error:', error);
                res.status(500).json({ error: 'Security check failed' });
            }
        };
    }

    /**
     * Initialize security system
     */
    async initialize() {
        console.log('🔒 Initializing Security Hardening System');
        console.log('=========================================');

        try {
            // Set up security event collection
            await this.setupSecurityCollections();
            
            // Initialize monitoring
            if (this.securityConfig.monitoring.enableMetrics) {
                this.startMetricsCollection();
            }

            console.log('✅ Security system initialized');
            console.log('Rate Limiting: Enabled');
            console.log('Fraud Detection: Enabled');
            console.log('Audit Logging: Enabled');
            console.log('Real-time Monitoring:', this.securityConfig.monitoring.enableRealTimeAlerts ? 'Enabled' : 'Disabled');

            return true;

        } catch (error) {
            console.error('❌ Security system initialization failed:', error);
            throw error;
        }
    }

    /**
     * Set up Firestore collections for security
     */
    async setupSecurityCollections() {
        // Create security events collection with proper indexes
        const securityEventsRef = this.db.collection('securityEvents');
        
        // Create a test document to ensure collection exists
        const testDoc = {
            eventType: 'SYSTEM_INIT',
            timestamp: Date.now(),
            data: { message: 'Security system initialized' },
            severity: 'LOW'
        };

        await securityEventsRef.add(testDoc);
        console.log('✅ Security events collection initialized');
    }

    /**
     * Start metrics collection
     */
    startMetricsCollection() {
        // Collect security metrics every 5 minutes
        setInterval(async () => {
            try {
                const metrics = await this.collectSecurityMetrics();
                await this.db.collection('securityMetrics').add({
                    timestamp: Date.now(),
                    ...metrics
                });
            } catch (error) {
                console.error('Error collecting security metrics:', error);
            }
        }, 5 * 60 * 1000); // 5 minutes

        console.log('✅ Metrics collection started');
    }

    /**
     * Collect security metrics
     */
    async collectSecurityMetrics() {
        const lastHour = Date.now() - (60 * 60 * 1000);
        
        try {
            const events = await this.db
                .collection('securityEvents')
                .where('timestamp', '>', lastHour)
                .get();

            const metrics = {
                totalEvents: events.size,
                eventsByType: {},
                eventsBySeverity: { LOW: 0, MEDIUM: 0, HIGH: 0 },
                rateLimitViolations: 0,
                fraudDetections: 0
            };

            events.forEach(doc => {
                const event = doc.data();
                
                // Count by type
                metrics.eventsByType[event.eventType] = 
                    (metrics.eventsByType[event.eventType] || 0) + 1;
                
                // Count by severity
                metrics.eventsBySeverity[event.severity] = 
                    (metrics.eventsBySeverity[event.severity] || 0) + 1;

                // Specific counters
                if (event.eventType === 'RATE_LIMIT_EXCEEDED') {
                    metrics.rateLimitViolations++;
                }
                if (event.eventType === 'FRAUD_DETECTION') {
                    metrics.fraudDetections++;
                }
            });

            return metrics;

        } catch (error) {
            console.error('Error collecting metrics:', error);
            return { error: 'Failed to collect metrics' };
        }
    }
}

module.exports = SecurityHardening;