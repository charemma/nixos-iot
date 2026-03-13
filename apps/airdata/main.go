package main

import (
	"log"
	"net/http"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"github.com/ryszard/sds011/go/sds011"
)

var (
	pm25Gauge = prometheus.NewGauge(prometheus.GaugeOpts{
		Name: "pm25",
		Help: "PM2.5 concentration in µg/m³",
	})
	pm10Gauge = prometheus.NewGauge(prometheus.GaugeOpts{
		Name: "pm10",
		Help: "PM10 concentration in µg/m³",
	})
)

func main() {
	sensor, err := sds011.New("/dev/ttyUSB0")
	if err != nil {
		log.Fatalf("failed to open port: %v", err)
	}
	defer sensor.Close()

	go func() {
		for {
			if err := sensor.Awake(); err != nil {
				log.Printf("failed to wake up sensor: %v", err)
				continue
			}

			time.Sleep(30 * time.Second) // Wait for the sensor to warm up

			point, err := sensor.Query()

			if err != nil {
				log.Printf("failed to query sensor: %v", err)
				continue
			} else {
				pm25Gauge.Set(point.PM25)
				pm10Gauge.Set(point.PM10)
				log.Printf("PM2.5: %.1f, PM10: %.1f", point.PM25, point.PM10)
			}

			if err := sensor.Sleep(); err != nil {
				log.Printf("failed to put sensor to sleep: %v", err)
			}

			time.Sleep(300 * time.Second) // Sleep for 5 minutes
		}
	}()

	http.Handle("/metrics", promhttp.Handler())
	log.Println("[particulate-exporter] Listening on :8000")
	log.Fatal(http.ListenAndServe(":8000", nil))
}
