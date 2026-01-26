#!/bin/bash

echo "Cleaning up OpenLIT demo"

# Delete Kind cluster
kind delete cluster --name openlit-demo

echo "Cleanup complete!"
