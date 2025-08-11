#!/bin/bash

# PopcornBoard Quick Deployment Script
echo "🍿 PopcornBoard Deployment Script"
echo "=================================="

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Check if .env.local exists
if [ ! -f ".env.local" ]; then
    echo "📝 Creating .env.local from template..."
    cp env.example .env.local
    echo "⚠️  Please edit .env.local with your API keys and secrets before continuing."
    echo "   Required: MOVIE_API_KEY, NEXTAUTH_SECRET"
    read -p "Press Enter after you've updated .env.local..."
fi

# Build Docker images
echo "🔨 Building Docker images..."
docker-compose build

# Start services
echo "🚀 Starting services..."
docker-compose up -d

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
sleep 30

# Check if services are running
echo "🔍 Checking service status..."
docker-compose ps

# Wait for Keycloak to be fully ready
echo "⏳ Waiting for Keycloak to be fully ready..."
until curl -s http://localhost:8080/health/ready > /dev/null 2>&1; do
    echo "   Keycloak is still starting..."
    sleep 10
done

echo "✅ Keycloak is ready!"

# Import Keycloak realm
echo "🔧 Setting up Keycloak realm..."
docker exec popcornboard-keycloak /opt/keycloak/bin/kc.sh import --file=/opt/keycloak/data/import/realm-export.json

# Get client secret
echo "🔑 Getting client secret..."
CLIENT_SECRET=$(docker exec popcornboard-keycloak /opt/keycloak/bin/kc.sh get-client-secret --client-id=nextjs-client 2>/dev/null | grep -o '[a-zA-Z0-9]\{8\}-[a-zA-Z0-9]\{4\}-[a-zA-Z0-9]\{4\}-[a-zA-Z0-9]\{4\}-[a-zA-Z0-9]\{12\}')

if [ -n "$CLIENT_SECRET" ]; then
    echo "✅ Client secret obtained: $CLIENT_SECRET"
    echo "⚠️  Please update docker-compose.yml with this client secret:"
    echo "   KEYCLOAK_CLIENT_SECRET=$CLIENT_SECRET"
else
    echo "⚠️  Could not get client secret automatically."
    echo "   Please get it manually from Keycloak admin console:"
    echo "   1. Go to http://localhost:8080"
    echo "   2. Login with admin/admin"
    echo "   3. Go to Clients > nextjs-client > Credentials"
    echo "   4. Copy the secret and update docker-compose.yml"
fi

echo ""
echo "🎉 Deployment completed!"
echo "========================"
echo "📱 Application: http://localhost:3000"
echo "🔐 Keycloak Admin: http://localhost:8080 (admin/admin)"
echo "🗄️  MongoDB: Using environment variable MONGODB_URI"
echo ""
echo "👥 Test Users:"
echo "   - user1@example.com / password123"
echo "   - user2@example.com / password123"
echo ""
echo "📋 Useful commands:"
echo "   - View logs: docker-compose logs -f"
echo "   - Stop services: docker-compose down"
echo "   - Restart: docker-compose restart"
echo ""
echo "🔧 Next steps:"
echo "   1. Update docker-compose.yml with the client secret"
echo "   2. Restart the app: docker-compose restart app"
echo "   3. Test the application at http://localhost:3000" 