#!/bin/bash

# API testing script for local deployment
set -e

echo "🧪 Testing Foody API endpoints..."

BASE_URL="https://lab10.ifalabs.org"

# Test health endpoint
echo "1. Testing health endpoint..."
curl -s "$BASE_URL/health" | jq '.' || echo "Health check failed"

echo ""

# Test API users endpoint (requires authentication)
echo "2. Testing API users endpoint..."
curl -s "$BASE_URL/api/users" | jq '.' || echo "Users API failed (may require auth)"

echo ""

# Test API recipes endpoint
echo "3. Testing API recipes endpoint..."
curl -s "$BASE_URL/api/recipes" | jq '.' || echo "Recipes API failed"

echo ""

# Test API categories endpoint
echo "4. Testing API categories endpoint..."
curl -s "$BASE_URL/api/recipes/categories" | jq '.' || echo "Categories API failed"

echo ""

# Test API difficulties endpoint
echo "5. Testing API difficulties endpoint..."
curl -s "$BASE_URL/api/recipes/difficulties" | jq '.' || echo "Difficulties API failed"

echo ""

# Test search endpoint
echo "6. Testing search endpoint..."
curl -s "$BASE_URL/api/recipes/search?q=pasta" | jq '.' || echo "Search API failed"

echo ""

# Test token endpoint (for authentication)
echo "7. Testing token endpoint..."
curl -s -X POST "$BASE_URL/api/tokens" -H "Content-Type: application/json" -d '{"username":"test","password":"test"}' | jq '.' || echo "Token API failed (expected - no test user)"

echo ""

echo "✅ API testing completed!"
echo ""
echo "🌐 Open your browser and go to: $BASE_URL"
echo "📊 View application logs: sudo journalctl -u foody -f"
echo "🔧 Check service status: sudo systemctl status foody"
