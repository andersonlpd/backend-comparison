FROM justb4/jmeter:latest

# Download Prometheus JMeter Plugin
USER root
RUN cd /opt/apache-jmeter-5.5/lib/ext && \
    wget https://github.com/johrstrom/jmeter-prometheus-plugin/releases/download/0.7.1/jmeter-prometheus-plugin-0.7.1.jar && \
    echo "prometheus.ip=0.0.0.0" >> ../../bin/jmeter.properties

USER jmeter

# Copy test plan
COPY backend-test-plan.jmx /tests/

# Expose Prometheus metrics port
EXPOSE 9270

# Run JMeter test
CMD ["jmeter", "-n", "-t", "/tests/backend-test-plan.jmx", "-l", "/tmp/result.jtl"]
