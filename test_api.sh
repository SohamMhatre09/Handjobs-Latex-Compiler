#!/bin/bash

# Test script for LaTeX Compiler Service with API Key Authentication

API_KEY="djsakjc213hjbkk3h123jkb123kbj"
BASE_URL="http://localhost:8080"

echo "Testing LaTeX Compiler Service with API Key Authentication"
echo "=========================================================="

# Test 1: Health check without API key (should fail)
echo -e "\n1. Testing health check without API key (should fail):"
curl -s -w "\nHTTP Status: %{http_code}\n" $BASE_URL/health

# Test 2: Health check with correct API key (should succeed)
echo -e "\n2. Testing health check with correct API key (should succeed):"
curl -s -H "X-API-KEY: $API_KEY" -w "\nHTTP Status: %{http_code}\n" $BASE_URL/health

# Test 3: Health check with wrong API key (should fail)
echo -e "\n3. Testing health check with wrong API key (should fail):"
curl -s -H "X-API-KEY: wrong-key" -w "\nHTTP Status: %{http_code}\n" $BASE_URL/health

# Test 4: Test compile endpoint without API key (should fail)
echo -e "\n4. Testing compile endpoint without API key (should fail):"
curl -s -X POST -H "Content-Type: application/json" \
     -d '{"latex_content": "\\documentclass{article}\\begin{document}Test\\end{document}"}' \
     -w "\nHTTP Status: %{http_code}\n" $BASE_URL/test

# Test 5: Test compile endpoint with correct API key (should succeed)
echo -e "\n5. Testing compile endpoint with correct API key (should succeed):"
curl -s -X POST -H "Content-Type: application/json" \
     -H "X-API-KEY: $API_KEY" \
     -w "\nHTTP Status: %{http_code}\n" $BASE_URL/test

echo -e "\nTest completed!"
