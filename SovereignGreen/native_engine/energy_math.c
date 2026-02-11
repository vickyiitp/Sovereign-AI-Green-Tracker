#include <stdio.h>
#include <stdlib.h>

#ifdef _WIN32
#define EXPORT __declspec(dllexport)
#else
#define EXPORT
#endif

// Example function to be called from Dart
EXPORT double calculate_impact(int tokens, float grid_intensity, int is_b200_gpu) {
    // Energy per token (Wh)
    double energy_per_token;
    if (is_b200_gpu) {
        energy_per_token = 0.003; // Next-gen B200: 15x more efficient
    } else {
        energy_per_token = 0.05;  // Standard H100
    }

    // Total Energy (kWh) = (Tokens * Wh/Token) / 1000
    double total_energy_kwh = (tokens * energy_per_token) / 1000.0;

    // Carbon Footprint (grams) = Energy (kWh) * Grid Intensity (kg/kWh) * 1000
    // We return grams directly
    return total_energy_kwh * grid_intensity * 1000.0;
}
