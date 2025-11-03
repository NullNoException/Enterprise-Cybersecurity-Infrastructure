#!/usr/bin/env python3
"""
AI-Powered Log Analyzer for Cybersecurity Infrastructure
Uses Llama3 via Ollama to analyze logs and detect anomalies
"""

import os
import time
import json
import logging
import requests
from datetime import datetime, timedelta
from elasticsearch import Elasticsearch
from typing import Dict, List, Any
import schedule

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class AILogAnalyzer:
    """AI-powered log analysis and anomaly detection"""

    def __init__(self):
        self.es_host = os.getenv('ELASTICSEARCH_HOST', 'http://elasticsearch:9200')
        self.es_user = os.getenv('ELASTICSEARCH_USER', 'elastic')
        self.es_password = os.getenv('ELASTICSEARCH_PASSWORD', 'changeme')
        self.ollama_host = os.getenv('OLLAMA_HOST', 'http://ollama:11434')
        self.wazuh_api_url = os.getenv('WAZUH_API_URL', 'https://wazuh:55000')
        self.wazuh_user = os.getenv('WAZUH_API_USER', 'wazuh-wui')
        self.wazuh_password = os.getenv('WAZUH_API_PASSWORD', 'MyS3cr37P450r.*-')
        self.webhook_url = os.getenv('ALERT_WEBHOOK', '')

        # Initialize Elasticsearch client
        self.es = Elasticsearch(
            [self.es_host],
            basic_auth=(self.es_user, self.es_password),
            verify_certs=False
        )

        # Model name
        self.model = "llama3"

        # Initialize Ollama
        self._initialize_ollama()

    def _initialize_ollama(self):
        """Pull Llama3 model if not available"""
        try:
            logger.info("Checking Ollama availability...")
            response = requests.get(f"{self.ollama_host}/api/tags", timeout=10)

            if response.status_code == 200:
                models = response.json().get('models', [])
                model_names = [m['name'] for m in models]

                if self.model not in model_names:
                    logger.info(f"Pulling {self.model} model... This may take several minutes.")
                    pull_response = requests.post(
                        f"{self.ollama_host}/api/pull",
                        json={"name": self.model},
                        timeout=600
                    )
                    if pull_response.status_code == 200:
                        logger.info(f"{self.model} model pulled successfully")
                    else:
                        logger.error(f"Failed to pull model: {pull_response.text}")
                else:
                    logger.info(f"{self.model} model is available")
            else:
                logger.warning("Ollama not ready yet, will retry...")

        except Exception as e:
            logger.error(f"Error initializing Ollama: {e}")
            logger.info("Will retry on next analysis cycle")

    def fetch_recent_logs(self, minutes: int = 5, max_logs: int = 100) -> List[Dict]:
        """Fetch recent logs from Elasticsearch"""
        try:
            query = {
                "query": {
                    "bool": {
                        "must": [
                            {
                                "range": {
                                    "@timestamp": {
                                        "gte": f"now-{minutes}m",
                                        "lte": "now"
                                    }
                                }
                            }
                        ]
                    }
                },
                "sort": [{"@timestamp": {"order": "desc"}}],
                "size": max_logs
            }

            result = self.es.search(
                index="filebeat-*,logstash-*,wazuh-*",
                body=query
            )

            logs = []
            for hit in result['hits']['hits']:
                logs.append(hit['_source'])

            logger.info(f"Fetched {len(logs)} logs from last {minutes} minutes")
            return logs

        except Exception as e:
            logger.error(f"Error fetching logs: {e}")
            return []

    def simplify_logs(self, logs: List[Dict]) -> str:
        """Simplify and aggregate logs for AI analysis"""
        if not logs:
            return "No logs to analyze"

        # Group logs by type/source
        log_summary = {
            'total_count': len(logs),
            'by_level': {},
            'by_source': {},
            'error_samples': [],
            'warning_samples': [],
            'suspicious_patterns': []
        }

        for log in logs:
            # Count by log level
            level = log.get('log', {}).get('level', log.get('level', 'info')).lower()
            log_summary['by_level'][level] = log_summary['by_level'].get(level, 0) + 1

            # Count by source
            source = log.get('agent', {}).get('name', log.get('source', 'unknown'))
            log_summary['by_source'][source] = log_summary['by_source'].get(source, 0) + 1

            # Collect error samples
            if 'error' in level and len(log_summary['error_samples']) < 5:
                log_summary['error_samples'].append({
                    'timestamp': log.get('@timestamp', 'unknown'),
                    'message': log.get('message', str(log))[:200]
                })

            # Collect warning samples
            if 'warn' in level and len(log_summary['warning_samples']) < 5:
                log_summary['warning_samples'].append({
                    'timestamp': log.get('@timestamp', 'unknown'),
                    'message': log.get('message', str(log))[:200]
                })

            # Look for suspicious patterns
            message = str(log.get('message', '')).lower()
            suspicious_keywords = [
                'failed', 'denied', 'unauthorized', 'attack', 'intrusion',
                'malware', 'exploit', 'breach', 'suspicious', 'anomaly'
            ]

            if any(keyword in message for keyword in suspicious_keywords):
                if len(log_summary['suspicious_patterns']) < 10:
                    log_summary['suspicious_patterns'].append({
                        'timestamp': log.get('@timestamp', 'unknown'),
                        'message': message[:200]
                    })

        return json.dumps(log_summary, indent=2)

    def analyze_with_ai(self, simplified_logs: str) -> Dict[str, Any]:
        """Use Ollama/Llama3 to analyze logs and detect anomalies"""
        try:
            prompt = f"""You are a cybersecurity AI assistant analyzing system logs.

Analyze the following log summary and identify:
1. Security threats or anomalies (rate severity: low/medium/high/critical)
2. Patterns that require immediate attention
3. Recommended actions

Log Summary:
{simplified_logs}

Provide your analysis in JSON format with these fields:
- severity: (low/medium/high/critical)
- threats: [list of identified threats]
- anomalies: [list of detected anomalies]
- recommendations: [list of recommended actions]
- summary: (brief overall assessment)

Keep your response concise and focused on security implications."""

            response = requests.post(
                f"{self.ollama_host}/api/generate",
                json={
                    "model": self.model,
                    "prompt": prompt,
                    "stream": False,
                    "options": {
                        "temperature": 0.3,
                        "top_p": 0.9
                    }
                },
                timeout=60
            )

            if response.status_code == 200:
                ai_response = response.json().get('response', '')
                logger.info("AI analysis completed")

                # Try to parse JSON from response
                try:
                    # Extract JSON from markdown code blocks if present
                    if '```json' in ai_response:
                        json_start = ai_response.find('```json') + 7
                        json_end = ai_response.find('```', json_start)
                        ai_response = ai_response[json_start:json_end].strip()
                    elif '```' in ai_response:
                        json_start = ai_response.find('```') + 3
                        json_end = ai_response.find('```', json_start)
                        ai_response = ai_response[json_start:json_end].strip()

                    analysis = json.loads(ai_response)
                    return analysis
                except json.JSONDecodeError:
                    logger.warning("AI response not in JSON format, using raw text")
                    return {
                        'severity': 'low',
                        'threats': [],
                        'anomalies': [],
                        'recommendations': [],
                        'summary': ai_response
                    }
            else:
                logger.error(f"Ollama API error: {response.status_code}")
                return self._fallback_analysis(simplified_logs)

        except Exception as e:
            logger.error(f"Error in AI analysis: {e}")
            return self._fallback_analysis(simplified_logs)

    def _fallback_analysis(self, simplified_logs: str) -> Dict[str, Any]:
        """Fallback rule-based analysis when AI is unavailable"""
        try:
            log_data = json.loads(simplified_logs)

            severity = 'low'
            threats = []
            anomalies = []

            # Check error rate
            error_count = log_data['by_level'].get('error', 0)
            total_count = log_data['total_count']

            if total_count > 0:
                error_rate = error_count / total_count
                if error_rate > 0.5:
                    severity = 'high'
                    anomalies.append(f"High error rate: {error_rate*100:.1f}%")
                elif error_rate > 0.2:
                    severity = 'medium'
                    anomalies.append(f"Elevated error rate: {error_rate*100:.1f}%")

            # Check suspicious patterns
            if log_data['suspicious_patterns']:
                if len(log_data['suspicious_patterns']) > 5:
                    severity = 'high'
                threats.append(f"Multiple suspicious events detected: {len(log_data['suspicious_patterns'])}")

            return {
                'severity': severity,
                'threats': threats,
                'anomalies': anomalies,
                'recommendations': ['Review error logs', 'Check suspicious events'],
                'summary': 'Automated rule-based analysis (AI unavailable)'
            }
        except Exception as e:
            logger.error(f"Error in fallback analysis: {e}")
            return {
                'severity': 'low',
                'threats': [],
                'anomalies': [],
                'recommendations': [],
                'summary': 'Analysis failed'
            }

    def send_alert_to_siem(self, analysis: Dict[str, Any]):
        """Send high-severity alerts to Wazuh SIEM"""
        if analysis['severity'] in ['high', 'critical']:
            try:
                # Create Wazuh alert
                alert_data = {
                    'title': f"AI Detected {analysis['severity'].upper()} severity issue",
                    'description': analysis['summary'],
                    'severity': analysis['severity'],
                    'threats': analysis.get('threats', []),
                    'anomalies': analysis.get('anomalies', []),
                    'recommendations': analysis.get('recommendations', [])
                }

                logger.warning(f"HIGH SEVERITY ALERT: {alert_data}")

                # Send to webhook if configured
                if self.webhook_url:
                    self._send_webhook_notification(alert_data)

                # Index alert in Elasticsearch
                self.es.index(
                    index='ai-security-alerts',
                    document={
                        '@timestamp': datetime.utcnow().isoformat(),
                        **alert_data
                    }
                )

                logger.info("Alert sent to SIEM")

            except Exception as e:
                logger.error(f"Error sending alert to SIEM: {e}")

    def _send_webhook_notification(self, alert_data: Dict[str, Any]):
        """Send notification to webhook (e.g., Rocket.Chat)"""
        try:
            message = f"""
🚨 **Security Alert - {alert_data['severity'].upper()}**

**Summary:** {alert_data['description']}

**Threats:** {', '.join(alert_data.get('threats', ['None']))}

**Anomalies:** {', '.join(alert_data.get('anomalies', ['None']))}

**Recommendations:**
{chr(10).join(f"• {rec}" for rec in alert_data.get('recommendations', []))}
"""

            requests.post(
                self.webhook_url,
                json={'text': message},
                timeout=5
            )
            logger.info("Webhook notification sent")

        except Exception as e:
            logger.error(f"Error sending webhook: {e}")

    def analyze_logs_cycle(self):
        """Main analysis cycle - runs periodically"""
        logger.info("Starting log analysis cycle...")

        try:
            # Fetch recent logs
            logs = self.fetch_recent_logs(minutes=5, max_logs=100)

            if not logs:
                logger.info("No logs to analyze")
                return

            # Simplify logs
            simplified = self.simplify_logs(logs)
            logger.debug(f"Simplified logs: {simplified}")

            # Analyze with AI
            analysis = self.analyze_with_ai(simplified)

            # Log analysis results
            logger.info(f"Analysis complete - Severity: {analysis['severity']}")
            logger.info(f"Summary: {analysis['summary']}")

            # Send alerts for high-severity issues
            self.send_alert_to_siem(analysis)

            # Store analysis results
            self.es.index(
                index='ai-log-analysis',
                document={
                    '@timestamp': datetime.utcnow().isoformat(),
                    'log_count': len(logs),
                    'analysis': analysis,
                    'simplified_logs': simplified
                }
            )

        except Exception as e:
            logger.error(f"Error in analysis cycle: {e}", exc_info=True)

    def run(self):
        """Run the analyzer continuously"""
        logger.info("AI Log Analyzer starting...")
        logger.info(f"Elasticsearch: {self.es_host}")
        logger.info(f"Ollama: {self.ollama_host}")
        logger.info(f"Model: {self.model}")

        # Wait for services to be ready
        logger.info("Waiting for services to be ready...")
        time.sleep(30)

        # Run initial analysis
        self.analyze_logs_cycle()

        # Schedule periodic analysis (every 5 minutes)
        schedule.every(5).minutes.do(self.analyze_logs_cycle)

        logger.info("Analyzer running. Analysis every 5 minutes.")

        while True:
            schedule.run_pending()
            time.sleep(60)


if __name__ == "__main__":
    analyzer = AILogAnalyzer()
    analyzer.run()
