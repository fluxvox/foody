# Quick Local Docker Testing Guide

## 🚀 **How to Test Docker Deployment Locally**

### **Option 1: One-Command Testing (Recommended)**

```bash
# Make sure Docker Desktop is running, then:
./test-local.sh
```

This will automatically:
- ✅ Check Docker is running
- ✅ Build and start all services
- ✅ Wait for health checks
- ✅ Test the application
- ✅ Show you all the URLs and commands

### **Option 2: Manual Step-by-Step Testing**

#### **Step 1: Start Docker Desktop**
- Open Docker Desktop application
- Wait for it to start (green icon in system tray)

#### **Step 2: Start Services**
```bash
# Start all services
docker-compose -f docker-compose.local.yml up --build -d

# Check status
docker-compose -f docker-compose.local.yml ps
```

#### **Step 3: Wait for Services**
```bash
# Monitor startup (wait for all services to be "healthy")
docker-compose -f docker-compose.local.yml logs -f
```

#### **Step 4: Test Application**
```bash
# Test health endpoint
curl http://localhost:5000/health

# Test API
curl http://localhost:5000/api/users

# Open in browser
open http://localhost:5000  # macOS
# or just go to http://localhost:5000 in your browser
```

### **Option 3: Quick API Testing**

```bash
# After services are running, test all API endpoints:
./test-api.sh
```

## 📋 **What You'll Get**

### **Services Running:**
- 🌐 **Web App**: http://localhost:5000
- 🗄️ **Database**: PostgreSQL on port 5432
- 🔄 **Redis**: Cache on port 6379  
- 🔍 **Elasticsearch**: Search on port 9200

### **Test URLs:**
- **Main App**: http://localhost:5000
- **Health Check**: http://localhost:5000/health
- **API Users**: http://localhost:5000/api/users
- **API Recipes**: http://localhost:5000/api/recipes
- **API Search**: http://localhost:5000/api/recipes/search?q=pasta

## 🛠️ **Useful Commands**

### **View Logs:**
```bash
# All services
docker-compose -f docker-compose.local.yml logs -f

# Specific service
docker-compose -f docker-compose.local.yml logs -f web
```

### **Stop Services:**
```bash
# Stop all services
docker-compose -f docker-compose.local.yml down

# Stop and remove all data
docker-compose -f docker-compose.local.yml down -v
```

### **Restart Services:**
```bash
# Restart after code changes
docker-compose -f docker-compose.local.yml up --build -d
```

### **Access Database:**
```bash
# Connect to PostgreSQL
docker-compose -f docker-compose.local.yml exec db psql -U foody -d foody
```

## 🔧 **Troubleshooting**

### **Docker Not Running:**
```bash
# Check if Docker is running
docker info

# If not running, start Docker Desktop
# Then try again
```

### **Port Conflicts:**
If port 5000 is busy, modify `docker-compose.local.yml`:
```yaml
ports:
  - "5001:5000"  # Use port 5001 instead
```

### **Services Not Starting:**
```bash
# Check logs
docker-compose -f docker-compose.local.yml logs

# Check Docker resources
docker system df
```

### **Application Not Responding:**
```bash
# Check health
curl -v http://localhost:5000/health

# Check application logs
docker-compose -f docker-compose.local.yml logs web
```

## 🎯 **What to Test**

### **1. Basic Functionality:**
- ✅ Open http://localhost:5000 in browser
- ✅ Register a new user
- ✅ Login with the user
- ✅ Create a recipe
- ✅ View recipes
- ✅ Search for recipes

### **2. API Endpoints:**
- ✅ GET /health
- ✅ GET /api/users
- ✅ GET /api/recipes
- ✅ GET /api/recipes/categories
- ✅ GET /api/recipes/difficulties
- ✅ GET /api/recipes/search?q=pasta

### **3. Database:**
- ✅ Check users table
- ✅ Check recipes table
- ✅ Check ratings table

## 🚀 **Next Steps**

Once local testing works:

1. **Production Deployment**: Use `./deploy.sh` for production
2. **Custom Configuration**: Edit `production.env.example`
3. **SSL Setup**: Configure proper SSL certificates
4. **Domain Setup**: Point your domain to the server

## 📞 **Need Help?**

1. **Check logs**: `docker-compose -f docker-compose.local.yml logs`
2. **Check status**: `docker-compose -f docker-compose.local.yml ps`
3. **Check health**: `curl http://localhost:5000/health`
4. **Read documentation**: `LOCAL_TESTING.md` for detailed guide

---

**🎉 That's it! Your Docker deployment is ready for testing!**
