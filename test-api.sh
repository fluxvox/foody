#!/bin/bash

# API testing script for local Docker deployment
set -e

echo "🧪 Testing Foody API endpoints..."

BASE_URL="http://localhost:5001"

# Test health endpoint
echo "1. Testing health endpoint..."
curl -s "$BASE_URL/health" | jq '.' || echo "Health check failed"

echo ""

# Test API users endpoint
echo "2. Testing API users endpoint..."
curl -s "$BASE_URL/api/users" | jq '.' || echo "Users API failed"

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

echo "✅ API testing completed!"
echo ""
echo "🌐 Open your browser and go to: $BASE_URL"
echo "📊 View container logs: docker compose -f docker-compose.local.yml logs -f"
