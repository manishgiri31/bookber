# BookBer Alerting Strategy

## Overview

Comprehensive alerting strategy for BookBer queue system, ensuring timely detection and response to production issues.

## Alert Severity Levels

### Critical (P0)

**Definition**: System-wide outage requiring immediate intervention

**Examples**:
- Service down (all instances)
- Database connection failure
- Redis connection failure
- Queue processing completely stopped
- Data corruption
- Security breach

**Response Time**: Immediate (< 5 minutes)

**Escalation**: Immediate to on-call engineer + engineering manager

**Notification Channels**:
- PagerDuty (critical)
- Phone call (if no response in 5 minutes)
- Slack #alerts-critical

### High (P1)

**Definition**: Significant degradation affecting core functionality

**Examples**:
- High error rate (> 5%)
- High latency (> 5s p95)
- Queue backlog (> 1000)
- Memory pressure (> 90%)
- CPU pressure (> 90%)
- Partial service outage (some instances down)

**Response Time**: < 15 minutes

**Escalation**: Escalate after 15 minutes to on-call engineer

**Notification Channels**:
- PagerDuty (high)
- Slack #alerts-high
- Email to on-call

### Medium (P2)

**Definition**: Moderate degradation with workarounds available

**Examples**:
- Elevated error rate (> 1%)
- Elevated latency (> 2s p95)
- Queue backlog (> 500)
- Memory pressure (> 80%)
- CPU pressure (> 80%)
- Degraded performance on some features

**Response Time**: < 30 minutes

**Escalation**: Escalate after 30 minutes to engineering team

**Notification Channels**:
- Slack #alerts-medium
- Email to engineering team

### Low (P3)

**Definition**: Minor issues with minimal impact

**Examples**:
- Minor error rate (> 0.5%)
- Minor latency (> 1s p95)
- Queue backlog (> 200)
- Memory pressure (> 70%)
- CPU pressure (> 70%)
- Non-critical feature degradation

**Response Time**: < 1 hour

**Escalation**: No automatic escalation

**Notification Channels**:
- Slack #alerts-low
- Email to engineering team (daily digest)

## Alert Rules

### Queue Metrics

#### Queue Latency

**Alert**: High Queue Latency
**Severity**: P1
**Condition**: `histogram_quantile(0.95, rate(bookber_queue_latency_seconds_bucket[5m])) > 5`
**Duration**: 5 minutes
**Description**: Queue operations are taking longer than 5 seconds (p95)

**Alert**: Critical Queue Latency
**Severity**: P0
**Condition**: `histogram_quantile(0.95, rate(bookber_queue_latency_seconds_bucket[5m])) > 10`
**Duration**: 2 minutes
**Description**: Queue operations are taking longer than 10 seconds (p95)

#### Booking Throughput

**Alert**: Low Booking Throughput
**Severity**: P1
**Condition**: `rate(bookber_booking_throughput_total[5m]) < 0.5 * rate(bookber_booking_throughput_total[1h] offset 5m)`
**Duration**: 5 minutes
**Description**: Booking throughput has dropped by more than 50%

**Alert**: Critical Booking Throughput
**Severity**: P0
**Condition**: `rate(bookber_booking_throughput_total[5m]) < 0.2 * rate(bookber_booking_throughput_total[1h] offset 5m)`
**Duration**: 2 minutes
**Description**: Booking throughput has dropped by more than 80%

#### Active Queues

**Alert**: Low Active Queues
**Severity**: P1
**Condition**: `sum(bookber_active_queues) < 0.5 * sum(bookber_active_queues offset 1h)`
**Duration**: 5 minutes
**Description**: Number of active queues has dropped by more than 50%

**Alert**: No Active Queues
**Severity**: P0
**Condition**: `sum(bookber_active_queues) == 0`
**Duration**: 1 minute
**Description**: No active queues detected

#### Wait Time Accuracy

**Alert**: Low Wait Time Accuracy
**Severity**: P2
**Condition**: `avg(bookber_wait_time_accuracy) < 0.8`
**Duration**: 10 minutes
**Description**: Wait time accuracy is below 80%

**Alert**: Critical Wait Time Accuracy
**Severity**: P1
**Condition**: `avg(bookber_wait_time_accuracy) < 0.6`
**Duration**: 5 minutes
**Description**: Wait time accuracy is below 60%

### Socket Metrics

#### Socket Connections

**Alert**: Low Socket Connections
**Severity**: P1
**Condition**: `sum(bookber_socket_connections) < 0.5 * sum(bookber_socket_connections offset 1h)`
**Duration**: 5 minutes
**Description**: Socket connections have dropped by more than 50%

**Alert**: No Socket Connections
**Severity**: P0
**Condition**: `sum(bookber_socket_connections) == 0`
**Duration**: 1 minute
**Description**: No socket connections detected

#### Socket Latency

**Alert**: High Socket Latency
**Severity**: P2
**Condition**: `histogram_quantile(0.95, rate(bookber_socket_latency_seconds_bucket[5m])) > 1`
**Duration**: 5 minutes
**Description**: Socket latency is above 1 second (p95)

### Redis Metrics

#### Redis Latency

**Alert**: High Redis Latency
**Severity**: P1
**Condition**: `histogram_quantile(0.95, rate(bookber_redis_latency_seconds_bucket[5m])) > 0.1`
**Duration**: 5 minutes
**Description**: Redis latency is above 100ms (p95)

**Alert**: Critical Redis Latency
**Severity**: P0
**Condition**: `histogram_quantile(0.95, rate(bookber_redis_latency_seconds_bucket[5m])) > 0.5`
**Duration**: 2 minutes
**Description**: Redis latency is above 500ms (p95)

#### Redis Errors

**Alert**: High Redis Error Rate
**Severity**: P1
**Condition**: `rate(bookber_redis_errors_total[5m]) > 0.05 * rate(bookber_redis_operations_total[5m])`
**Duration**: 5 minutes
**Description**: Redis error rate is above 5%

### PostgreSQL Metrics

#### PostgreSQL Latency

**Alert**: High PostgreSQL Latency
**Severity**: P1
**Condition**: `histogram_quantile(0.95, rate(bookber_postgres_latency_seconds_bucket[5m])) > 1`
**Duration**: 5 minutes
**Description**: PostgreSQL latency is above 1 second (p95)

**Alert**: Critical PostgreSQL Latency
**Severity**: P0
**Condition**: `histogram_quantile(0.95, rate(bookber_postgres_latency_seconds_bucket[5m])) > 5`
**Duration**: 2 minutes
**Description**: PostgreSQL latency is above 5 seconds (p95)

#### PostgreSQL Errors

**Alert**: High PostgreSQL Error Rate
**Severity**: P1
**Condition**: `rate(bookber_postgres_errors_total[5m]) > 0.05 * rate(bookber_postgres_queries_total[5m])`
**Duration**: 5 minutes
**Description**: PostgreSQL error rate is above 5%

### Chair Metrics

#### Chair Utilization

**Alert**: Low Chair Utilization
**Severity**: P2
**Condition**: `avg(bookber_chair_utilization) < 50`
**Duration**: 30 minutes
**Description**: Chair utilization is below 50%

**Alert**: High Chair Utilization
**Severity**: P1
**Condition**: `avg(bookber_chair_utilization) > 100`
**Duration**: 5 minutes
**Description**: Chair utilization is above 100% (overbooked)

### HTTP Metrics

#### HTTP Error Rate

**Alert**: High HTTP Error Rate
**Severity**: P1
**Condition**: `rate(bookber_http_errors_total[5m]) / rate(bookber_http_requests_total[5m]) > 0.05`
**Duration**: 5 minutes
**Description**: HTTP error rate is above 5%

**Alert**: Critical HTTP Error Rate
**Severity**: P0
**Condition**: `rate(bookber_http_errors_total[5m]) / rate(bookber_http_requests_total[5m]) > 0.1`
**Duration**: 2 minutes
**Description**: HTTP error rate is above 10%

#### HTTP Latency

**Alert**: High HTTP Latency
**Severity**: P1
**Condition**: `histogram_quantile(0.95, rate(bookber_http_request_duration_seconds_bucket[5m])) > 5`
**Duration**: 5 minutes
**Description**: HTTP request latency is above 5 seconds (p95)

**Alert**: Critical HTTP Latency
**Severity**: P0
**Condition**: `histogram_quantile(0.95, rate(bookber_http_request_duration_seconds_bucket[5m])) > 10`
**Duration**: 2 minutes
**Description**: HTTP request latency is above 10 seconds (p95)

### Infrastructure Metrics

#### Memory Usage

**Alert**: High Memory Usage
**Severity**: P1
**Condition**: `process_resident_memory_bytes / node_memory_MemTotal_bytes > 0.9`
**Duration**: 5 minutes
**Description**: Memory usage is above 90%

**Alert**: Critical Memory Usage
**Severity**: P0
**Condition**: `process_resident_memory_bytes / node_memory_MemTotal_bytes > 0.95`
**Duration**: 2 minutes
**Description**: Memory usage is above 95%

#### CPU Usage

**Alert**: High CPU Usage
**Severity**: P1
**Condition**: `rate(process_cpu_seconds_total[5m]) > 0.9`
**Duration**: 5 minutes
**Description**: CPU usage is above 90%

**Alert**: Critical CPU Usage
**Severity**: P0
**Condition**: `rate(process_cpu_seconds_total[5m]) > 0.95`
**Duration**: 2 minutes
**Description**: CPU usage is above 95%

## Alert Suppression

### Maintenance Windows

Alerts should be suppressed during scheduled maintenance windows. Configure maintenance windows in your alerting system to prevent false positives during planned downtime.

### Known Issues

Alerts should be suppressed for known issues that are being worked on. Use alert annotations to track known issues and suppress related alerts.

### Testing Environments

Alerts should be disabled or significantly relaxed in testing/staging environments to avoid noise during development and testing.

## Alert Routing

### On-Call Schedule

- **Primary On-Call**: First point of contact for all alerts
- **Secondary On-Call**: Backup if primary doesn't respond
- **Engineering Manager**: Escalation point for critical issues
- **Team Lead**: Escalation point for high priority issues

### Routing Rules

1. **P0 Alerts**: Route to primary on-call immediately
2. **P1 Alerts**: Route to primary on-call, escalate after 15 minutes
3. **P2 Alerts**: Route to team Slack channel, escalate after 30 minutes
4. **P3 Alerts**: Route to team Slack channel, no automatic escalation

### Time-Based Routing

- **Business Hours (9 AM - 6 PM)**: Route to team Slack channel for P2/P3
- **After Hours**: Route to on-call for P1/P2, suppress P3

## Alert Response Playbooks

### Queue Latency High

1. Check Redis health and latency
2. Check queue size and backlog
3. Check for stuck bookings
4. Check recovery worker status
5. Restart recovery workers if needed
6. Scale queue processing if needed

### Booking Throughput Low

1. Check service health
2. Check error rate
3. Check database connection pool
4. Check Redis connection pool
5. Check for rate limiting
6. Review recent deployments

### Redis Connection Failure

1. Check Redis service status
2. Check network connectivity
3. Check Redis configuration
4. Restart Redis if needed
5. Failover to replica if available
6. Scale Redis if needed

### PostgreSQL Connection Failure

1. Check PostgreSQL service status
2. Check network connectivity
3. Check connection pool settings
4. Check for long-running queries
5. Kill blocking queries if needed
6. Scale PostgreSQL if needed

### High Error Rate

1. Identify error type and source
2. Check recent deployments
3. Review error logs
4. Check for configuration changes
5. Rollback if recent deployment
6. Fix root cause

## Alert Tuning

### Review Process

- **Weekly**: Review alert fatigue and false positives
- **Monthly**: Review alert thresholds and adjust as needed
- **Quarterly**: Comprehensive review of alerting strategy

### Metrics to Track

- Alert frequency by severity
- Alert response time
- False positive rate
- Mean time to acknowledge (MTTA)
- Mean time to resolve (MTTR)

### Continuous Improvement

- Add new alerts for emerging issues
- Remove obsolete alerts
- Adjust thresholds based on baseline changes
- Improve alert messages with actionable information
- Add runbooks for common issues

## Alert Documentation

### Alert Template

Each alert should include:
- **Title**: Clear, concise description
- **Severity**: P0, P1, P2, or P3
- **Condition**: Prometheus query
- **Duration**: Time threshold
- **Description**: What the alert means
- **Impact**: Business impact
- **Runbook**: Link to troubleshooting guide
- **Owner**: Team responsible for the alert

### Runbook Template

Each runbook should include:
- **Symptoms**: What to look for
- **Diagnosis**: How to diagnose the issue
- **Resolution**: Steps to resolve
- **Prevention**: How to prevent recurrence
- **References**: Links to relevant documentation

## Integration with Incident Management

### PagerDuty Integration

- Configure service integration in PagerDuty
- Map alert severities to PagerDuty urgency
- Set up escalation policies
- Configure on-call schedules

### Slack Integration

- Create alert channels (#alerts-critical, #alerts-high, #alerts-medium, #alerts-low)
- Configure webhook integration
- Set up alert formatting
- Add interactive buttons for common actions

### Incident Tracking

- Create incident for P0/P1 alerts
- Track incident lifecycle
- Document resolution steps
- Conduct post-mortem for critical incidents

## Testing

### Alert Testing

- Test alert delivery weekly
- Test escalation paths monthly
- Test runbooks quarterly
- Test new alerts before deployment

### Load Testing

- Test alert behavior under load
- Ensure alerts don't flood during incidents
- Verify alert suppression works correctly
- Test notification channel reliability

## Compliance and Security

### Data Privacy

- Ensure alert messages don't contain PII
- Redact sensitive information in logs
- Use secure channels for critical alerts
- Comply with data retention policies

### Audit Trail

- Log all alert notifications
- Track alert acknowledgments
- Record alert resolutions
- Maintain alert history for compliance

## Summary

This alerting strategy provides a comprehensive framework for monitoring and alerting on the BookBer queue system. Regular review and tuning of alerts is essential to maintain effectiveness and reduce alert fatigue.
